module Main 
using Oxygen
using HTTP

@get "/greet" function(req::HTTP.Request)
    return "hello world!"
end

@route ["GET", "POST", "PUT", "DELETE"] "/" function()
  html("""
  <html>
  <body>
  <h1>myAnalytics.jl</h1>
  <p>Welcome to the myAnalytics.jl API</p>
  <p>Available endpoints:</p>
  <ul>
    <li><a href="/docs">Docs</a></li>
    <li><a href="/greet">Greet</a></li>
  </ul>
  </body>
  </html>
  """)
end

@get "/api" function()
    return Dict(
        :status => 200,
        :message => "API is running"
    )
end

@route ["GET", "POST", "PUT", "DELETE"] "/*" function(req::HTTP.Request)
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