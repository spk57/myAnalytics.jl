#!/usr/bin/env julia

"""
Startup script for myAnalytics API server

Usage:
    julia start_server.jl                   # Start with defaults (0.0.0.0:8080)
    julia start_server.jl 8080              # Custom port
    julia start_server.jl 8443 ssl          # With SSL (uses ssl/cert.pem and ssl/key.pem)
"""

using myAnalytics
using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "port"
            help = "Port to listen on"
            arg_type = Int
            default = 8080
        "--host"
            help = "Host to bind to"
            arg_type = String
            default = "0.0.0.0"
        "--ssl"
            help = "Enable SSL/HTTPS"
            action = :store_true
        "--cert"
            help = "Path to SSL certificate file"
            arg_type = String
            default = "ssl/cert.pem"
        "--key"
            help = "Path to SSL key file"
            arg_type = String
            default = "ssl/key.pem"
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()
    
    port = args["port"]
    host = args["host"]
    ssl_enabled = args["ssl"]
    cert_path = args["cert"]
    key_path = args["key"]
    
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

