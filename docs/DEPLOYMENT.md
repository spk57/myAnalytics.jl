# Deployment Guide

Guide for deploying myAnalytics.jl in production environments.

## Prerequisites

- Julia 1.6+ installed on the server
- Sufficient memory (recommended: 2GB+ RAM)
- Open port for the API (default: 8001)
- Process manager (systemd, PM2, or similar)

## Deployment Options

### Option 1: Systemd Service (Linux)

#### 1. Create Service File

Create `/etc/systemd/system/myanalytics.service`:

```ini
[Unit]
Description=myAnalytics.jl API Server
After=network.target

[Service]
Type=simple
User=youruser
WorkingDirectory=/path/to/myAnalytics.jl
Environment="PORT=8001"
Environment="JULIA_PROJECT=@."
ExecStart=/usr/bin/julia --project src/myAnalytics.jl
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

#### 2. Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable myanalytics

# Start service
sudo systemctl start myanalytics

# Check status
sudo systemctl status myanalytics
```

#### 3. View Logs

```bash
# Follow logs
sudo journalctl -u myanalytics -f

# View recent logs
sudo journalctl -u myanalytics -n 100
```

### Option 2: Docker Container

#### 1. Create Dockerfile

```dockerfile
FROM julia:1.9

# Set working directory
WORKDIR /app

# Copy project files
COPY Project.toml Manifest.toml ./
COPY src/ ./src/
COPY swagger.json ./
COPY public/ ./public/

# Install dependencies
RUN julia --project -e 'using Pkg; Pkg.instantiate()'

# Expose port
EXPOSE 8001

# Set environment
ENV PORT=8001

# Run server
CMD ["julia", "--project", "src/myAnalytics.jl"]
```

#### 2. Build and Run

```bash
# Build image
docker build -t myanalytics:latest .

# Run container
docker run -d \
  --name myanalytics \
  -p 8001:8001 \
  -e PORT=8001 \
  --restart unless-stopped \
  myanalytics:latest

# View logs
docker logs -f myanalytics
```

#### 3. Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8001:8001"
    environment:
      - PORT=8001
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/"]
      interval: 30s
      timeout: 10s
      retries: 3
```

Run with:
```bash
docker-compose up -d
```

### Option 3: Reverse Proxy with Nginx

#### Nginx Configuration

```nginx
upstream myanalytics_backend {
    server localhost:8001;
}

