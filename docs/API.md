# API Documentation

## myAnalytics.jl REST API

Version: 0.0.1

Base URL: `http://localhost:8765` (default)

## Authentication

Currently, no authentication is required. This is suitable for internal/development use. For production, consider adding authentication middleware.

## Endpoints

### GET /

**Description**: Root endpoint, returns simple HTML page.

**Response**: 
- Status: 200 OK
- Content-Type: text/html

---

### POST /api/getssl

**Description**: Performs structural state space learning analysis on time series price data. Decomposes the time series into trend, level, and seasonal components, and provides forecasts.

**Request Headers**:
- Content-Type: application/json

**Request Body**:
```json
{
  "prices": [number]  // Array of numeric price values
}
```

**Request Body Schema**:
- `prices` (required): Array of Float64 numbers
  - Minimum length: 10
  - No maximum length, but performance may vary with very large datasets
  - Values must be numeric (integers or floats)

**Success Response** (200 OK):
```json
{
  "success": true,
  "message": "Analysis completed successfully",
  "predicted": [number],      // 20-step ahead forecasts
  "fitted": [number],          // Fitted values for input data
  "stats": {
    "mean": number,            // Mean of input prices
    "std": number,             // Standard deviation
    "max": number,             // Maximum value
    "min": number,             // Minimum value
    "return": number,          // Percentage return (first to last)
    "swmax": number,           // Weekly seasonal max range
    "swmaxd": integer,         // Day index of weekly seasonal max (1-5)
    "swmind": integer,         // Day index of weekly seasonal min (1-5)
    "smmax": number,           // Monthly seasonal max range (optional)
    "smmaxd": integer,         // Day index of monthly seasonal max (optional, 1-20)
    "smmind": integer          // Day index of monthly seasonal min (optional, 1-20)
  },
  "level": [number],           // Level component
  "slope": [number],           // Slope component  
  "trend": [number],           // Trend component (level + slope)
  "seasonal_week": [number],   // Weekly seasonal component (5-day period)
  "seasonal_month": [number]   // Monthly seasonal component (20-day period, if > 40 points)
}
```

**Error Response** (400 Bad Request) - Missing prices field:
```json
{
  "success": false,
  "message": "Error: Missing 'prices' field in request"
}
```

**Error Response** (200 OK) - Insufficient data:
```json
{
  "success": false,
  "message": "Insufficient data points for analysis. Need at least 10, got N"
}
```

**Error Response** (200 OK) - General error:
```json
{
  "success": false,
  "message": "Error in analysis: [error details]"
}
```

**Analysis Details**:

The endpoint uses StateSpaceLearning.jl to perform structural decomposition:

1. **Model Components**:
   - Level (μ): The baseline value
   - Slope (ν): Rate of change
   - Weekly Seasonal (γ_5): 5-day repeating pattern
   - Monthly Seasonal (γ_20): 20-day repeating pattern (only if > 40 data points)

2. **Forecasting**:
   - Generates 20-step ahead predictions
   - Uses learned components to project future values
   - Accounts for trend and seasonality

3. **Statistics**:
   - Basic statistics (mean, std, min, max)
   - Return calculation: `100 * (last_price - first_price) / first_price`
   - Seasonal peak information for pattern analysis

**Example Request**:
```bash
curl -X POST http://localhost:8765/api/getssl \
  -H "Content-Type: application/json" \
  -d '{
    "prices": [100, 102, 101, 103, 105, 104, 106, 108, 107, 109, 110]
  }'
```

**Example Response**:
```json
{
  "success": true,
  "message": "Analysis completed successfully",
  "predicted": [110.5, 111.2, 111.8, 112.5, 113.1, ...],
  "fitted": [100.1, 102.0, 100.9, 103.1, 104.8, ...],
  "stats": {
    "mean": 105.0,
    "std": 3.5,
    "max": 110.0,
    "min": 100.0,
    "return": 10.0,
    "swmax": 2.3,
    "swmaxd": 4,
    "swmind": 1
  },
  "level": [...],
  "trend": [...],
  "seasonal_week": [...]
}
```

---

### GET /docs

**Description**: Interactive Swagger UI documentation interface.

**Response**:
- Status: 200 OK
- Content-Type: text/html
- Returns Swagger UI HTML page

**Usage**: Open in a web browser to explore and test API endpoints interactively.

---

### GET /swagger.json

**Description**: OpenAPI 3.0 specification in JSON format.

**Response**:
- Status: 200 OK
- Content-Type: application/json
- Returns complete OpenAPI specification

**Usage**: Can be imported into API tools like Postman, Insomnia, or used to generate client SDKs.

---

### GET /api-docs

**Description**: Convenience redirect to `/docs`.

**Response**:
- Status: 302 Found
- Location: /docs

---

## HTTP Status Codes

- **200 OK**: Request succeeded
- **302 Found**: Redirect to another endpoint
- **400 Bad Request**: Invalid request (missing required fields)
- **404 Not Found**: Endpoint not found
- **500 Internal Server Error**: Server error (generic error message only)

## Rate Limiting

Currently no rate limiting is implemented. For production use, consider adding rate limiting middleware.

## CORS

CORS headers are not currently configured. Configure as needed for your deployment environment.

## Data Types

All numeric values in requests and responses are Float64 (double precision floating point).

## Versioning

API version is indicated in the OpenAPI specification. Breaking changes will result in a major version bump.

## Error Handling Philosophy

- User-facing error messages are clean and informative
- No stack traces or internal details are exposed
- Errors are logged server-side for debugging
- Consistent error response format across all endpoints

## Best Practices

1. **Always validate responses**: Check the `success` field before using data
2. **Handle errors gracefully**: Implement proper error handling in clients
3. **Provide sufficient data**: Ensure at least 10 data points for analysis
4. **Monitor performance**: Larger datasets (> 1000 points) may take longer to process
5. **Use appropriate timeouts**: Set reasonable HTTP timeouts for client requests

## Integration Examples

### Python with pandas

```python
import pandas as pd
import requests

# Load your time series data
df = pd.read_csv('prices.csv')
prices = df['price'].tolist()

# Make API request
response = requests.post(
    'http://localhost:8765/api/getssl',
    json={'prices': prices}
)

result = response.json()

if result['success']:
    # Create DataFrame with results
    forecast_df = pd.DataFrame({
        'predicted': result['predicted']
    })
    print(forecast_df.head())
```

### Julia with DataFrames

```julia
using HTTP, JSON, DataFrames

# Load data
prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0, 107.0, 109.0, 110.0]

# Make request
response = HTTP.post(
    "http://localhost:8765/api/getssl",
    body=JSON.json(Dict("prices" => prices)),
    headers=Dict("Content-Type" => "application/json")
)

result = JSON.parse(String(response.body))

if result["success"]
    # Convert to DataFrame
    df = DataFrame(
        predicted = result["predicted"],
        fitted = result["fitted"][1:length(result["predicted"])]
    )
    println(first(df, 5))
end
```

### R with httr

```r
library(httr)
library(jsonlite)

prices <- c(100, 102, 101, 103, 105, 104, 106, 108, 107, 109, 110)

response <- POST(
  "http://localhost:8765/api/getssl",
  body = list(prices = prices),
  encode = "json"
)

result <- content(response, "parsed")

if (result$success) {
  cat("Mean:", result$stats$mean, "\n")
  cat("Return:", result$stats$return, "%\n")
}
```

## Changelog

### Version 0.0.1
- Initial release
- Single analytics endpoint `/api/getssl`
- Swagger documentation
- Comprehensive error handling

