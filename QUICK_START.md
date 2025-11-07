# Quick Start Guide - myAnalytics API

## 🚀 Get Running in 2 Minutes

### Step 1: Navigate to Project
```bash
cd /home/steve/dev/projects/myAnalytics.jl
```

### Step 2: Start Julia and Install Dependencies
```bash
julia

# Inside Julia REPL:
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

### Step 3: Start the API Server
```julia
using myAnalytics
start_analytics_api()
```

You should see:
```
============================================================
🚀 Starting myAnalytics API Server
============================================================
Host: 0.0.0.0
Port: 8080
SSL: false
============================================================
```

### Step 4: Test the API (in another terminal)

```bash
# Health check
curl http://localhost:8080/health

# List all metrics
curl http://localhost:8080/api/metrics/list

# Get a specific metric
curl http://localhost:8080/api/metrics/cpu_usage

# Query metrics with filters
curl -X POST http://localhost:8080/api/metrics/query \
  -H "Content-Type: application/json" \
  -d '{"metric": "cpu_usage"}'
```

## 🔥 Common Commands

### Start with Custom Port
```julia
start_analytics_api(port=3000)
```

### Start with Custom Host
```julia
start_analytics_api(host="127.0.0.1", port=8080)
```

### Start with SSL
```julia
start_analytics_api(
    port=8443,
    ssl=true,
    ssl_cert="ssl/cert.pem",
    ssl_key="ssl/key.pem"
)
```

### Using the Startup Script
```bash
# Default (0.0.0.0:8080)
julia start_server.jl

# Custom port
julia start_server.jl 3000

# With SSL
julia start_server.jl 8443 --ssl --cert ssl/cert.pem --key ssl/key.pem
```

## 📚 Available Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check |
| `/api/version` | GET | API version info |
| `/api/metrics/:metric_name` | GET | Get single metric |
| `/api/metrics/list` | GET | List all metrics |
| `/api/metrics/query` | POST | Query metrics with filters |
| `/api/analytics/summary` | GET | Analytics summary stats |
| `/api/analytics/timeseries/:metric` | GET | Time series data |
| `/api/analytics/aggregate` | POST | Aggregate multiple metrics |

## 🧪 Quick Test Examples

### JavaScript/Node.js
```javascript
// Fetch health status
fetch('http://localhost:8080/health')
  .then(r => r.json())
  .then(data => console.log(data));

// Query metrics
fetch('http://localhost:8080/api/metrics/query', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({metric: 'cpu_usage', filters: {}})
})
  .then(r => r.json())
  .then(data => console.log(data));
```

### Python
```python
import requests

# Health check
response = requests.get('http://localhost:8080/health')
print(response.json())

# Query metrics
response = requests.post(
    'http://localhost:8080/api/metrics/query',
    json={'metric': 'cpu_usage', 'filters': {}}
)
print(response.json())
```

### Julia
```julia
using HTTP, JSON

# Health check
resp = HTTP.get("http://localhost:8080/health")
println(JSON.parse(String(resp.body)))

# Query metrics
body = JSON.json(Dict(:metric => "cpu_usage", :filters => Dict()))
resp = HTTP.post("http://localhost:8080/api/metrics/query", 
    ["Content-Type" => "application/json"], body)
println(JSON.parse(String(resp.body)))
```

## 🛠️ Modifying the API

### Add New Endpoint
Edit `src/api/routes.jl`:

```julia
@get "/api/custom/path" function()
    return Dict(
        :status => 200,
        :data => Dict(:message => "Hello!")
    )
end
```

### Add Utility Function
Edit `src/api/utils.jl`:

```julia
function my_helper(data)
    # Your logic
    return result
end
```

### Add Middleware
Edit `src/api/middleware.jl`:

```julia
function my_middleware(handler)
    return function(request)
        # Before
        response = handler(request)
        # After
        return response
    end
end
```

## 🚨 Troubleshooting

**Q: Port 8080 already in use**
```bash
lsof -i :8080
kill -9 <PID>
```

**Q: Module not found error**
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

**Q: SSL certificate errors**
Check files exist:
```bash
ls -la ssl/cert.pem ssl/key.pem
```

**Q: Can't connect to API**
- Check server is running
- Check firewall settings
- Check correct host/port
- Try: `curl -v http://localhost:8080/health`

## 📖 Full Documentation

See `API_GUIDE.md` for complete documentation.

## 🎯 Next Steps

1. **Customize endpoints** in `src/api/routes.jl`
2. **Add your analytics logic** in route handlers
3. **Connect to database** using appropriate Julia packages
4. **Deploy** using Docker or your preferred platform

Happy coding! 🎉

