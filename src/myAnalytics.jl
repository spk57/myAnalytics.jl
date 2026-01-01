#myAnalytics.jl is a simple API for analytics.
module myAnalytics
using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json
using JSON
using Dates

# Include API endpoints
include("api/getssl.jl")
include("api/logger.jl")

route("/*") do
    json(Dict(:error => "myAnalytics endpoint Not Found"))
end

route("/") do
    html("myAnalytics.jl")
end

# Swagger documentation endpoints
route("/swagger.json") do
    try
        swagger_content = read(joinpath(@__DIR__, "..", "swagger.json"), String)
        respond(swagger_content, :json)
    catch e
        Genie.Responses.setstatus(500)
        json(Dict(:error => "Failed to load Swagger specification: $(sprint(showerror, e))"))
    end
end

route("/docs") do
    try
        swagger_html = read(joinpath(@__DIR__, "..", "public", "swagger-ui.html"), String)
        html(swagger_html)
    catch e
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
    uptime_seconds = round(Int, (now() - SERVER_START_TIME).value / 1000)
    
    health_data = Dict(
        :status => "healthy",
        :timestamp => now(),
        :version => API_VERSION,
        :uptime_seconds => uptime_seconds,
        :service => "myAnalytics.jl"
    )
    
    json(health_data)
end

route("/api/getssl", method = POST) do
    try
        # Parse JSON request body
        request_data = Genie.Requests.jsonpayload()
        
        # Extract prices from request
        if !haskey(request_data, "prices")
            return json(Dict(:success => false, :message => "Error: Missing 'prices' field in request"))
        end
        
        prices = request_data["prices"]
        
        # Call getssl function
        result = getssl(prices)
        
        # Check if getssl returned an error (insufficient data points)
        if haskey(result, :success) && result[:success] == false
            # Check if it's the insufficient data points error
            if occursin("Insufficient data points", result[:message])
                return json(Dict(:success => false, :message => "Insufficient number of data points"))
            else
                return json(Dict(:success => false, :message => result[:message]))
            end
        end
        
        # Return result as JSON
        return json(result)
    catch e
        # Check if it's the insufficient data points error
        error_msg = sprint(showerror, e)
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
        request_data = Genie.Requests.jsonpayload()
        
        # Validate required fields
        required_fields = ["datetime", "name", "value", "source"]
        for field in required_fields
            if !haskey(request_data, field)
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
        
        return json(result)
    catch e
        error_msg = sprint(showerror, e)
        if occursin("ArgumentError", error_msg) && occursin("DateTime", error_msg)
            return json(Dict(:success => false, :message => "Invalid datetime format. Use ISO 8601 format (e.g., 2025-01-01T10:30:00)"))
        else
            return json(Dict(:success => false, :message => "Error processing request: $(sprint(showerror, e))"))
        end
    end
end

route("/api/logger", method = GET) do
    try
        # Get query parameters
        params = Genie.Requests.getpayload()
        
        limit = haskey(params, :limit) ? parse(Int, params[:limit]) : 100
        offset = haskey(params, :offset) ? parse(Int, params[:offset]) : 0
        source = haskey(params, :source) ? string(params[:source]) : nothing
        name = haskey(params, :name) ? string(params[:name]) : nothing
        
        result = get_log_entries(limit=limit, offset=offset, source=source, name=name)
        return json(result)
    catch e
        return json(Dict(:success => false, :message => "Error retrieving log entries: $(sprint(showerror, e))"))
    end
end

route("/api/logger/stats", method = GET) do
    try
        result = get_log_stats()
        return json(result)
    catch e
        return json(Dict(:success => false, :message => "Error retrieving stats: $(sprint(showerror, e))"))
    end
end

r=routes()
println("Routes: $r")
port = parse(Int, get(ENV, "PORT", "8001"))
host = get(ENV, "HOST", "0.0.0.0")
println("Starting server on $host:$port")
up(host=host, port=port, async = false)
end