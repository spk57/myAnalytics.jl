# myAnalytics API Architecture

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Client Applications                    │
│          (Web, Mobile, Desktop, CLI, etc.)               │
└────────────────────┬────────────────────────────────────┘
                     │ HTTP/HTTPS
                     ▼
┌─────────────────────────────────────────────────────────┐
│                Reverse Proxy (Optional)                  │
│                    (nginx, Apache)                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│         myAnalytics API Server (Oxygen.jl)               │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Middleware Stack                          │  │
│  │  ┌─────────────────────────────────────────┐    │  │
│  │  │ - CORS Headers                          │    │  │
│  │  │ - Rate Limiting                         │    │  │
│  │  │ - JSON Validation                       │    │  │
│  │  │ - Authentication                        │    │  │
│  │  │ - Logging                               │    │  │
│  │  └─────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────┘  │
│                     │                                    │
│                     ▼                                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Route Handlers (routes.jl)                │  │
│  │  ┌─────────────────────────────────────────┐    │  │
│  │  │ Health & Info Endpoints                 │    │  │
│  │  │ - /health                               │    │  │
│  │  │ - /api/version                          │    │  │
│  │  └─────────────────────────────────────────┘    │  │
│  │  ┌─────────────────────────────────────────┐    │  │
│  │  │ Metrics Endpoints                       │    │  │
│  │  │ - /api/metrics/:name                    │    │  │
│  │  │ - /api/metrics/list                     │    │  │
│  │  │ - /api/metrics/query (POST)             │    │  │
│  │  └─────────────────────────────────────────┘    │  │
│  │  ┌─────────────────────────────────────────┐    │  │
│  │  │ Analytics Endpoints                     │    │  │
│  │  │ - /api/analytics/summary                │    │  │
│  │  │ - /api/analytics/timeseries/:metric     │    │  │
│  │  │ - /api/analytics/aggregate (POST)       │    │  │
│  │  └─────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────┘  │
│                     │                                    │
│                     ▼                                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │    Utility Functions & Helpers (utils.jl)       │  │
│  │  ┌─────────────────────────────────────────┐    │  │
│  │  │ - Response formatting                   │    │  │
│  │  │ - Input validation                      │    │  │
│  │  │ - Data parsing & transformation         │    │  │
│  │  │ - Statistics calculation                │    │  │
│  │  │ - Logging                               │    │  │
│  │  └─────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────┘  │
│                     │                                    │
│                     ▼                                    │
│         ┌───────────────────────────────┐              │
│         │ Data Layer (External)          │              │
│         │ - Database                     │              │
│         │ - Cache (Redis)                │              │
│         │ - Message Queue                │              │
│         └───────────────────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
myAnalytics.jl/
│
├── src/
│   ├── myAnalytics.jl              # Main module - orchestrates everything
│   │
│   └── api/
│       ├── server.jl               # Server setup and configuration
│       │   ├── start_server()
│       │   ├── stop_server()
│       │   ├── SERVER_CONFIG
│       │   └── Response helpers
│       │
│       ├── routes.jl               # API endpoint definitions
│       │   ├── Health endpoints
│       │   ├── Metrics endpoints
│       │   ├── Analytics endpoints
│       │   └── Error handlers
│       │
│       ├── utils.jl                # Helper functions and utilities
│       │   ├── Response/ErrorResponse structs
│       │   ├── Validation functions
│       │   ├── Data formatting
│       │   ├── Logging utilities
│       │   └── Statistics helpers
│       │
│       └── middleware.jl           # Request/response middleware
│           ├── add_cors_headers()
│           ├── validate_json()
│           ├── rate_limit()
│           ├── authenticate_request()
│           └── logging_middleware()
│
├── ssl/                            # SSL certificates (copied from persfin)
│   ├── cert.pem
│   └── key.pem
│
├── Project.toml                    # Julia project dependencies
├── start_server.jl                 # CLI startup script
├── config.example.jl               # Configuration template
├── API_GUIDE.md                    # Complete API documentation
├── QUICK_START.md                  # Quick start guide (you are here)
└── ARCHITECTURE.md                 # This file

```

## 🔄 Data Flow

### Request Processing Flow

```
1. CLIENT REQUEST
   │
   ├─ HTTP Method (GET, POST, etc.)
   ├─ URL Path & Query Parameters
   ├─ Headers (Content-Type, Authorization, etc.)
   └─ Body (for POST/PUT/PATCH)
   │
   ▼
2. MIDDLEWARE CHAIN
   │
   ├─ [1] CORS Headers Added
   ├─ [2] JSON Validation (if applicable)
   ├─ [3] Rate Limiting Check
   ├─ [4] Authentication Check
   └─ [5] Request Logging
   │
   ▼
3. ROUTE MATCHING (Oxygen.jl Router)
   │
   ├─ Match URL pattern to handler
   ├─ Extract path parameters
   ├─ Parse query parameters
   └─ Identify HTTP method
   │
   ▼
4. ROUTE HANDLER EXECUTION
   │
   ├─ Parse request body
   ├─ Validate inputs
   ├─ Call utility functions
   ├─ Access data layer
   └─ Prepare response data
   │
   ▼
5. RESPONSE CREATION
   │
   ├─ Format data using Response struct
   ├─ Set appropriate status code
   ├─ Include timestamps
   └─ Add metadata
   │
   ▼
6. RESPONSE MIDDLEWARE
   │
   ├─ Add response headers
   ├─ Log response
   └─ Handle compression
   │
   ▼
7. CLIENT RESPONSE
   │
   ├─ HTTP Status Code
   ├─ Response Headers
   └─ JSON Body

