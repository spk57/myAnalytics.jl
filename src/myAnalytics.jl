#myAnalytics.jl is a simple API for analytics.
module myAnalytics
using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json
using JSON

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
        Genie.Renderer.setstatuscode(500)
        json(Dict(:error => "Failed to load Swagger specification: $(sprint(showerror, e))"))
    end
end

route("/docs") do
    try
        swagger_html = read(joinpath(@__DIR__, "..", "public", "swagger-ui.html"), String)
        html(swagger_html)
    catch e
        Genie.Renderer.setstatuscode(500)
        html("<html><body><h1>Error loading Swagger UI</h1><p>$(sprint(showerror, e))</p></body></html>")
    end
end

route("/api-docs") do
    # Redirect to /docs for convenience
    Genie.Renderer.setstatuscode(302)
    Genie.Renderer.setheaders(Dict("Location" => "/docs"))
    ""
end

route("/api/getssl", method = POST) do
    try
        # Parse JSON request body
        request_data = Genie.Requests.jsonpayload()
        
        # Extract prices from request
        if !haskey(request_data, "prices")
            Genie.Renderer.setstatuscode(400)
            return json(Dict(:success => false, :message => "Missing 'prices' field in request"))
        end
        
        prices = request_data["prices"]
        
        # Call getssl function
        result = getssl(prices)
        
        # Check if getssl returned an error (insufficient data points)
        if haskey(result, :success) && result[:success] == false
            Genie.Renderer.setstatuscode(500)
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
        Genie.Renderer.setstatuscode(500)
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