using Test
using HTTP
using JSON
using Logging
using Dates

#Not able to get genie to return other status codes than 200 
# Configuration
TEST_PORT = 8765
API_URL = "http://localhost:$TEST_PORT"
SERVER_SCRIPT = joinpath(@__DIR__, "..", "src", "myAnalytics.jl")
LOG_FILE = joinpath(@__DIR__, "runtests.log")
MAX_WAIT_TIME = 30  # Maximum seconds to wait for server to start
POLL_INTERVAL = 0.5  # Seconds between health checks

# Custom logger that writes to both console and file
mutable struct DualLogger <: AbstractLogger
    console_logger::ConsoleLogger
    file_logger::SimpleLogger
    file_handle::IO
end

function DualLogger(file_path::String, min_level::LogLevel=Logging.Info)
    file_handle = open(file_path, "a")
    console_logger = ConsoleLogger(stderr, min_level)
    file_logger = SimpleLogger(file_handle, min_level)
    return DualLogger(console_logger, file_logger, file_handle)
end

Logging.min_enabled_level(logger::DualLogger) = Logging.min_enabled_level(logger.console_logger)
Logging.shouldlog(logger::DualLogger, level, _module, group, id) = 
    Logging.shouldlog(logger.console_logger, level, _module, group, id)

function Logging.handle_message(logger::DualLogger, level, message, _module, group, id, 
                                 filepath, line; kwargs...)
    # Log to console
    Logging.handle_message(logger.console_logger, level, message, _module, group, id, 
                          filepath, line; kwargs...)
    # Log to file
    Logging.handle_message(logger.file_logger, level, message, _module, group, id, 
                          filepath, line; kwargs...)
end

# Set up logging to both console and file
function setup_logging()
    # Create dual logger
    dual_logger = DualLogger(LOG_FILE, Logging.Info)
    global_logger(dual_logger)
    return dual_logger
end

# Initialize logging
dual_logger = setup_logging()
log_file_handle = dual_logger.file_handle

# Log test session start
@info "=" ^ 60
@info "Test session started at $(now())"
@info "=" ^ 60
@info "Starting myAnalytics API server on port $TEST_PORT"
@info "Log file: $LOG_FILE"

function wait_for_server(url::String, max_wait::Real, poll_interval::Real)
    """Wait for the server to become available"""
    start_time = time()
    @info "Waiting for server to start at $url..."
    attempt = 0
    while time() - start_time < max_wait
        attempt += 1
        try
            r = HTTP.request("GET", url, timeout=2)
            if r.status == 200
                elapsed = time() - start_time
                @info "Server is ready after $(round(elapsed, digits=2)) seconds (attempt $attempt)"
                return true
            end
        catch e
            # Server not ready yet, continue waiting
            if attempt % 10 == 0  # Log every 10th attempt
                elapsed = time() - start_time
                @info "Still waiting for server... ($(round(elapsed, digits=1))s elapsed)"
            end
        end
        sleep(poll_interval)
    end
    @error "Server failed to start within $max_wait seconds"
    return false
end

function start_server(port::Int)
    """Start the server as a background process"""
    env = copy(ENV)
    env["PORT"] = string(port)
    
    @info "Starting server process: julia --project $SERVER_SCRIPT"
    @info "Server will run on port $port"
    
    # Start the server process
    # Note: Server output will be visible - redirect to devnull if you want to suppress it
    cmd = `julia --project $SERVER_SCRIPT`
    cmd_with_env = setenv(cmd, env)
    proc = run(cmd_with_env, wait=false)
    
    @info "Server process started"
    return proc
end

function stop_server(proc::Base.Process)
    """Stop the server process"""
    try
        if !process_exited(proc)
            @info "Stopping server process ..."
            kill(proc)
            # Give it a moment to exit gracefully
            sleep(1.0)
            if !process_exited(proc)
                @warn "Server did not exit gracefully, forcing termination"
                # Force kill if still running
                kill(proc)
            end
        end
        # Wait for process to finish (with timeout)
        try
            wait(proc)
            @info "Server process stopped successfully"
        catch e
            # Process already exited or error waiting
            @info "Server process already exited"
        end
    catch e
        # Process might already be stopped
        @warn "Error stopping server: $e"
    end
end

# Main test execution
# Start the server
server_proc = start_server(TEST_PORT)

