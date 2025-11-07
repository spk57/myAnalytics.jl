"""
    AnalyticsServer

Main server module for the myAnalytics API using Oxygen.jl
"""

module AnalyticsServer

using Oxygen
using JSON
using Dates
using HTTP

export start_server, stop_server

# Server configuration
const SERVER_CONFIG = Dict(
    :host => "0.0.0.0",
    :port => 8080,
    :ssl => false,
    :ssl_cert => "",
    :ssl_key => ""
)

"""
    start_server(; host="0.0.0.0", port=8080, ssl=false, ssl_cert="", ssl_key="")

Start the analytics API server with specified configuration.

# Arguments
- `host::String`: Host to bind to (default: "0.0.0.0")
- `port::Int`: Port to listen on (default: 8080)
- `ssl::Bool`: Enable SSL/HTTPS (default: false)
- `ssl_cert::String`: Path to SSL certificate file
- `ssl_key::String`: Path to SSL key file
"""
function start_server(; host="0.0.0.0", port=8080, ssl=false, ssl_cert="", ssl_key="")
    # Update configuration
    SERVER_CONFIG[:host] = host
    SERVER_CONFIG[:port] = port
    SERVER_CONFIG[:ssl] = ssl
    SERVER_CONFIG[:ssl_cert] = ssl_cert
    SERVER_CONFIG[:ssl_key] = ssl_key

    println("=" ^ 60)
    println("🚀 Starting myAnalytics API Server")
    println("=" ^ 60)
    println("Host: $(SERVER_CONFIG[:host])")
    println("Port: $(SERVER_CONFIG[:port])")
    println("SSL: $(SERVER_CONFIG[:ssl])")
    println("=" ^ 60)

    # Routes are registered in the main module before this function is called

    # Start the server
    if ssl && !isempty(ssl_cert) && !isempty(ssl_key)
        serve(host=host, port=port, ssl_cert=ssl_cert, ssl_key=ssl_key)
    else
        serve(host=host, port=port)
    end
end

"""
    stop_server()

Stop the analytics API server gracefully.
"""
function stop_server()
    println("\n🛑 Stopping myAnalytics API Server")
    # Oxygen.jl handles this through SIGINT/SIGTERM
end

"""
    create_response(status::Int, data::Any; message::String="")

Create a standardized JSON response.
"""
function create_response(status::Int, data::Any; message::String="")
    response = Dict(
        :status => status,
        :timestamp => Dates.now(),
        :data => data
    )
    
    if !isempty(message)
        response[:message] = message
    end
    
    return response
end

"""
    create_error_response(status::Int, error::String; details::String="")

Create a standardized error JSON response.
"""
function create_error_response(status::Int, error::String; details::String="")
    response = Dict(
        :status => status,
        :timestamp => Dates.now(),
        :error => error
    )
    
    if !isempty(details)
        response[:details] = details
    end
    
    return response
end

end # module AnalyticsServer

