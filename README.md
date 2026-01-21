# myAnalytics.jl

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A REST API for analytics operations built with Julia and Genie.jl, featuring 
- Structural state space learning analysis for time series data.

## Features

- 📊 **Time Series Analysis**: Structural state space learning using StateSpaceLearning.jl
- 📖 **Interactive Documentation**: Swagger UI for easy API exploration

## Quick Start

### Prerequisites

- Julia 1.6 or higher
- Dependencies: Genie, HTTP, JSON, StateSpaceLearning, Statistics

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd myAnalytics.jl
```

2. Install dependencies:
```julia
julia --project -e 'using Pkg; Pkg.instantiate()'
```

### Running the Server

#### Option 1: Using the startup script
```bash
./start_server.sh
```

The server will start on port 8765 by default.

#### Option 2: Manual start
```bash
julia --project src/myAnalytics.jl
```

Or specify a custom port:
```bash
PORT=8080 julia --project src/myAnalytics.jl
```

### Access the API

- **API Base URL**: `http://localhost:8765`
- **Interactive Documentation**: `http://localhost:8765/docs`
- **OpenAPI Spec**: `http://localhost:8765/swagger.json`

## API Endpoints

### Health Check
```http
GET /health
```
Returns the health status of the API server.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-12T10:30:00.123",
  "version": "0.0.1",
  "uptime_seconds": 3600,
  "service": "myAnalytics.jl"
}
```

Use this endpoint for monitoring, health checks, and load balancer probes.

### Logger Endpoints

#### POST /api/logger
Create a new log entry with datetime, transaction, name, value, and source.

**Request Body:**
```json
{
  "datetime": "2025-01-01T10:30:00",
  "transaction": "logging",
  "name": "temperature",
  "value": 23.5,
  "source": "sensor-01"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Log entry created successfully",
  "id": 1
}
```

#### GET /api/logger
Retrieve log entries with optional filtering and pagination.

**Query Parameters:**
- `limit`: Maximum entries to return (default: 100)
- `offset`: Number of entries to skip (default: 0)
- `source`: Filter by source
- `name`: Filter by name

#### GET /api/logger/stats
Get statistics about logged entries (total count, unique sources/names).

**Data Storage:** Log entries are persisted to `logger.csv` in the project root directory.

**See [Logger API Documentation](docs/LOGGER_API.md) for detailed examples and usage.**

### Root Endpoint
```http
GET /
```
Returns a simple HTML page.

### Analytics Endpoint

#### POST /api/getssl
Performs structural state space learning analysis on time series price data.

**Request Body:**
```json
{
  "prices": [100.0, 102.5, 101.0, 103.5, 105.0, ...]
}
```

**Requirements:**
- Minimum 10 data points required
- Values must be numeric (Float64)

**Response (Success):**
```json
{
  "success": true,
  "message": "Analysis completed successfully",
  "predicted": [120.0, 121.5, ...],
  "fitted": [100.1, 102.4, ...],
  "stats": {
    "mean": 110.5,
    "std": 5.2,
    "max": 119.0,
    "min": 100.0,
    "return": 19.0,
    "swmax": 2.5,
    "swmaxd": 4,
    "swmind": 1
  },
  "level": [...],
  "trend": [...],
  "seasonal_week": [...],
  "seasonal_month": [...]
}
```

**Response Fields:**
- `predicted`: 20-step ahead forecast values
- `fitted`: Model fitted values for input data
- `stats`: Statistical measures
  - `mean`: Average of input prices
  - `std`: Standard deviation
  - `max/min`: Maximum/minimum values
  - `return`: Percentage return (first to last)
  - `swmax`: Weekly seasonal maximum range
  - `swmaxd/swmind`: Day index of weekly max/min
  - `smmax/smmaxd/smmind`: Monthly seasonal statistics (for data > 40 points)
- `level`: Level component of the time series
- `trend`: Trend component (level + slope)
- `seasonal_week`: Weekly seasonal component (5-day period)
- `seasonal_month`: Monthly seasonal component (20-day period, if applicable)

**Error Responses:**

Missing prices field (400):
```json
{
  "success": false,
  "message": "Error: Missing 'prices' field in request"
}
```

Insufficient data (200):
```json
{
  "success": false,
  "message": "Insufficient number of data points"
}
```

### Documentation Endpoints

#### GET /docs
Interactive Swagger UI documentation

#### GET /swagger.json
OpenAPI 3.0 specification in JSON format

#### GET /api-docs
Redirects to `/docs`

## Usage Examples

### Using curl

```bash
# Simple request with valid data
curl -X POST http://localhost:8765/api/getssl \
  -H "Content-Type: application/json" \
  -d '{
    "prices": [100.0, 102.5, 101.0, 103.5, 105.0, 104.0, 106.5, 108.0, 107.5, 109.0,
                110.0, 111.5, 112.0, 113.5, 115.0, 114.0, 116.5, 118.0, 117.5, 119.0]
  }'
