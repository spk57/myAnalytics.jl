#interactive testing of the API
using HTTP
using JSON
#get the API URL
API_URL="http://localhost:8765"

#get the API endpoint
API_ENDPOINT="/api/getssl"

r=HTTP.request("GET", "http://localhost:8765/docs")
println(r)
test_prices = [100.0, 102.5, 101.0, 103.5, 105.0, 104.0, 106.5, 108.0, 107.5, 109.0, 
110.0, 111.5, 112.0, 113.5, 115.0, 114.0, 116.5, 118.0, 117.5, 119.0]

payload = JSON.json(Dict("prices" => test_prices))
r = HTTP.request("POST", "$API_URL/api/getssl", 
  body=payload,
  headers=Dict("Content-Type" => "application/json"))

println(r)
test_prices_short = [100.0, 102.5, 101.0, 103.5] #Requires at least 10 points
payload_short = JSON.json(Dict("prices" => test_prices_short))
r = HTTP.request("POST", "$API_URL/api/getssl", 
  body=payload_short,
  headers=Dict("Content-Type" => "application/json"))

println(r)