```

## 🧩 Module Responsibilities

### `myAnalytics.jl` - Main Module
**Responsibility**: Module orchestration and public API

```
├─ Includes all submodules
├─ Exports public functions
├─ Provides start_analytics_api() entry point
└─ Re-exports from submodules
```

### `server.jl` - Server Module
**Responsibility**: Server initialization and configuration

```
├─ SERVER_CONFIG dictionary
├─ start_server() - Initialize and start Oxygen server
├─ stop_server() - Graceful shutdown
├─ create_response() - Standard response creation
└─ create_error_response() - Error response creation
```

### `routes.jl` - Routes Module
**Responsibility**: Endpoint definitions

```
├─ Health check endpoints
│  ├─ /health
│  └─ /api/version
├─ Metrics endpoints
│  ├─ GET /api/metrics/:metric_name
│  ├─ GET /api/metrics/list
│  └─ POST /api/metrics/query
├─ Analytics endpoints
│  ├─ GET /api/analytics/summary
│  ├─ GET /api/analytics/timeseries/:metric
│  └─ POST /api/analytics/aggregate
└─ Error handler
   └─ 404 catch-all route
```

### `utils.jl` - Utilities Module
**Responsibility**: Reusable helper functions

```
├─ Data Structures
│  ├─ Response @struct
│  └─ ErrorResponse @struct
├─ Validation Functions
│  ├─ validate_metric_name()
│  └─ sanitize_input()
├─ Formatting Functions
│  ├─ format_timestamp()
│  └─ parse_query_params()
├─ Utility Functions
│  ├─ create_logger()
│  ├─ calculate_stats()
│  └─ (add your custom utilities)
└─ Constants & Configuration
```

### `middleware.jl` - Middleware Module
**Responsibility**: Request/response processing

```
├─ add_cors_headers() - CORS support
├─ validate_json() - JSON validation
├─ rate_limit() - Rate limiting per IP
├─ authenticate_request() - API key auth
└─ logging_middleware() - Request/response logging
```

## 🔐 Security Architecture

```
┌─────────────────────────────────────────┐
│      Security Layers                     │
├─────────────────────────────────────────┤
│ 1. SSL/TLS (Transport Layer)            │
│    - Encrypted connections              │
│    - Certificate-based authentication   │
├─────────────────────────────────────────┤
│ 2. Authentication (API Key)             │
│    - Header-based or query param        │
│    - Per-endpoint control               │
├─────────────────────────────────────────┤
│ 3. Input Validation                     │
│    - Type checking                      │
│    - Format validation                  │
│    - Size limits                        │
├─────────────────────────────────────────┤
│ 4. Rate Limiting                        │
│    - Per-IP limiting                    │
│    - Sliding window algorithm           │
│    - 429 Too Many Requests response     │
├─────────────────────────────────────────┤
│ 5. CORS Control                         │
│    - Cross-origin request handling      │
│    - Origin validation                  │
├─────────────────────────────────────────┤
│ 6. Input Sanitization                   │
│    - SQL injection prevention           │
│    - XSS prevention                     │
│    - Special character handling         │
└─────────────────────────────────────────┘
```

## 📊 Scalability Considerations

### Horizontal Scaling
```
Load Balancer (nginx)
    │
    ├── Server Instance 1 (port 8080)
    ├── Server Instance 2 (port 8081)
    └── Server Instance 3 (port 8082)
    
    Shared Resources:
    - Database
    - Redis Cache
    - Message Queue
```

### Performance Optimization
- **Caching**: Implement response caching in Redis
- **Database**: Use connection pooling for database access
- **Async Operations**: Use Julia Tasks for long-running operations
- **Compression**: Enable response compression for large payloads

## 🔌 Extension Points

### Adding Custom Endpoints

File: `src/api/routes.jl`

```julia
@get "/api/custom/:id" function(id::String)
    # Your custom logic
    return response_dict
end
```

### Adding Custom Utilities

File: `src/api/utils.jl`

```julia
function my_custom_function(data::Dict)
    # Your logic
    return result
end
```

### Adding Custom Middleware

File: `src/api/middleware.jl`

```julia
function my_custom_middleware(handler)
    return function(request)
        # Pre-processing
        response = handler(request)
        # Post-processing
        return response
    end
end
```

## 🚀 Deployment Patterns

### Pattern 1: Standalone Server
```bash
julia start_server.jl 8080
```

### Pattern 2: Behind Reverse Proxy
```
Client → nginx (443) → localhost:8080 (API)
```

### Pattern 3: Docker Container
```dockerfile
FROM julia:latest
WORKDIR /app
COPY . .
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
EXPOSE 8080
CMD ["julia", "start_server.jl", "8080"]
```

### Pattern 4: Kubernetes
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myanalytics-api
spec:
  containers:
  - name: api
    image: myanalytics:latest
    ports:
    - containerPort: 8080
```

## 📈 Performance Metrics

Consider monitoring:
- **Request Latency**: Time to process requests
- **Throughput**: Requests per second
- **Error Rate**: 4xx/5xx responses
- **Resource Usage**: CPU, Memory, Disk I/O
- **Database Performance**: Query times, connection pool
- **Cache Hit Ratio**: Cache effectiveness

## 🔧 Configuration Management

```julia
# In server.jl
SERVER_CONFIG = Dict(
    :host => "0.0.0.0",
    :port => 8080,
    :ssl => false,
    :ssl_cert => "",
    :ssl_key => ""
)
```

Override with environment variables or startup arguments.

---

This architecture provides:
✅ **Modularity**: Clean separation of concerns  
✅ **Scalability**: Easy to extend and optimize  
✅ **Security**: Multiple security layers  
✅ **Maintainability**: Clear structure and conventions  
✅ **Performance**: Built for speed with Oxygen.jl  

