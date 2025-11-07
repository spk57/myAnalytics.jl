#!/usr/bin/env julia

"""
Startup script for myAnalytics API server

Usage:
    julia start_server.jl                       # Start with defaults (0.0.0.0:8080)
    julia start_server.jl 8080                  # Custom port
    julia start_server.jl 8080 0.0.0.0          # Custom port and host
    julia start_server.jl 8443 0.0.0.0 ssl      # With SSL
"""

# Change to project directory
cd(@__DIR__)

# Activate the project environment
using Pkg
Pkg.activate(".")

# Load the module
using myAnalytics

function main()
    # Parse command line arguments
    port = 8080
    host = "0.0.0.0"
    ssl_enabled = false
    cert_path = "ssl/cert.pem"
    key_path = "ssl/key.pem"
    
    # Parse arguments
    if length(ARGS) >= 1
        port = parse(Int, ARGS[1])
    end
    
    if length(ARGS) >= 2
        # Check if second arg is "ssl" or a host
        if ARGS[2] == "ssl"
            ssl_enabled = true
        else
            host = ARGS[2]
        end
    end
    
    if length(ARGS) >= 3
        if ARGS[3] == "ssl"
            ssl_enabled = true
        end
    end
    
    # Start the API server
    if ssl_enabled
        println("Starting server with SSL...")
        start_analytics_api(
            host=host,
            port=port,
            ssl=true,
            ssl_cert=cert_path,
            ssl_key=key_path
        )
    else
        println("Starting server without SSL...")
        start_analytics_api(host=host, port=port)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

