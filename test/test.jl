using HTTP
using JSON

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

println("\nTesting /api/getssl endpoint.  Should return 200.")
# Test getssl API endpoint with valid data
try
    # Create test prices data (at least 10 values as required by getssl)
    test_prices = [100.0, 102.5, 101.0, 103.5, 105.0, 104.0, 106.5, 108.0, 107.5, 109.0, 
                   110.0, 111.5, 112.0, 113.5, 115.0, 114.0, 116.5, 118.0, 117.5, 119.0]
    
    # Create JSON payload
    payload = JSON.json(Dict("prices" => test_prices))
    
    # Make POST request
    r = HTTP.request("POST", "$api_url/api/getssl", 
                     body=payload,
                     headers=Dict("Content-Type" => "application/json"))
    
    println("Path: /api/getssl Status: $(r.status)")
    
    if r.status == 200
        response_body = JSON.parse(String(r.body))
        println("Success: $(response_body["success"])")
        println("Message: $(response_body["message"])")
        if haskey(response_body, "stats")
            println("Stats keys: $(keys(response_body["stats"]))")
        end
        if haskey(response_body, "predicted")
            println("Predicted values count: $(length(response_body["predicted"]))")
        end
    else
        println("Response body: $(String(r.body))")
    end
catch e
    println("Path: /api/getssl Error: $(sprint(showerror, e))")
end

println("\nTesting /api/getssl endpoint with missing prices.  Should return 400.")
# Test getssl API endpoint with missing prices field
try
    # Create JSON payload without prices
    payload = JSON.json(Dict("data" => [1, 2, 3]))
    
    # Make POST request
    r = HTTP.request("POST", "$api_url/api/getssl", 
                     body=payload,
                     headers=Dict("Content-Type" => "application/json"))
    
    println("Path: /api/getssl (missing prices) Status: $(r.status)")
    if length(r.body) < 200
        println("Response body: $(String(r.body))")
    end
catch e
    println("Path: /api/getssl (missing prices) Error: $(sprint(showerror, e))")
end

println("\nTesting /api/getssl endpoint with insufficient data.  Should return 200 with error message.")
# Test getssl API endpoint with insufficient data
try
    # Create test prices data with less than 10 values
    test_prices_short = [100.0, 102.5, 101.0, 103.5, 105.0]
    
    # Create JSON payload
    payload = JSON.json(Dict("prices" => test_prices_short))
    
    # Make POST request
    r = HTTP.request("POST", "$api_url/api/getssl", 
                     body=payload,
                     headers=Dict("Content-Type" => "application/json"))
    
    println("Path: /api/getssl (insufficient data) Status: $(r.status)")
    response_body = JSON.parse(String(r.body))
    println("Success: $(response_body["success"])")
    println("Message: $(response_body["message"])")
catch e
    println("Path: /api/getssl (insufficient data) Error: $(sprint(showerror, e))")
end

