# Testing Guide

## Overview

myAnalytics.jl includes a comprehensive test suite with both unit tests and integration tests. The test framework automatically manages server lifecycle, logging, and provides detailed test reports.

## Test Structure

```
test/
├── runtests.jl           # Main integration tests with server management
├── test_getssl.jl        # Unit tests for getssl function
└── runtests.log          # Test execution log (generated)
```

## Running Tests

### Full Integration Tests

The main test suite starts a server, runs all tests, and stops the server automatically:

```bash
julia --project test/runtests.jl
```

**Features:**
- Automatically starts server on port 8765
- Waits for server to be ready (max 30 seconds)
- Runs all endpoint tests
- Captures detailed logs to `test/runtests.log`
- Stops server on completion (even if tests fail)
- Reports test duration

### Unit Tests Only

Test the `getssl` function directly without starting a server:

```bash
julia --project test/test_getssl.jl
```

## Test Coverage

### Integration Tests (`runtests.jl`)

#### 1. Successful GET Endpoints
Tests all public GET endpoints return 200 OK:
- `/` - Root endpoint
- `/swagger.json` - API specification
- `/docs` - Swagger UI

#### 2. Redirect Endpoint
Tests `/api-docs` properly redirects to `/docs`:
- Verifies 302 status code
- Confirms Location header

#### 3. Failed Paths
Tests error handling for non-existent endpoints:
- `/missing`
- `/nonexistent`
- Verifies JSON error response

#### 4. Analytics Endpoint Tests

**Valid Request:**
- Sends 20 valid price points
- Verifies 200 status code
- Validates response structure
- Checks for all expected fields
- Confirms 20 predicted values

**Missing Prices Field:**
- Sends request without `prices` field
- Expects 400 Bad Request
- Validates error message

**Insufficient Data Points:**
- Sends only 5 price points
- Expects 200 with error in response
- Confirms specific error message

### Unit Tests (`test_getssl.jl`)

#### 1. Valid Input
Tests normal operation with sufficient data:
- 20 data points
- Verifies success flag
- Checks all output fields exist
- Validates array lengths

#### 2. Insufficient Data Points
Tests error handling with < 10 points:
- Verifies failure response
- Confirms appropriate error message

#### 3. Monthly Analysis
Tests with > 40 points:
- Triggers monthly seasonal analysis
- Verifies monthly statistics present

#### 4. Edge Cases
**Exactly 10 Points:**
- Minimum valid input
- Verifies successful processing

**Exactly 40 Points:**
- Boundary for monthly analysis
- Confirms correct behavior

## Test Logging

### Dual Logging System

Tests use a custom `DualLogger` that writes to both:
1. **Console (stderr)**: Real-time test monitoring
2. **File (runtests.log)**: Persistent test history

### Log Contents

Each test session logs:
- Test session start/end timestamps
- Server startup/shutdown events
- Each test execution with results
- HTTP status codes and response details
- Test duration
- Any errors or warnings

### Example Log Entry

```
┌ Info: ============================================================
└ @ Main ~/myAnalytics.jl/test/runtests.jl:56
┌ Info: Test session started at 2025-11-11T10:30:00.123
└ @ Main ~/myAnalytics.jl/test/runtests.jl:57
┌ Info: Starting server process: julia --project ~/myAnalytics.jl/src/myAnalytics.jl
└ @ Main ~/myAnalytics.jl/test/runtests.jl:74
┌ Info: Server is ready after 2.34 seconds (attempt 5)
└ @ Main ~/myAnalytics.jl/test/runtests.jl:53
┌ Info: Testing GET /
└ @ Main ~/myAnalytics.jl/test/runtests.jl:138
┌ Info: ✓ GET / - Status: 200, Body size: 15 bytes
└ @ Main ~/myAnalytics.jl/test/runtests.jl:142
```

## Test Configuration

### Environment Variables

