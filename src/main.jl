using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json

route("/*") do
    throw(HTTP.StatusError(404, "Endpoint Not Found"))
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

r=routes()
println("Routes: $r")
up(8001, async = false)