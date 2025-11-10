using Test
include("../src/api/getssl.jl")

@testset "getssl function tests" begin
    
    @testset "Valid input with sufficient data points" begin
        prices = [1.0, 2.0, 3.0, 4.0, 5.0, 1.0, 2.0, 3.0, 4.0, 5.0, 
                  1.0, 2.0, 3.0, 4.0, 5.0, 1.0, 2.0, 3.0, 4.0, 5.0]
        result = getssl(prices)
        
        @test result[:success] == true
        @test haskey(result, :message)
        @test haskey(result, :predicted)
        @test haskey(result, :fitted)
        @test haskey(result, :stats)
        @test length(result[:predicted]) == 20
        @test length(result[:fitted]) == length(prices)
        
        # Check stats keys
        @test haskey(result[:stats], :mean)
        @test haskey(result[:stats], :std)
        @test haskey(result[:stats], :max)
        @test haskey(result[:stats], :min)
        @test haskey(result[:stats], :return)
    end
    
    @testset "Insufficient data points" begin
        prices = [1.0, 2.0, 3.0, 4.0, 5.0]  # Only 5 values, need at least 10
        result = getssl(prices)
        
        @test result[:success] == false
        @test haskey(result, :message)
        @test occursin("Insufficient data points", result[:message])
    end
    
    @testset "Monthly analysis (more than 40 points)" begin
        # Create 50 data points to trigger monthly analysis
        prices = collect(100.0:1.0:149.0)
        result = getssl(prices)
        
        @test result[:success] == true
        @test haskey(result, :stats)
        # Monthly stats should be present
        if haskey(result[:stats], :smmax)
            @test haskey(result[:stats], :smmaxd)
            @test haskey(result[:stats], :smmind)
        end
    end
    
    @testset "Edge case: exactly 10 data points" begin
        prices = [100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 106.0, 107.0, 108.0, 109.0]
        result = getssl(prices)
        
        @test result[:success] == true
        @test length(result[:fitted]) == 10
        @test length(result[:predicted]) == 20
    end
    
    @testset "Edge case: exactly 40 data points" begin
        prices = collect(100.0:1.0:139.0)
        result = getssl(prices)
        
        @test result[:success] == true
        # Should not have monthly stats (exactly 40, so monthlyAnalysis = false)
        @test length(result[:fitted]) == 40
    end
end
