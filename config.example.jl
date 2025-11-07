# myAnalytics API Configuration Example
# Copy this file to config.jl and modify as needed

# Server Configuration
const SERVER_HOST = "0.0.0.0"
const SERVER_PORT = 8080

# SSL/TLS Configuration
const ENABLE_SSL = false
const SSL_CERT_PATH = "ssl/cert.pem"
const SSL_KEY_PATH = "ssl/key.pem"

# API Configuration
const API_KEY = "your-secret-api-key-here"
const RATE_LIMIT_REQUESTS = 100
const RATE_LIMIT_WINDOW = 60  # seconds

# Logging
const LOG_FILE = "analytics.log"
const LOG_LEVEL = "info"  # debug, info, warn, error

# CORS Configuration
const CORS_ENABLED = true
const CORS_ORIGIN = "*"  # or specific domain like "https://example.com"

# Performance
const COMPRESSION_ENABLED = true
const CACHE_ENABLED = true
const CACHE_TTL = 300  # seconds

# Database Configuration (optional)
# const DB_HOST = "localhost"
# const DB_PORT = 5432
# const DB_NAME = "analytics"
# const DB_USER = "user"
# const DB_PASSWORD = "password"

# Request Configuration
const MAX_REQUEST_SIZE = 1024 * 1024  # 1MB in bytes
const REQUEST_TIMEOUT = 30  # seconds

# Features
const ENABLE_HEALTH_CHECK = true
const ENABLE_METRICS_ENDPOINT = true
const ENABLE_ANALYTICS_ENDPOINT = true

