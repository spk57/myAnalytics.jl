# logger.jl - API endpoint for logging data entries
using Dates
using JSON

# In-memory storage for logged entries (for development/demo)
# In production, you would store this in a database
const LOG_ENTRIES = Vector{Dict{Symbol,Any}}()
const LOG_LOCK = ReentrantLock()

"""
    add_log_entry(datetime, name, value, source)

Add a log entry to the system.

# Arguments
- `datetime::DateTime`: Timestamp of the log entry
- `name::String`: Name/identifier of the log entry
- `value::Any`: Value to be logged (can be numeric, string, etc.)
- `source::String`: Source/origin of the log entry

# Returns
Dict with success status and entry ID
"""
function add_log_entry(datetime::DateTime, name::String, value::Any, source::String)
    entry = Dict{Symbol,Any}(
        :id => length(LOG_ENTRIES) + 1,
        :datetime => datetime,
        :name => name,
        :value => value,
        :source => source,
        :created_at => now()
    )
    
    lock(LOG_LOCK) do
        push!(LOG_ENTRIES, entry)
    end
    
    return Dict(
        :success => true,
        :message => "Log entry created successfully",
        :id => entry[:id]
    )
end

"""
    get_log_entries(; limit=100, offset=0, source=nothing, name=nothing)

Retrieve log entries with optional filtering.

# Arguments
- `limit::Int`: Maximum number of entries to return (default: 100)
- `offset::Int`: Number of entries to skip (default: 0)
- `source::Union{String,Nothing}`: Filter by source (optional)
- `name::Union{String,Nothing}`: Filter by name (optional)

# Returns
Dict with entries array and metadata
"""
function get_log_entries(; limit::Int=100, offset::Int=0, source::Union{String,Nothing}=nothing, name::Union{String,Nothing}=nothing)
    lock(LOG_LOCK) do
        filtered_entries = LOG_ENTRIES
        
        # Apply filters
        if !isnothing(source)
            filtered_entries = filter(e -> e[:source] == source, filtered_entries)
        end
        
        if !isnothing(name)
            filtered_entries = filter(e -> e[:name] == name, filtered_entries)
        end
        
        # Apply pagination
        total = length(filtered_entries)
        start_idx = offset + 1
        end_idx = min(offset + limit, total)
        
        paginated_entries = start_idx <= total ? filtered_entries[start_idx:end_idx] : []
        
        return Dict(
            :success => true,
            :entries => paginated_entries,
            :total => total,
            :limit => limit,
            :offset => offset
        )
    end
end

"""
    clear_log_entries()

Clear all log entries (for testing purposes).
"""
function clear_log_entries()
    lock(LOG_LOCK) do
        empty!(LOG_ENTRIES)
    end
    return Dict(
        :success => true,
        :message => "All log entries cleared"
    )
end

"""
    get_log_stats()

Get statistics about logged entries.
"""
function get_log_stats()
    lock(LOG_LOCK) do
        total = length(LOG_ENTRIES)
        
        if total == 0
            return Dict(
                :success => true,
                :total_entries => 0,
                :unique_sources => 0,
                :unique_names => 0
            )
        end
        
        sources = Set(e[:source] for e in LOG_ENTRIES)
        names = Set(e[:name] for e in LOG_ENTRIES)
        
        return Dict(
            :success => true,
            :total_entries => total,
            :unique_sources => length(sources),
            :unique_names => length(names),
            :sources => collect(sources),
            :names => collect(names)
        )
    end
end

