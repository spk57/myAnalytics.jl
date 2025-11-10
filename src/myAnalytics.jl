#myAnalytics.jl is a simple API for analytics.
module myAnalytics
using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json

# Include API endpoints
include("api/getssl.jl")

route("/*") do
    throw(HTTP.StatusError(404, "myAnalytics endpoint Not Found"))
end

route("/") do
    html("myAnalytics.jl")
  end
  
route("/hello.html") do
  html("Hello World")
end

route("/hello.json") do
  json("Hello World")
end

route("/hello.txt") do
   respond("Hello World", :text)
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
        
        # Return result as JSON
        return json(result)
    catch e
        Genie.Renderer.setstatuscode(500)
        return json(Dict(:success => false, :message => "Error processing request: $(sprint(showerror, e))"))
    end
end

r=routes()
println("Routes: $r")
up(8001, async = false)
end