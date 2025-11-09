"""
    routes

API routes for the myAnalytics analytics service
This file should be included in the main myAnalytics module where Oxygen is already loaded.
"""

# Health check endpoint
@get "/health" function()
    return Dict(
        :status => "healthy",
        :timestamp => Dates.now(),
        :service => "myAnalytics"
    )
end

# Version endpoint
@get "/api/version" function()
    return Dict(
        :version => "0.1.0",
        :name => "myAnalytics",
        :api_version => "1.0"
    )
end

# Basic analytics endpoint - GET metrics by name
@get "/api/metrics/:metric_name" function(metric_name::String)
    # Example implementation - replace with your actual analytics logic
    data = Dict(
        :metric => metric_name,
        :value => rand() * 100,
        :timestamp => Dates.now(),
        :unit => "units"
    )
    
    return Dict(
        :status => 200,
        :data => data,
        :message => "Metric retrieved successfully"
    )
end

# Metrics endpoint - POST query for analytics
@post "/api/metrics/query" function(req)
    try
        # Parse request body
        body_str = String(req.body)
        body = isempty(body_str) ? Dict() : JSON.parse(body_str; dicttype=Dict{Symbol, Any})
        
        # Validate request
        if !haskey(body, :metric)
            return Dict(
                :status => 400,
                :error => "Missing required field: metric",
                :timestamp => Dates.now()
            )
        end
        
        metric_name = body[:metric]
        filters = get(body, :filters, Dict())
        
        # Your analytics query logic here
        result = Dict(
            :metric => metric_name,
            :filters => filters,
            :result => rand() * 100,
            :timestamp => Dates.now()
        )
        
        return Dict(
            :status => 200,
            :data => result,
            :message => "Query executed successfully"
        )
    catch e
        return Dict(
            :status => 500,
            :error => "Internal server error",
            :details => string(e),
            :timestamp => Dates.now()
        )
    end
end

# Analytics summary endpoint
@get "/api/analytics/summary" function()
    summary = Dict(
        :total_metrics => 42,
        :active_users => 128,
        :data_points => 15324,
        :last_update => Dates.now(),
        :status => "operational"
    )
    
    return Dict(
        :status => 200,
        :data => summary
    )
end

# Analytics time-series endpoint
@get "/api/analytics/timeseries/:metric" function(metric::String)
    # Generate sample time-series data
    timestamps = [Dates.now() - Dates.Hour(i) for i in 0:23]
    values = rand(24) .* 100
    
    data = Dict(
        :metric => metric,
        :timestamps => timestamps,
        :values => values,
        :period => "24h"
    )
    
    return Dict(
        :status => 200,
        :data => data
    )
end

# Analytics aggregation endpoint
@post "/api/analytics/aggregate" function(req)
    try
        # Parse request body
        body_str = String(req.body)
        body = isempty(body_str) ? Dict() : JSON.parse(body_str; dicttype=Dict{Symbol, Any})
        
        agg_type = get(body, :type, "sum")  # sum, avg, min, max, count
        metrics = get(body, :metrics, [])
        
        if isempty(metrics)
            return Dict(
                :status => 400,
                :error => "At least one metric is required"
            )
        end
        
        aggregated = Dict(
            :type => agg_type,
            :metrics => metrics,
            :result => rand() * 1000,
            :timestamp => Dates.now()
        )
        
        return Dict(
            :status => 200,
            :data => aggregated
        )
    catch e
        return Dict(
            :status => 500,
            :error => "Aggregation failed",
            :details => string(e)
        )
    end
end

# List all available metrics
@get "/api/metrics/list" function()
    # Return list of available metrics
    metrics = [
        Dict(:name => "cpu_usage", :type => "gauge", :unit => "%"),
        Dict(:name => "memory_usage", :type => "gauge", :unit => "MB"),
        Dict(:name => "requests_total", :type => "counter", :unit => "count"),
        Dict(:name => "request_duration", :type => "histogram", :unit => "ms"),
        Dict(:name => "errors_total", :type => "counter", :unit => "count")
    ]
    
    return Dict(
        :status => 200,
        :data => metrics,
        :count => length(metrics)
    )
end

# SSL (Structural State Space Learning) Analysis endpoint
# Performs time series analysis on price data using structural models
@post "/api/analytics/ssl" function(req)
    try
        # Parse request body
        body_str = String(req.body)
        body = isempty(body_str) ? Dict() : JSON.parse(body_str; dicttype=Dict{Symbol, Any})
        
        # Validate request - require prices array
        if !haskey(body, :prices)
            return Dict(
                :status => 400,
                :error => "Missing required field: prices",
                :message => "Please provide a 'prices' array in the request body",
                :timestamp => Dates.now()
            )
        end
        
        prices = body[:prices]
        
        # Validate prices is an array
        if !isa(prices, Vector) && !isa(prices, Array)
            return Dict(
                :status => 400,
                :error => "Invalid data type",
                :message => "'prices' must be an array of numbers",
                :timestamp => Dates.now()
            )
        end
        
        # Convert to Vector{Float64} if needed
        try
            prices_vec = convert(Vector{Float64}, prices)
        catch e
            return Dict(
                :status => 400,
                :error => "Invalid price values",
                :message => "All prices must be numeric values",
                :details => string(e),
                :timestamp => Dates.now()
            )
        end
        
        # Call getssl function
        result = getssl(prices_vec)
        
        # Format response to match API standard
        if get(result, :success, false)
            return Dict(
                :status => 200,
                :data => result,
                :message => get(result, :message, "SSL analysis completed successfully"),
                :timestamp => Dates.now()
            )
        else
            return Dict(
                :status => 500,
                :error => "SSL analysis failed",
                :message => get(result, :message, "Unknown error occurred"),
                :timestamp => Dates.now()
            )
        end
        
    catch e
        return Dict(
            :status => 500,
            :error => "Internal server error",
            :message => "An error occurred while processing the SSL analysis request",
            :details => string(e),
            :timestamp => Dates.now()
        )
    end
end

# 404 handler - catch-all for undefined routes
# Note: This will only catch GET requests. For other methods, Oxygen will return default 404
@get "/:path..." function(path)
    return Dict(
        :status => 404,
        :error => "Endpoint not found",
        :path => path,
        :available_endpoints => [
            "/health",
            "/api/version",
            "/api/metrics/:metric_name",
            "/api/metrics/query (POST)",
            "/api/metrics/list",
            "/api/analytics/summary",
            "/api/analytics/timeseries/:metric",
            "/api/analytics/aggregate (POST)",
            "/api/analytics/ssl (POST)"
        ]
    )
end

