#myAnalytics.jl is a simple API for analytics.
module myAnalytics
using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json
using JSON
using Dates

# Include API endpoints
include("api/getssl.jl")

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

r=routes()
println("Routes: $r")
port = parse(Int, get(ENV, "PORT", "8001"))
println("Starting server on port $port")
up(port, async = false)
end