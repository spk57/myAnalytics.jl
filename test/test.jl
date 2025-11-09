using HTTP

api_url = "http://localhost:8080"

paths=["/", "/greet", "/docs", "/api"]

for path in paths
    r = HTTP.request("GET", "$api_url$path")
    println("Path:  $path Status: $(r.status)")
    if length(r.body) < 100  
        println(String(r.body))
    end
end


