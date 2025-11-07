module myAnalytics

using Oxygen

# Include API modules
include("api/utils.jl")
include("api/middleware.jl")
include("api/server.jl")

# Re-export key functions
using .AnalyticsServer: start_server, stop_server
using .AnalyticsUtils: Response, ErrorResponse, validate_metric_name
using .AnalyticsMiddleware

export start_server, stop_server, Response, ErrorResponse, validate_metric_name,
       greet, start_analytics_api

"""
    greet()

Welcome message for myAnalytics.
"""
greet() = println("Welcome to myAnalytics.jl!")

"""
    start_analytics_api(; host="0.0.0.0", port=8080, ssl=false, ssl_cert="", ssl_key="")

Start the myAnalytics API server with optional SSL support.

# Examples
```julia
using myAnalytics

# Start with default settings
start_analytics_api()

# Start with custom host and port
start_analytics_api(host="127.0.0.1", port=3000)

# Start with SSL
start_analytics_api(
    host="0.0.0.0",
    port=8443,
    ssl=true,
    ssl_cert="ssl/cert.pem",
    ssl_key="ssl/key.pem"
)
```
"""
function start_analytics_api(; host="0.0.0.0", port=8080, ssl=false, ssl_cert="", ssl_key="")
    greet()
    AnalyticsServer.start_server(host=host, port=port, ssl=ssl, ssl_cert=ssl_cert, ssl_key=ssl_key)
end

end # module myAnalytics
