using Test
using HTTP
using JSON

# Get API URL from environment variable or use default
api_url = get(ENV, "API_URL", "http://localhost:8001")

@testset "API Endpoints Tests" begin
    
    @testset "Successful GET endpoints" begin
        paths = ["/", "/swagger.json", "/docs"]
        
        for path in paths
            @testset "Testing $path" begin
                r = HTTP.request("GET", "$api_url$path")
                @test r.status == 200
                @test length(r.body) > 0
            end
        end
    end
    
    @testset "Redirect endpoint" begin
        @testset "Testing /api-docs redirect" begin
            r = HTTP.request("GET", "$api_url/api-docs", redirect=false)
            @test r.status == 302
            
            # Check for Location header
            location_found = false
            for (key, value) in r.headers
                if lowercase(key) == "location"
                    @test value == "/docs"
                    location_found = true
                    break
                end
            end
            @test location_found
        end
    end
    
    @testset "Failed paths" begin
        bad_paths = ["missing", "/nonexistent"]
        
        for path in bad_paths
            @testset "Testing $path" begin
                r = HTTP.request("GET", "$api_url$path")
                # Should return JSON error (status might be 200 or 404 depending on catch-all route)
                @test r.status in [200, 404]
                response_body = JSON.parse(String(r.body))
                @test haskey(response_body, "error")
            end
        end
    end
    
    @testset "/api/getssl endpoint" begin
        @testset "Valid request" begin
            # Create test prices data (at least 10 values as required by getssl)
            test_prices = [100.0, 102.5, 101.0, 103.5, 105.0, 104.0, 106.5, 108.0, 107.5, 109.0, 
                           110.0, 111.5, 112.0, 113.5, 115.0, 114.0, 116.5, 118.0, 117.5, 119.0]
            
            payload = JSON.json(Dict("prices" => test_prices))
            r = HTTP.request("POST", "$api_url/api/getssl", 
                             body=payload,
                             headers=Dict("Content-Type" => "application/json"))
            
            @test r.status == 200
            response_body = JSON.parse(String(r.body))
            @test response_body["success"] == true
            @test haskey(response_body, "predicted")
            @test haskey(response_body, "fitted")
            @test haskey(response_body, "stats")
            @test length(response_body["predicted"]) == 20
        end
        
        @testset "Missing prices field" begin
            payload = JSON.json(Dict("data" => [1, 2, 3]))
            r = HTTP.request("POST", "$api_url/api/getssl", 
                             body=payload,
                             headers=Dict("Content-Type" => "application/json"))
            
            @test r.status == 400
            response_body = JSON.parse(String(r.body))
            @test response_body["success"] == false
            @test occursin("Missing 'prices' field", response_body["message"])
        end
        
        @testset "Insufficient data points" begin
            test_prices_short = [100.0, 102.5, 101.0, 103.5, 105.0]
            payload = JSON.json(Dict("prices" => test_prices_short))
            r = HTTP.request("POST", "$api_url/api/getssl", 
                             body=payload,
                             headers=Dict("Content-Type" => "application/json"))
            
            @test r.status == 500
            response_body = JSON.parse(String(r.body))
            @test response_body["success"] == false
            @test response_body["message"] == "Insufficient number of data points"
        end
    end
end
