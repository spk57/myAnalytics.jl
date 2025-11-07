# myAnalytics API Framework

A modern, lightweight, and production-ready REST API framework for analytics built with Julia and Oxygen.jl.

## 🚀 Quick Start

### Prerequisites
- Julia 1.6+
- SSL certificates (optional, in `/ssl` directory)

### Installation

```bash
cd /home/steve/dev/projects/myAnalytics.jl
julia
```

In Julia REPL:
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using myAnalytics
start_analytics_api()
```

### Starting the Server

#### Option 1: Using Julia REPL
```julia
using myAnalytics
start_analytics_api()  # Starts on 0.0.0.0:8080
```

#### Option 2: Using startup script
```bash
julia start_server.jl 8080
julia start_server.jl 8443 --ssl --cert ssl/cert.pem --key ssl/key.pem
```

## 📋 API Endpoints

### Health & Info Endpoints

#### Health Check
```
GET /health
```
Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T10:00:00.000",
  "service": "myAnalytics"
}
```

#### Version Info
```
GET /api/version
```
Response:
```json
{
  "version": "0.1.0",
  "name": "myAnalytics",
  "api_version": "1.0"
}
```

### Metrics Endpoints

#### Get Single Metric
```
GET /api/metrics/:metric_name
```

**Example:**
```bash
curl http://localhost:8080/api/metrics/cpu_usage
```

Response:
```json
{
  "status": 200,
  "data": {
    "metric": "cpu_usage",
    "value": 45.3,
    "timestamp": "2024-01-01T10:00:00.000",
    "unit": "units"
  },
  "message": "Metric retrieved successfully"
}
```

#### List All Metrics
```
GET /api/metrics/list
```

Response:
```json
{
  "status": 200,
  "data": [
    {"name": "cpu_usage", "type": "gauge", "unit": "%"},
    {"name": "memory_usage", "type": "gauge", "unit": "MB"},
    {"name": "requests_total", "type": "counter", "unit": "count"},
    {"name": "request_duration", "type": "histogram", "unit": "ms"},
    {"name": "errors_total", "type": "counter", "unit": "count"}
  ],
  "count": 5
}
```

#### Query Metrics
```
POST /api/metrics/query
Content-Type: application/json

{
  "metric": "cpu_usage",
  "filters": {
    "host": "server1",
    "start_time": "2024-01-01T00:00:00Z"
  }
}
```

Response:
```json
{
  "status": 200,
  "data": {
    "metric": "cpu_usage",
    "filters": {...},
    "result": 67.3,
    "timestamp": "2024-01-01T10:00:00.000"
  },
  "message": "Query executed successfully"
}
```

### Analytics Endpoints

#### Summary Statistics
```
GET /api/analytics/summary
```

Response:
```json
{
  "status": 200,
  "data": {
    "total_metrics": 42,
    "active_users": 128,
    "data_points": 15324,
    "last_update": "2024-01-01T10:00:00.000",
    "status": "operational"
  }
}
```

#### Time Series Data
```
GET /api/analytics/timeseries/:metric
```

**Example:**
```bash
curl http://localhost:8080/api/analytics/timeseries/cpu_usage
```

Response:
```json
{
  "status": 200,
  "data": {
    "metric": "cpu_usage",
    "timestamps": ["2024-01-01T10:00:00", "2024-01-01T11:00:00", ...],
    "values": [45.3, 52.1, 48.9, ...],
    "period": "24h"
  }
}
```

#### Aggregate Metrics
```
POST /api/analytics/aggregate
Content-Type: application/json

{
  "type": "sum",
  "metrics": ["cpu_usage", "memory_usage"]
}
```