- `TEST_PORT`: Server port for tests (default: 8765)
- `API_URL`: Base URL for API calls (default: http://localhost:8765)
- `MAX_WAIT_TIME`: Max seconds to wait for server (default: 30)
- `POLL_INTERVAL`: Seconds between server health checks (default: 0.5)

### Customizing Tests

```bash
# Run tests on different port
TEST_PORT=9000 API_URL=http://localhost:9000 julia --project test/runtests.jl

# Extend server wait time
MAX_WAIT_TIME=60 julia --project test/runtests.jl
```

## Writing New Tests

### Adding Integration Tests

Add new test sets to `runtests.jl`:

```julia
@testset "My New Endpoint" begin
    @testset "Test case description" begin
        @info "Testing my endpoint"
        r = HTTP.request("GET", "$API_URL/my/endpoint")
        @test r.status == 200
        @info "✓ Test passed"
    end
end
```

### Adding Unit Tests

Add test sets to `test_getssl.jl`:

```julia
@testset "My New Feature" begin
    # Setup
    data = [...]
    
    # Execute
    result = getssl(data)
    
    # Verify
    @test result[:success] == true
    @test haskey(result, :new_field)
end
```

## Test Best Practices

### 1. Use Descriptive Test Names

```julia
# Good
@testset "Valid request with 20 data points"

# Bad
@testset "Test 1"
```

### 2. Log Test Actions

```julia
@testset "My Test" begin
    @info "Testing feature X with condition Y"
    # test code
    @info "✓ Feature X behaves correctly"
end
```

### 3. Test Both Success and Failure Cases

```julia
@testset "Validation" begin
    @testset "Valid input" begin
        # test valid case
    end
    
    @testset "Invalid input" begin
        # test error handling
    end
end
```

### 4. Verify Complete Response Structure

```julia
@test haskey(result, :success)
@test haskey(result, :message)
@test haskey(result, :data)
@test result[:success] == true
```

## Debugging Test Failures

### 1. Check the Log File

```bash
tail -100 test/runtests.log
```

### 2. Run Tests Verbosely

```julia
# In Julia REPL
using Test
include("test/runtests.jl")
```

### 3. Test Individual Components

```julia
# Test just the getssl function
include("src/api/getssl.jl")
result = getssl([100.0, 101.0, ..., 110.0])
println(result)
```

### 4. Check Server Logs

If the server fails to start, check:
- Port availability: `lsof -i :8765`
- Julia environment: `julia --project -e 'using Pkg; Pkg.status()'`
- Dependencies: Verify all packages are installed

## Continuous Integration

### Example GitHub Actions Workflow

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - uses: julia-actions/setup-julia@v1
        with:
          version: '1.9'
      
      - name: Install dependencies
        run: julia --project -e 'using Pkg; Pkg.instantiate()'
      
      - name: Run tests
        run: julia --project test/runtests.jl
      
      - name: Upload test logs
        if: always()
        uses: actions/upload-artifact@v2
        with:
          name: test-logs
          path: test/runtests.log
```

## Performance Testing

For performance benchmarking:

```julia
using BenchmarkTools

include("src/api/getssl.jl")

prices = randn(100)

@benchmark getssl($prices)
```

## Test Maintenance

### Regular Tasks

1. **Update tests** when adding new features
2. **Review logs** periodically for warnings
3. **Clean old logs**: `rm test/runtests.log`
4. **Verify coverage** of new code paths

### Test Checklist

Before committing:
- [ ] All tests pass
- [ ] New features have tests
- [ ] Edge cases are covered
- [ ] Error handling is tested
- [ ] Documentation is updated

## Troubleshooting

### Server Won't Start
- Check if port 8765 is in use
- Verify Julia dependencies are installed
- Look for errors in console output

### Tests Timeout
- Increase `MAX_WAIT_TIME`
- Check server startup logs
- Verify no firewall blocking

### Intermittent Failures
- Check for resource constraints
- Look for timing issues
- Review log file for patterns

## Resources

- [Julia Test Documentation](https://docs.julialang.org/en/v1/stdlib/Test/)
- [HTTP.jl Documentation](https://juliaweb.github.io/HTTP.jl/)
- [Genie.jl Testing Guide](https://genieframework.github.io/Genie.jl/)