try
    # Wait for server to be ready
    if !wait_for_server(API_URL, MAX_WAIT_TIME, POLL_INTERVAL)
        @error "Server failed to start within $MAX_WAIT_TIME seconds"
        error("Server failed to start within $MAX_WAIT_TIME seconds")
    end
    
    @info "Server is ready! Starting tests..."
    @info ""
    
    # Run the tests
    test_start_time = time()
    @testset "API Endpoints Tests" begin
        
        @testset "Health Check endpoint" begin
            @testset "Testing /health" begin
                @info "Testing GET /health"
                r = HTTP.request("GET", "$API_URL/health")
                @test r.status == 200
                
                response_body = JSON.parse(String(r.body))
                @test haskey(response_body, "status")
                @test response_body["status"] == "healthy"
                @test haskey(response_body, "timestamp")
                @test haskey(response_body, "version")
                @test haskey(response_body, "uptime_seconds")
                @test haskey(response_body, "service")
                @test response_body["service"] == "myAnalytics.jl"
                @info "✓ GET /health - Status: healthy, Version: $(response_body["version"]), Uptime: $(response_body["uptime_seconds"])s"
            end
        end
        
        @testset "Successful GET endpoints" begin
            paths = ["/", "/swagger.json", "/docs"]
            
            for path in paths
                @testset "Testing $path" begin
                    @info "Testing GET $path"
                    r = HTTP.request("GET", "$API_URL$path")
                    @test r.status == 200
                    @test length(r.body) > 0
                    @info "✓ GET $path - Status: $(r.status), Body size: $(length(r.body)) bytes"
                end
            end
        end
        
        @testset "Failed paths" begin
            bad_paths = ["/nonexistent"]
            
            for path in bad_paths
                @testset "Testing $path" begin
                    @info "Testing GET $path (should return error)"
                    r = HTTP.request("GET", "$API_URL$path")
                    response_body = JSON.parse(String(r.body))
                    @test haskey(response_body, "error")
                    @info "✓ GET $path - Status: $(r.status), Error: $(response_body["error"])"
                end
            end
        end
        
        @testset "/api/getssl endpoint" begin
            @testset "Valid request" begin
                @info "Testing POST /api/getssl with valid data"
                # Create test prices data (at least 10 values as required by getssl)
                test_prices = [100.0, 102.5, 101.0, 103.5, 105.0, 104.0, 106.5, 108.0, 107.5, 109.0, 
                               110.0, 111.5, 112.0, 113.5, 115.0, 114.0, 116.5, 118.0, 117.5, 119.0]
                
                payload = JSON.json(Dict("prices" => test_prices))
                r = HTTP.request("POST", "$API_URL/api/getssl", 
                                 body=payload,
                                 headers=Dict("Content-Type" => "application/json"))
                
                @test r.status == 200
                response_body = JSON.parse(String(r.body))
                @test response_body["success"] == true
                @test haskey(response_body, "predicted")
                @test haskey(response_body, "fitted")
                @test haskey(response_body, "stats")
                @test length(response_body["predicted"]) == 20
                @info "✓ POST /api/getssl (valid) - Status: $(r.status), Predicted: $(length(response_body["predicted"])) values"
            end
            
            @testset "Missing prices field" begin
                @info "Testing POST /api/getssl with missing prices field"
                payload = JSON.json(Dict("data" => [1, 2, 3]))
                r = HTTP.request("POST", "$API_URL/api/getssl", 
                                 body=payload,
                                 headers=Dict("Content-Type" => "application/json"))
                
                response_body = JSON.parse(String(r.body))
                @test response_body["success"] == false
                @test occursin("Missing 'prices' field", response_body["message"])
                @info "✓ POST /api/getssl (missing prices) - Status: $(r.status), Message: $(response_body["message"])"
            end
            
            @testset "Insufficient data points" begin
                @info "Testing POST /api/getssl with insufficient data points"
                test_prices_short = [100.0, 102.5, 101.0, 103.5, 105.0]
                payload = JSON.json(Dict("prices" => test_prices_short))
                r = HTTP.request("POST", "$API_URL/api/getssl", 
                                 body=payload,
                                 headers=Dict("Content-Type" => "application/json"))
                
                response_body = JSON.parse(String(r.body))
                @test response_body["success"] == false
                @test response_body["message"] == "Insufficient number of data points"
                @info "✓ POST /api/getssl (insufficient data) - Status: $(r.status), Message: $(response_body["message"])"
            end
        end
    end
    
    test_duration = time() - test_start_time
    @info ""
    @info "=" ^ 60
    @info "Tests completed successfully in $(round(test_duration, digits=2)) seconds!"
    @info "=" ^ 60
    
finally
    # Always stop the server, even if tests fail
    @info ""
    @info "Stopping server..."
    stop_server(server_proc)
    @info "Server stopped."
    
    # Log test session end
    @info "=" ^ 60
    @info "Test session ended at $(now())"
    @info "=" ^ 60
    @info ""
    
    # Close log file
    try
        close(log_file_handle)
    catch e
        @warn "Error closing log file: $e"
    end
end
