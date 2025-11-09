module Main 
using Oxygen
using HTTP

@get "/greet" function(req::HTTP.Request)
    return "hello world!"
end

@route ["GET", "POST", "PUT", "DELETE"] "/api" function(req::HTTP.Request)
    return Dict(
        :status => 404,
        :error => "Endpoint not found",
        :available_endpoints => [
            "/docs",
            "/greet"
        ]
    )
end

serve()
end