```

### Using Python

```python
import requests
import json

url = "http://localhost:8765/api/getssl"
data = {
    "prices": [100.0, 102.5, 101.0, 103.5, 105.0, 104.0, 106.5, 108.0, 107.5, 109.0,
               110.0, 111.5, 112.0, 113.5, 115.0, 114.0, 116.5, 118.0, 117.5, 119.0]
}

response = requests.post(url, json=data)
result = response.json()

if result["success"]:
    print(f"Mean: {result['stats']['mean']}")
    print(f"Predicted values: {result['predicted'][:5]}...")
else:
    print(f"Error: {result['message']}")
```

### Using Julia

```julia
using HTTP
using JSON

url = "http://localhost:8765/api/getssl"
prices = [100.0, 102.5, 101.0, 103.5, 105.0, 104.0, 106.5, 108.0, 107.5, 109.0,
          110.0, 111.5, 112.0, 113.5, 115.0, 114.0, 116.5, 118.0, 117.5, 119.0]

payload = JSON.json(Dict("prices" => prices))
response = HTTP.post(url, 
                     body=payload,
                     headers=Dict("Content-Type" => "application/json"))

result = JSON.parse(String(response.body))
println("Success: ", result["success"])
println("Mean: ", result["stats"]["mean"])
```

## Testing

### Running All Tests

The test suite automatically starts and stops the server:

```bash
julia --project test/runtests.jl
```

Test results are logged to both console and `test/runtests.log`.

### Running Unit Tests

Test the `getssl` function directly:

```bash
julia --project test/test_getssl.jl
```

### Test Coverage

The test suite includes:
- ✅ GET endpoint tests (/, /swagger.json, /docs)
- ✅ Redirect tests (/api-docs)
- ✅ Error handling (404, missing fields)
- ✅ Valid analytics requests
- ✅ Insufficient data validation
- ✅ Edge cases (exactly 10 and 40 data points)

## Configuration

### Environment Variables

- `PORT`: Server port (default: 8001)
- `API_URL`: API base URL for tests (default: http://localhost:8765)

### Project Structure

```
myAnalytics.jl/
├── src/
│   ├── myAnalytics.jl          # Main server module
│   └── api/
│       └── getssl.jl           # Analytics endpoint implementation
├── test/
│   ├── runtests.jl             # Integration tests with server management
│   ├── test_getssl.jl          # Unit tests for getssl function
│   └── runtests.log            # Test execution log
├── public/
│   └── swagger-ui.html         # Swagger UI interface
├── swagger.json                # OpenAPI 3.0 specification
├── start_server.sh             # Server startup script
├── .gitignore                  # Git ignore patterns
└── README.md                   # This file
```

## Development

### Adding New Endpoints

1. Create your function in `src/api/`
2. Add the route in `src/myAnalytics.jl`
3. Update `swagger.json` with endpoint documentation
4. Add tests in `test/runtests.jl`

Example:
```julia
# In src/myAnalytics.jl
route("/api/myendpoint", method = POST) do
    try
        data = Genie.Requests.jsonpayload()
        # Your logic here
        return json(Dict(:success => true, :result => result))
    catch e
        return json(Dict(:success => false, :message => "Error: $(sprint(showerror, e))"))
    end
end
```

## Error Handling

The API uses consistent error response format:

```json
{
  "success": false,
  "message": "Descriptive error message"
}
```

Common error scenarios:
- Missing required fields → Detailed error message
- Insufficient data points → Clear minimum requirement
- Server errors → Generic error message (no stack traces exposed)

## Performance Notes

- **Minimum data points**: 10 (for basic analysis)
- **Monthly analysis threshold**: > 40 data points
- **Forecast horizon**: 20 steps ahead
- **Weekly seasonal period**: 5 days
- **Monthly seasonal period**: 20 days

## Troubleshooting

### Server won't start
- Check if the port is already in use
- Verify all dependencies are installed
- Check for syntax errors in the code

### Tests fail
- Ensure no other server is running on port 8765
- Check `test/runtests.log` for detailed error information
- Verify project dependencies are up to date

### API returns errors
- Verify JSON payload format
- Ensure minimum 10 data points
- Check that values are numeric

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

[Contribution guidelines here]

## Support

For issues, questions, or contributions, please [open an issue or contact the maintainer].