server {
    listen 80;
    server_name api.yourdomain.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    # SSL certificates
    ssl_certificate /path/to/ssl/cert.pem;
    ssl_certificate_key /path/to/ssl/key.pem;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Logging
    access_log /var/log/nginx/myanalytics_access.log;
    error_log /var/log/nginx/myanalytics_error.log;

    # Proxy settings
    location / {
        proxy_pass http://myanalytics_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Serve static files directly (if any)
    location /static/ {
        alias /path/to/myAnalytics.jl/public/;
        expires 30d;
    }
}
```

## Production Configuration

### Environment Variables

```bash
# Port configuration
export PORT=8001

# Julia threads (for parallel processing)
export JULIA_NUM_THREADS=4

# Memory management
export JULIA_GC_ALLOC_POOL=1048576
export JULIA_GC_ALLOC_OTHER=262144
```

### Performance Tuning

#### 1. Julia Optimization

Start with optimizations:
```bash
julia -O3 --project src/myAnalytics.jl
```

#### 2. Precompilation

Create a startup script that precompiles dependencies:

```julia
# warmup.jl
using Genie, HTTP, JSON, StateSpaceLearning

# Warm up the compiler
include("src/api/getssl.jl")
result = getssl([100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 106.0, 107.0, 108.0, 109.0, 110.0])
```

#### 3. Resource Limits

Set appropriate limits in systemd:

```ini
[Service]
LimitNOFILE=65536
LimitNPROC=4096
MemoryLimit=4G
```

## Monitoring

### Health Check Endpoint

Add to `src/myAnalytics.jl`:

```julia
route("/health") do
    json(Dict(
        :status => "ok",
        :timestamp => now(),
        :version => "1.0.0"
    ))
end
```

### Prometheus Metrics

For monitoring with Prometheus, add metrics endpoint:

```julia
using Dates

# Simple metrics
global request_count = 0
global error_count = 0

route("/metrics") do
    """
    # HELP api_requests_total Total API requests
    # TYPE api_requests_total counter
    api_requests_total $request_count

    # HELP api_errors_total Total API errors
    # TYPE api_errors_total counter
    api_errors_total $error_count
    """
end
```

### Log Monitoring

Use `journalctl` or log aggregation tools:

```bash
# Watch for errors
sudo journalctl -u myanalytics | grep ERROR

# Monitor access patterns
sudo journalctl -u myanalytics | grep "POST /api/getssl"
```

## Security Considerations

### 1. Authentication

Add authentication middleware:

```julia
# Simple API key authentication
function authenticate(request)
    api_key = get(request.headers, "X-API-Key", "")
    if api_key != ENV["API_KEY"]
        throw(AuthenticationError("Invalid API key"))
    end
end
```

### 2. Rate Limiting

Implement rate limiting:

```julia
using DataStructures

# Simple rate limiter
const rate_limiter = DefaultDict{String, Vector{DateTime}}(() -> DateTime[])

function check_rate_limit(ip, max_requests=10, window=60)
    now_time = now()
    cutoff = now_time - Second(window)
    
    # Clean old requests
    filter!(t -> t > cutoff, rate_limiter[ip])
    
    # Check limit
    if length(rate_limiter[ip]) >= max_requests
        throw(RateLimitError("Too many requests"))
    end
    
    push!(rate_limiter[ip], now_time)
end
```

### 3. CORS Configuration

Add CORS headers if needed:

```julia
# CORS middleware
function add_cors_headers()
    Genie.Responses.setheaders(Dict(
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type"
    ))
end
```

### 4. Input Validation

Always validate input sizes:

```julia
const MAX_ARRAY_SIZE = 10000

function validate_input(prices)
    if length(prices) > MAX_ARRAY_SIZE
        throw(ValidationError("Too many data points. Maximum: $MAX_ARRAY_SIZE"))
    end
end
```

## Backup and Recovery

### Backup Strategy

1. **Code**: Use Git for version control
2. **Configuration**: Store environment variables securely
3. **Logs**: Rotate and archive logs regularly

### Log Rotation

Configure with logrotate (`/etc/logrotate.d/myanalytics`):

```
/var/log/myanalytics/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 youruser youruser
}
```

## Scaling

### Horizontal Scaling

Deploy multiple instances behind a load balancer:

```nginx
upstream myanalytics_cluster {
    least_conn;
    server 10.0.1.10:8001;
    server 10.0.1.11:8001;
    server 10.0.1.12:8001;
}
```

### Load Balancer Health Checks

```nginx
upstream myanalytics_cluster {
    server 10.0.1.10:8001 max_fails=3 fail_timeout=30s;
    server 10.0.1.11:8001 max_fails=3 fail_timeout=30s;
    
    # Health check
    check interval=5000 rise=2 fall=3 timeout=1000;
}
```

## Troubleshooting

### High Memory Usage

```bash
# Check Julia process
ps aux | grep julia

# Monitor in real-time
top -p $(pgrep julia)
```

### Slow Responses

1. Check server load
2. Review Julia GC settings
3. Profile the getssl function
4. Consider caching results

### Service Won't Start

```bash
# Check syntax
julia --project -e 'include("src/myAnalytics.jl")'

# Check dependencies
julia --project -e 'using Pkg; Pkg.status()'

# Check logs
sudo journalctl -u myanalytics -n 50
```

## Deployment Checklist

Before deploying to production:

- [ ] All tests pass
- [ ] Dependencies are up to date
- [ ] Environment variables are configured
- [ ] SSL/TLS certificates are valid
- [ ] Monitoring is set up
- [ ] Backups are configured
- [ ] Log rotation is enabled
- [ ] Health checks are working
- [ ] Documentation is current
- [ ] Security measures are in place

## Maintenance

### Regular Tasks

**Daily:**
- Monitor logs for errors
- Check service status
- Review error rates

**Weekly:**
- Update dependencies
- Review performance metrics
- Check disk space

**Monthly:**
- Security updates
- Performance optimization
- Backup verification

### Updates

```bash
# Pull latest code
git pull

# Update dependencies
julia --project -e 'using Pkg; Pkg.update()'

# Restart service
sudo systemctl restart myanalytics
```

## Support

For production support:
- Monitor GitHub issues
- Check service status regularly
- Keep documentation updated
- Maintain communication channels

