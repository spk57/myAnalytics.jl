#myAnalytics.jl is a simple API for analytics.
module myAnalytics
using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json
using JSON
using Dates

# Include API endpoints
include("api/getssl.jl")
include("api/logger.jl")

# Logging helper function with timestamps
function log_with_timestamp(message::String)
    timestamp = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
    println("[$timestamp] $message")
end

function log_request(method::String, path::String, status::Int=200)
    timestamp = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
    println("[$timestamp] $method $path -> $status")
end

function log_error(message::String, error::Exception)
    timestamp = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
    error_msg = sprint(showerror, error)
    println("[$timestamp] ERROR: $message - $error_msg")
end

route("/*") do
    json(Dict(:error => "myAnalytics endpoint Not Found"))
end

route("/") do
    html("myAnalytics.jl")
end

# Swagger documentation endpoints
route("/swagger.json") do
    try
        log_request("GET", "/swagger.json")
        swagger_content = read(joinpath(@__DIR__, "..", "swagger.json"), String)
        log_request("GET", "/swagger.json", 200)
        respond(swagger_content, :json)
    catch e
        log_error("GET /swagger.json", e)
        Genie.Responses.setstatus(500)
        json(Dict(:error => "Failed to load Swagger specification: $(sprint(showerror, e))"))
    end
end

route("/docs") do
    try
        log_request("GET", "/docs")
        swagger_html = read(joinpath(@__DIR__, "..", "public", "swagger-ui.html"), String)
        log_request("GET", "/docs", 200)
        html(swagger_html)
    catch e
        log_error("GET /docs", e)
        Genie.Responses.setstatus(500)
        html("<html><body><h1>Error loading Swagger UI</h1><p>$(sprint(showerror, e))</p></body></html>")
    end
end

route("/api-docs") do
    # Redirect to /docs for convenience
    setstatus!(302)
    Genie.Responses.setstatus(302)
    Genie.Responses.setheaders(Dict("Location" => "/docs"))
    ""
end

# Health check endpoint
const SERVER_START_TIME = now()
const API_VERSION = "0.0.1"

route("/health") do
    log_request("GET", "/health")
    uptime_seconds = round(Int, (now() - SERVER_START_TIME).value / 1000)
    
    health_data = Dict(
        :status => "healthy",
        :timestamp => now(),
        :version => API_VERSION,
        :uptime_seconds => uptime_seconds,
        :service => "myAnalytics.jl"
    )
    
    log_request("GET", "/health", 200)
    json(health_data)
end

route("/api/getssl", method = POST) do
    try
        log_request("POST", "/api/getssl")
        # Parse JSON request body
        request_data = Genie.Requests.jsonpayload()
        
        # Extract prices from request
        if !haskey(request_data, "prices")
            log_with_timestamp("POST /api/getssl - Missing 'prices' field")
            return json(Dict(:success => false, :message => "Error: Missing 'prices' field in request"))
        end
        
        prices = request_data["prices"]
        log_with_timestamp("POST /api/getssl - Processing $(length(prices)) data points")
        
        # Call getssl function
        result = getssl(prices)
        
        # Check if getssl returned an error (insufficient data points)
        if haskey(result, :success) && result[:success] == false
            # Check if it's the insufficient data points error
            if occursin("Insufficient data points", result[:message])
                log_with_timestamp("POST /api/getssl - Insufficient data points")
                return json(Dict(:success => false, :message => "Insufficient number of data points"))
            else
                log_with_timestamp("POST /api/getssl - Error: $(result[:message])")
                return json(Dict(:success => false, :message => result[:message]))
            end
        end
        
        log_request("POST", "/api/getssl", 200)
        # Return result as JSON
        return json(result)
    catch e
        # Check if it's the insufficient data points error
        error_msg = sprint(showerror, e)
        log_error("POST /api/getssl", e)
        if occursin("Insufficient data points", error_msg)
            return json(Dict(:success => false, :message => "Insufficient number of data points"))
        else
            return json(Dict(:success => false, :message => "Error processing request: Unknown error"))
        end
    end
end

# Logger endpoints
route("/api/logger", method = POST) do
    try
        log_request("POST", "/api/logger")
        request_data = Genie.Requests.jsonpayload()
        
        # Validate required fields
        required_fields = ["datetime", "name", "value", "source"]
        for field in required_fields
            if !haskey(request_data, field)
                log_with_timestamp("POST /api/logger - Missing required field: $field")
                return json(Dict(:success => false, :message => "Missing required field: $field"))
            end
        end
        
        # Parse datetime
        datetime_str = request_data["datetime"]
        datetime = DateTime(datetime_str)
        
        # Add log entry
        result = add_log_entry(
            datetime,
            string(request_data["name"]),
            request_data["value"],
            string(request_data["source"])
        )
        
        log_request("POST", "/api/logger", 200)
        return json(result)
    catch e
        error_msg = sprint(showerror, e)
        log_error("POST /api/logger", e)
        if occursin("ArgumentError", error_msg) && occursin("DateTime", error_msg)
            return json(Dict(:success => false, :message => "Invalid datetime format. Use ISO 8601 format (e.g., 2025-01-01T10:30:00)"))
        else
            return json(Dict(:success => false, :message => "Error processing request: $(sprint(showerror, e))"))
        end
    end
end

route("/api/logger", method = GET) do
    try
        log_request("GET", "/api/logger")
        # Get query parameters
        params = Genie.Requests.getpayload()
        
        limit = haskey(params, :limit) ? parse(Int, params[:limit]) : 100
        offset = haskey(params, :offset) ? parse(Int, params[:offset]) : 0
        source = haskey(params, :source) ? string(params[:source]) : nothing
        name = haskey(params, :name) ? string(params[:name]) : nothing
        
        result = get_log_entries(limit=limit, offset=offset, source=source, name=name)
        log_request("GET", "/api/logger", 200)
        return json(result)
    catch e
        log_error("GET /api/logger", e)
        return json(Dict(:success => false, :message => "Error retrieving log entries: $(sprint(showerror, e))"))
    end
end

route("/api/logger/stats", method = GET) do
    try
        log_request("GET", "/api/logger/stats")
        result = get_log_stats()
        log_request("GET", "/api/logger/stats", 200)
        return json(result)
    catch e
        log_error("GET /api/logger/stats", e)
        return json(Dict(:success => false, :message => "Error retrieving stats: $(sprint(showerror, e))"))
    end
end

r=routes()
log_with_timestamp("Routes registered: $r")
port = parse(Int, get(ENV, "PORT", "8001"))
host = get(ENV, "HOST", "0.0.0.0")
log_with_timestamp("Starting server on $host:$port")
up(host=host, port=port, async = false)
end