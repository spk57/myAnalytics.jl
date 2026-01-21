# logger.jl - API endpoint for logging data entries
using Dates
using JSON
using CSV
using DataFrames

# CSV file path for persistent storage
const LOG_FILE = joinpath(@__DIR__, "..", "..", "logger.csv")
const LOG_LOCK = ReentrantLock()

# Initialize CSV file if it doesn't exist
function init_log_file()
    if !isfile(LOG_FILE)
        df = DataFrame(
            id = Int[],
            transaction = String[],
            datetime = DateTime[],
            name = String[],
            value = Any[],
            source = String[],
            created_at = DateTime[]
        )
        CSV.write(LOG_FILE, df)
    end
end

# Initialize on module load
init_log_file()

"""
    add_log_entry(datetime, transaction, name, value, source)

Add a log entry to the system and persist to CSV file.

# Arguments
- `datetime::DateTime`: Timestamp of the log entry
- `transaction::String`: Transaction identifier
- `name::String`: Name/identifier of the log entry
- `value::Any`: Value to be logged (can be numeric, string, etc.)
- `source::String`: Source/origin of the log entry

# Returns
Dict with success status and entry ID
"""
function add_log_entry(datetime::DateTime, transaction::String, name::String, value::Any, source::String)
    lock(LOG_LOCK) do
        # Read current entries to get next ID
        df = CSV.read(LOG_FILE, DataFrame)
        
        # Expected column order: id, transaction, datetime, name, value, source, created_at
        expected_columns = [:id, :transaction, :datetime, :name, :value, :source, :created_at]
        
        # Ensure transaction column exists (for backward compatibility)
        if !(:transaction in names(df))
            df.transaction = fill("", nrow(df))
        else
            # Ensure transaction column is pure String type (handle missing/null values)
            # Convert any missing or null values to empty strings and ensure type is String
            df.transaction = String[x === missing || x === nothing ? "" : string(x) for x in df.transaction]
        end
        
        # Ensure columns are in the correct order
        if names(df) != expected_columns
            # Reorder to match expected order
            df = df[:, expected_columns]
        end
        
        next_id = isempty(df) ? 1 : maximum(df.id) + 1
        
        # Create new entry DataFrame with explicit column order matching expected_columns
        # Use a vector of values in the exact order of expected_columns
        new_entry = DataFrame(
            id = [next_id],
            transaction = [transaction],
            datetime = [datetime],
            name = [name],
            value = [value],
            source = [source],
            created_at = [now()]
        )
        
        # Reorder to match expected_columns order (this ensures consistency)
        new_entry = new_entry[:, expected_columns]
        
        # Ensure transaction column is String type (should already be, but ensure it)
        if eltype(new_entry.transaction) != String
            new_entry.transaction = String[string(x) for x in new_entry.transaction]
        end
        
        # Append new entry to existing DataFrame
        # Since both df.transaction and new_entry.transaction are now String, vcat should work correctly
        df = vcat(df, new_entry)
        
        # Ensure final DataFrame has correct column order before writing
        df = df[:, expected_columns]
        
        # Final verification: ensure the last row's transaction value matches what we intended
        # This is a safety check to catch any issues
        if nrow(df) > 0 && df.id[end] == next_id
            if df.transaction[end] != transaction
                # Force correct value if there was any issue
                df.transaction[end] = transaction
            end
        end
        
        # Write entire DataFrame back to CSV
        CSV.write(LOG_FILE, df)
        
        return Dict(
            :success => true,
            :message => "Log entry created successfully",
            :id => next_id
        )
    end
end

"""
    get_log_entries(; limit=100, offset=0, source=nothing, name=nothing)

Retrieve log entries from CSV file with optional filtering.

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
        # Read from CSV file
        df = CSV.read(LOG_FILE, DataFrame)
        
        # Apply filters
        if !isnothing(source)
            df = filter(row -> row.source == source, df)
        end
        
        if !isnothing(name)
            df = filter(row -> row.name == name, df)
        end
        
        # Get total before pagination
        total = nrow(df)
        
        # Apply pagination
        start_idx = offset + 1
        end_idx = min(offset + limit, total)
        
        if start_idx <= total
            paginated_df = df[start_idx:end_idx, :]
            # Check if transaction column exists (for backward compatibility)
            has_transaction = :transaction in names(paginated_df)
            # Convert DataFrame rows to Dict entries
            entries = [
                begin
                    entry_dict = Dict(
                        :id => row.id,
                        :datetime => row.datetime,
                        :name => row.name,
                        :value => row.value,
                        :source => row.source,
                        :created_at => row.created_at
                    )
                    # Add transaction if column exists
                    if has_transaction
                        entry_dict[:transaction] = row.transaction
                    else
                        entry_dict[:transaction] = ""
                    end
                    entry_dict
                end
                for row in eachrow(paginated_df)
            ]
        else
            entries = []
        end
        
        return Dict(
            :success => true,
            :entries => entries,
            :total => total,
            :limit => limit,
            :offset => offset
        )
    end
end

"""
    clear_log_entries()

Clear all log entries from CSV file (for testing purposes).
"""
function clear_log_entries()
    lock(LOG_LOCK) do
        # Reinitialize empty CSV file
        df = DataFrame(
            id = Int[],
            transaction = String[],
            datetime = DateTime[],
            name = String[],
            value = Any[],
            source = String[],
            created_at = DateTime[]
        )
        CSV.write(LOG_FILE, df)
    end
    return Dict(
        :success => true,
        :message => "All log entries cleared"
    )
end

"""
    get_log_stats()

Get statistics about logged entries from CSV file.
"""
function get_log_stats()
    lock(LOG_LOCK) do
        # Read from CSV file
        df = CSV.read(LOG_FILE, DataFrame)
        total = nrow(df)
        
        if total == 0
            return Dict(
                :success => true,
                :total_entries => 0,
                :unique_sources => 0,
                :unique_names => 0,
                :sources => [],
                :names => []
            )
        end
        
        sources = unique(df.source)
        names = unique(df.name)
        
        return Dict(
            :success => true,
            :total_entries => total,
            :unique_sources => length(sources),
            :unique_names => length(names),
            :sources => sources,
            :names => names
        )
    end
end

