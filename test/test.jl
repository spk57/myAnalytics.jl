using HTTP

api_url = "http://localhost:8080"

#Test successful paths
paths=["/", "/greet", "/docs", "/api"]

println("Testing successful paths.  Should return 200.")
for path in paths
    r = HTTP.request("GET", "$api_url$path")
    println("Path:  $path Status: $(r.status)")
    if length(r.body) < 100  
        println(String(r.body))
    end
end

println("Testing failed paths.  Should return 404.")
#Test failed paths
paths=["missing"]

for path in paths
    r = HTTP.request("GET", "$api_url$path")
    println("Path:  $path Status: $(r.status)")
end

