# myAnalytics.jl 📊

A modern, production-ready **REST API framework** for analytics built with Julia and **Oxygen.jl**. Create powerful data APIs with minimal boilerplate.

![Version](https://img.shields.io/badge/version-0.1.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Julia](https://img.shields.io/badge/julia-1.6+-purple)

## 🚀 Features

- **⚡ High-Performance**: Built on Oxygen.jl for fast request handling
- **🔐 Secure**: SSL/TLS support, API key authentication, rate limiting
- **📦 Modular**: Clean architecture with separation of concerns
- **🛣️ RESTful**: Comprehensive REST API with standard HTTP methods
- **📝 Well-Documented**: Complete guides and examples included
- **🔧 Extensible**: Easy to add custom endpoints and middleware
- **📊 Analytics-Focused**: Pre-built analytics endpoints and utilities
- **🌐 CORS-Enabled**: Cross-origin requests supported
- **📈 Scalable**: Ready for production deployment

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **[QUICK_START.md](QUICK_START.md)** | Get started in 2 minutes ⚡ |
| **[API_GUIDE.md](API_GUIDE.md)** | Complete API reference 📖 |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | System design and extension 🏗️ |
| **[config.example.jl](config.example.jl)** | Configuration template ⚙️ |

## 🎯 Quick Start

### 1️⃣ Prerequisites
```bash
julia --version  # Requires Julia 1.6+
```

### 2️⃣ Install Dependencies
```bash
cd /home/steve/dev/projects/myAnalytics.jl
julia

# In Julia REPL:
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

### 3️⃣ Start the Server
```julia
using myAnalytics
start_analytics_api()  # Runs on 0.0.0.0:8080
```

### 4️⃣ Test the API
```bash
# In another terminal:
curl http://localhost:8080/health
curl http://localhost:8080/api/metrics/list
```

**That's it!** Your analytics API is running. See [QUICK_START.md](QUICK_START.md) for more examples.

## 🏗️ Project Structure

```
myAnalytics.jl/
├── src/
│   ├── myAnalytics.jl              # Main module
│   └── api/
│       ├── server.jl               # Server configuration
│       ├── routes.jl               # API endpoints (customize here)
│       ├── utils.jl                # Utility functions
│       └── middleware.jl           # Request/response middleware
├── ssl/                            # SSL certificates (optional)
├── Project.toml                    # Dependencies
├── start_server.jl                 # CLI startup script
└── Documentation                   # Guides and examples
    ├── QUICK_START.md
    ├── API_GUIDE.md
    ├── ARCHITECTURE.md
    └── config.example.jl
```

## 📡 API Endpoints

### Health & Info
```
GET /health                         # Server health check
GET /api/version                    # API version info
```

### Metrics
```
GET /api/metrics/:metric_name       # Get single metric
GET /api/metrics/list               # List all available metrics
POST /api/metrics/query             # Query with filters
```

### Analytics
```
GET /api/analytics/summary          # Summary statistics
GET /api/analytics/timeseries/:metric  # Time series data
POST /api/analytics/aggregate       # Aggregate multiple metrics
```

**Full API documentation** in [API_GUIDE.md](API_GUIDE.md)

## 💡 Usage Examples

### Starting with Different Configurations

```julia
using myAnalytics

# Default (0.0.0.0:8080)
start_analytics_api()

# Custom port
start_analytics_api(port=3000)

# Custom host
start_analytics_api(host="127.0.0.1", port=8080)

# With SSL
start_analytics_api(
    port=8443,
    ssl=true,
    ssl_cert="ssl/cert.pem",
    ssl_key="ssl/key.pem"
)
```

### Using the Startup Script

```bash
# Default port 8080
julia start_server.jl

# Custom port
julia start_server.jl 3000

# With SSL
julia start_server.jl 8443 --ssl --cert ssl/cert.pem --key ssl/key.pem
```

### Testing with cURL

```bash
# Health check
curl http://localhost:8080/health

# List metrics
curl http://localhost:8080/api/metrics/list

# Get metric
curl http://localhost:8080/api/metrics/cpu_usage

# Query with filters
curl -X POST http://localhost:8080/api/metrics/query \
  -H "Content-Type: application/json" \
  -d '{"metric": "cpu_usage", "filters": {"host": "server1"}}'

# Aggregate metrics
curl -X POST http://localhost:8080/api/analytics/aggregate \
  -H "Content-Type: application/json" \
  -d '{"type": "sum", "metrics": ["cpu_usage", "memory_usage"]}'
```

## 🔧 Customization

### Adding Custom Endpoints

Edit `src/api/routes.jl`:

```julia
@get "/api/custom/:id" function(id::String)
    return Dict(
        :status => 200,
        :data => Dict(:id => id, :value => 42)
    )
end

@post "/api/custom/data" function()
    body = @json
    # Your logic here
    return Dict(:status => 200, :result => "processed")
end
```

### Adding Utility Functions

Edit `src/api/utils.jl`:

```julia
function my_analytics_function(data::Vector)
    return mean(data)
end
```

### Adding Middleware

Edit `src/api/middleware.jl`:

```julia
function my_middleware(handler)
    return function(request)
        # Pre-processing
        response = handler(request)
        # Post-processing
        return response
    end
end
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed extension guide.

## 🔐 Security

- **SSL/TLS**: Optional HTTPS support with your certificates
- **API Key Auth**: Simple per-request authentication
- **Rate Limiting**: Built-in rate limiting per IP address
- **CORS**: Cross-origin request handling
- **Input Validation**: Request body and parameter validation
- **Sanitization**: Basic SQL injection prevention

See [API_GUIDE.md](API_GUIDE.md#-security-features) for security configuration.

## 📦 Dependencies

```toml
[deps]
Oxygen = "4f8fbe84-2c4e-40db-93d7-a95ba6e4f5a1"  # Web framework
JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"    # JSON parsing
Dates = "ade2ca70-3891-5945-98fb-52f0b215db09"   # Date/time utilities
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"    # HTTP support
Parameters = "d96e819e-fc66-5662-9728-84c5a19d735c"  # @with_kw macro
```

## 🚀 Deployment

### Local Development
```bash
julia start_server.jl 8080
```

### Docker
```dockerfile
FROM julia:latest
WORKDIR /app
COPY . .
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
EXPOSE 8080
CMD ["julia", "start_server.jl", "8080"]
```

### Behind Reverse Proxy (nginx)
```nginx
upstream julia_api {
    server localhost:8080;
}

server {
    listen 443 ssl;
    server_name api.example.com;

    location / {
        proxy_pass http://julia_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

See [API_GUIDE.md](API_GUIDE.md#-production-deployment) for deployment details.

## 🧪 Testing

### Test with Julia
```julia
using HTTP, JSON

# Health check
resp = HTTP.get("http://localhost:8080/health")
JSON.parse(String(resp.body))

# Query metrics
body = JSON.json(Dict(:metric => "cpu_usage"))
resp = HTTP.post("http://localhost:8080/api/metrics/query",
    ["Content-Type" => "application/json"], body)
JSON.parse(String(resp.body))
```

### Test with Python
```python
import requests

resp = requests.get('http://localhost:8080/health')
print(resp.json())

resp = requests.post('http://localhost:8080/api/metrics/query',
    json={'metric': 'cpu_usage'})
print(resp.json())
```

### Test with Node.js
```javascript
fetch('http://localhost:8080/health')
    .then(r => r.json())
    .then(data => console.log(data));

fetch('http://localhost:8080/api/metrics/query', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({metric: 'cpu_usage'})
})
    .then(r => r.json())
    .then(data => console.log(data));
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Port already in use** | `lsof -i :8080` then `kill -9 <PID>` |
| **Modules not found** | Run `Pkg.instantiate()` in Julia REPL |
| **SSL errors** | Verify `ssl/cert.pem` and `ssl/key.pem` exist |
| **CORS errors** | CORS is enabled by default for all origins |
| **Connection refused** | Check server is running and on correct host/port |

See [QUICK_START.md](QUICK_START.md#-troubleshooting) for more help.

## 📈 Performance

- **Oxygen.jl** provides excellent performance for Julia applications
- Handles thousands of requests per second
- Memory efficient with Julia's GC
- Suitable for production analytics workloads
- Easily scales horizontally behind a load balancer

## 🎓 Learning Resources

- [Oxygen.jl Documentation](https://oxygenframework.github.io/Oxygen.jl/)
- [Julia Documentation](https://docs.julialang.org/)
- [REST API Best Practices](https://restfulapi.net/)
- [HTTP Status Codes](https://httpwg.org/specs/rfc7231.html#status.codes)

## 🤝 Contributing

Want to extend this framework?

1. **Add routes**: Edit `src/api/routes.jl`
2. **Add utilities**: Edit `src/api/utils.jl`
3. **Add middleware**: Edit `src/api/middleware.jl`
4. **Update docs**: Edit relevant `.md` files

See [ARCHITECTURE.md](ARCHITECTURE.md#-extension-points) for detailed guidance.

## 📄 License

MIT License - Free to use in commercial and private projects.

## 🎯 Roadmap

- [ ] Database integration examples (PostgreSQL, SQLite)
- [ ] WebSocket support for real-time analytics
- [ ] Advanced authentication (OAuth2, JWT)
- [ ] GraphQL endpoint support
- [ ] Prometheus metrics export
- [ ] OpenAPI/Swagger documentation
- [ ] Docker Compose example
- [ ] Kubernetes manifests

## 💬 Support

For help:
1. Check [QUICK_START.md](QUICK_START.md) for common issues
2. Read [API_GUIDE.md](API_GUIDE.md) for API details
3. Review [ARCHITECTURE.md](ARCHITECTURE.md) for design patterns
4. Consult [Oxygen.jl docs](https://oxygenframework.github.io/Oxygen.jl/) for framework-specific help

## 🎉 What's Next?

- ✅ API framework is ready
- 📊 Start building your analytics endpoints
- 🗄️ Connect to your data sources
- 🚀 Deploy to production
- 📈 Monitor and scale

---

**Built with ❤️ using Julia and Oxygen.jl**

Happy building! 🚀