Response:
```json
{
  "status": 200,
  "data": {
    "type": "sum",
    "metrics": ["cpu_usage", "memory_usage"],
    "result": 892.3,
    "timestamp": "2024-01-01T10:00:00.000"
  }
}
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the project root:

```
MYANALYTICS_HOST=0.0.0.0
MYANALYTICS_PORT=8080
MYANALYTICS_SSL=false
MYANALYTICS_CERT_PATH=ssl/cert.pem
MYANALYTICS_KEY_PATH=ssl/key.pem
```

### SSL/TLS Setup

Place your SSL certificates in the `/ssl` directory:
- `ssl/cert.pem` - Your SSL certificate
- `ssl/key.pem` - Your private key

Then start with SSL enabled:
```julia
start_analytics_api(
    ssl=true,
    ssl_cert="ssl/cert.pem",
    ssl_key="ssl/key.pem"
)
```

## 📦 Project Structure

```
myAnalytics.jl/
├── src/
│   ├── myAnalytics.jl           # Main module
│   └── api/
│       ├── server.jl            # Server configuration and startup
│       ├── routes.jl            # API endpoints
│       ├── utils.jl             # Utility functions and helpers
│       └── middleware.jl        # Request/response middleware
├── ssl/                         # SSL certificates (if applicable)
├── Project.toml                 # Dependencies
├── start_server.jl              # Startup script
└── API_GUIDE.md                 # This file
```

## 🔐 Security Features

### CORS Support
All endpoints support Cross-Origin Resource Sharing (CORS) by default.

### Rate Limiting
Implement rate limiting per IP address (configurable):
```julia
# In middleware.jl
rate_limit(max_requests=100, window=60)  # 100 requests per 60 seconds
```

### Input Validation
- Metric names validated against alphanumeric + underscore pattern
- JSON body validation for POST/PUT requests
- Basic SQL injection prevention

### Authentication (Optional)
Add API key authentication:
```julia
authenticate_request(api_key="your-secret-key")
```

## 🧪 Testing the API

### Using cURL

```bash
# Health check
curl http://localhost:8080/health

# List metrics
curl http://localhost:8080/api/metrics/list

# Get single metric
curl http://localhost:8080/api/metrics/cpu_usage

# Query metrics (POST)
curl -X POST http://localhost:8080/api/metrics/query \
  -H "Content-Type: application/json" \
  -d '{
    "metric": "cpu_usage",
    "filters": {"host": "server1"}
  }'

# Aggregate metrics (POST)
curl -X POST http://localhost:8080/api/analytics/aggregate \
  -H "Content-Type: application/json" \
  -d '{
    "type": "sum",
    "metrics": ["cpu_usage", "memory_usage"]
  }'
```

### Using Julia

```julia
using HTTP, JSON

# Health check
resp = HTTP.get("http://localhost:8080/health")
JSON.parse(String(resp.body))

# Get metric
resp = HTTP.get("http://localhost:8080/api/metrics/cpu_usage")
JSON.parse(String(resp.body))

# Query metrics
body = JSON.json(Dict(:metric => "cpu_usage", :filters => Dict()))
resp = HTTP.post("http://localhost:8080/api/metrics/query", ["Content-Type" => "application/json"], body)
JSON.parse(String(resp.body))
```

## 📊 Extending the Framework

### Adding New Endpoints

Edit `src/api/routes.jl` and add:

```julia
@get "/api/custom/:id" function(id::String)
    return Dict(
        :status => 200,
        :data => Dict(:id => id, :custom => "data")
    )
end

@post "/api/custom/process" function()
    body = @json
    # Process body
    return Dict(:status => 200, :result => "processed")
end
```

### Adding Middleware

Edit `src/api/middleware.jl` and create new middleware functions:

```julia
function custom_middleware(handler)
    return function(request)
        # Pre-processing
        response = handler(request)
        # Post-processing
        return response
    end
end
```

### Adding Utility Functions

Edit `src/api/utils.jl` and add helper functions:

```julia
function my_calculation(data::Dict)
    # Your custom logic
    return result
end
```

## 🚀 Production Deployment

### Performance Tips

1. **Use SSL/TLS** for secure connections
2. **Enable compression** for large responses
3. **Configure rate limiting** appropriately
4. **Use reverse proxy** (nginx, Apache) in front
5. **Monitor server logs** regularly

### Example nginx Configuration

```nginx
upstream julia_app {
    server 127.0.0.1:8080;
}

server {
    listen 443 ssl;
    server_name analytics.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://julia_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📚 Dependencies

- **Oxygen.jl** - Web framework
- **JSON.jl** - JSON parsing
- **Dates** - Timestamp handling
- **HTTP.jl** - HTTP utilities
- **Parameters.jl** - @with_kw macro

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Find process using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>
```

### SSL Certificate Issues
Ensure SSL files exist in `/ssl/` directory:
```bash
ls -la ssl/cert.pem ssl/key.pem
```

### Dependencies Not Installed
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()  # Install all dependencies
```

## 📝 License

myAnalytics.jl - Analytics API Framework

## 🤝 Contributing

To extend the framework:
1. Add new routes in `src/api/routes.jl`
2. Add utilities in `src/api/utils.jl`
3. Add middleware in `src/api/middleware.jl`
4. Update documentation here

## 📞 Support

For issues or questions, check:
- Oxygen.jl documentation: https://oxygenframework.github.io/Oxygen.jl/
- Julia documentation: https://docs.julialang.org/

