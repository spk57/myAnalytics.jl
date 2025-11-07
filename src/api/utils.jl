"""
    utils

Utility functions for the myAnalytics API
"""

module AnalyticsUtils

using JSON
using Dates
using Parameters

export Response, ErrorResponse, validate_metric_name, format_timestamp, 
       parse_query_params, create_logger

"""
    Response

Standard API response structure
"""
@with_kw struct Response
    status::Int = 200
    data::Any = nothing
    message::String = ""
    timestamp::DateTime = Dates.now()
end

"""
    ErrorResponse

Standard API error response structure
"""
@with_kw struct ErrorResponse
    status::Int = 400
    error::String = ""
    details::String = ""
    timestamp::DateTime = Dates.now()
end

"""
    validate_metric_name(name::String)::Bool

Validate that metric name follows naming conventions.
"""
function validate_metric_name(name::String)::Bool
    # Metric names should be alphanumeric with underscores
    return match(r"^[a-z0-9_]+$"i, name) !== nothing && length(name) > 0 && length(name) <= 100
end

"""
    format_timestamp(dt::DateTime)::String

Format DateTime to ISO 8601 string.
"""
function format_timestamp(dt::DateTime)::String
    return Dates.format(dt, "yyyy-mm-ddTHH:MM:SS.sss")
end

"""
    parse_query_params(query_string::String)::Dict

Parse URL query string into a dictionary.
"""
function parse_query_params(query_string::String)::Dict{String, String}
    params = Dict{String, String}()
    
    if isempty(query_string)
        return params
    end
    
    for param in split(query_string, "&")
        if contains(param, "=")
            key, value = split(param, "="; limit=2)
            params[HTTP.URIs.unescapeuri(key)] = HTTP.URIs.unescapeuri(value)
        end
    end
    
    return params
end

"""
    create_logger(log_file::String="analytics.log")

Create or get a logger for the application.
"""
function create_logger(log_file::String="analytics.log")
    # Basic logging setup - can be extended with Logging.jl
    return (level::String, message::String) -> begin
        timestamp = format_timestamp(Dates.now())
        log_entry = "[$timestamp] [$level] $message"
        println(log_entry)
        
        # Optionally write to file
        open(log_file, "a") do f
            println(f, log_entry)
        end
    end
end

"""
    sanitize_input(input::String)::String

Basic input sanitization for security.
"""
function sanitize_input(input::String)::String
    # Remove potential SQL injection characters
    # This is a basic example - use parameterized queries in production
    dangerous_chars = ['\'', '"', ';', '--', '/*', '*/']
    
    result = input
    for char in dangerous_chars
        result = replace(result, string(char) => "")
    end
    
    return strip(result)
end

"""
    calculate_stats(values::Vector{Float64})::Dict

Calculate basic statistics from a vector of values.
"""
function calculate_stats(values::Vector{Float64})::Dict
    if isempty(values)
        return Dict(:error => "Empty values vector")
    end
    
    return Dict(
        :mean => mean(values),
        :median => median(values),
        :std => std(values),
        :min => minimum(values),
        :max => maximum(values),
        :count => length(values)
    )
end

end # module AnalyticsUtils

