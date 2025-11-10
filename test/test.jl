using HTTP

api_url = "http://localhost:8001"

#Test successful paths
paths=["/", "/hello.html", "/hello.json", "/hello.txt"]

println("Testing successful paths.  Should return 200.")
for path in paths
    try
      r = HTTP.request("GET", "$api_url$path")
      println("Path:  $path Status: $(r.status)")
      if length(r.body) < 100  
        println(String(r.body))
      end
    catch e
      println("Path:  $path Error: Error getting path")
    end
end

println("Testing failed paths.  Should return 404.")
#Test failed paths
paths=["missing"]

for path in paths
    try
      r = HTTP.request("GET", "$api_url$path")
      println("Path:  $path Status: $(r.status)")
      if length(r.body) < 100  
        println(String(r.body))
      end
    catch e
      println("Path:  $path Error: Error getting path")
    end
end

