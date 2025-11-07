"""
    middleware

Middleware functions for request/response handling
"""

module AnalyticsMiddleware

using Oxygen
using JSON
using Dates
using HTTP

export add_cors_headers, validate_json, rate_limit, authenticate_request

"""
    add_cors_headers()

Add CORS headers to enable cross-origin requests.
"""
function add_cors_headers(handler)
    return function(request)
        response = handler(request)
        
        # Add CORS headers
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        
        return response
    end
end

"""
    validate_json()

Validate that request body is valid JSON for POST/PUT requests.
"""
function validate_json(handler)
    return function(request)
        if request.method in ["POST", "PUT", "PATCH"]
            try
                if !isempty(request.body)
                    JSON.parse(request.body)
                end
            catch e
                return HTTP.Response(400, JSON.json(Dict(
                    :status => 400,
                    :error => "Invalid JSON in request body",
                    :details => string(e)
                )))
            end
        end
        
        return handler(request)
    end
end

"""
    rate_limit(max_requests::Int=100, window::Int=60)

Basic rate limiting middleware (per-IP).
"""
function rate_limit(max_requests::Int=100, window::Int=60)
    # In-memory store for rate limiting (in production, use Redis)
    request_counts = Dict{String, Vector{Float64}}()
    
    return function(handler)
        return function(request)
            client_ip = get(request.headers, "X-Forwarded-For", get(request.headers, "X-Real-IP", "unknown"))
            
            now_time = time()
            
            # Initialize or retrieve request times for this IP
            if !haskey(request_counts, client_ip)
                request_counts[client_ip] = []
            end
            
            # Remove old requests outside the window
            filter!(t -> now_time - t < window, request_counts[client_ip])
            
            # Check if limit exceeded
            if length(request_counts[client_ip]) >= max_requests
                return HTTP.Response(429, JSON.json(Dict(
                    :status => 429,
                    :error => "Rate limit exceeded",
                    :retry_after => window
                )))
            end
            
            # Add current request
            push!(request_counts[client_ip], now_time)
            
            response = handler(request)
            response.headers["X-RateLimit-Limit"] = string(max_requests)
            response.headers["X-RateLimit-Remaining"] = string(max_requests - length(request_counts[client_ip]))
            response.headers["X-RateLimit-Reset"] = string(ceil(Int, now_time + window))
            
            return response
        end
    end
end

"""
    authenticate_request(api_key::String)

Simple API key authentication middleware.
"""
function authenticate_request(required_api_key::String)
    return function(handler)
        return function(request)
            # Skip authentication for health and public endpoints
            public_paths = ["/health", "/api/version"]
            if any(startswith(request.target, path) for path in public_paths)
                return handler(request)
            end
            
            # Check for API key in header or query parameter
            api_key = get(request.headers, "X-API-Key", "")
            
            if isempty(api_key)
                # Try query parameter
                if contains(request.target, "api_key=")
                    parts = split(request.target, "api_key=")
                    if length(parts) > 1
                        api_key = split(parts[2], "&")[1]
                    end
                end
            end
            
            if isempty(api_key) || api_key != required_api_key
                return HTTP.Response(401, JSON.json(Dict(
                    :status => 401,
                    :error => "Unauthorized",
                    :message => "Valid API key required"
                )))
            end
            
            return handler(request)
        end
    end
end

"""
    logging_middleware()

Log all incoming requests and outgoing responses.
"""
function logging_middleware()
    return function(handler)
        return function(request)
            timestamp = Dates.now()
            method = request.method
            target = request.target
            
            println("📨 [$timestamp] $method $target")
            
            response = handler(request)
            
            status = response.status
            status_emoji = if status < 300
                "✅"
            elseif status < 400
                "↪️"
            elseif status < 500
                "⚠️"
            else
                "❌"
            end
            
            println("$status_emoji [$timestamp] $status - $method $target")
            
            return response
        end
    end
end

end # module AnalyticsMiddleware

