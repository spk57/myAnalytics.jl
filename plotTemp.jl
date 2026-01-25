#!/usr/bin/env julia
# plotTemp.jl - Plot temperature data from logger.csv
# Reads logger.csv, filters temperature entries, converts time to EST, and plots
#
# Required packages: CSV, DataFrames, Dates, Plots, Statistics
# Install with: julia --project -e 'using Pkg; Pkg.add(["Plots", "Statistics"])'

using CSV
using DataFrames
using Dates
using Statistics
using Plots

# Configuration
# CSV format: id, transaction, datetime, name, value, source, created_at
const LOG_FILE = "logger.csv"
const OUTPUT_FILE = "temperature_plot.png"

function main()
    # Check if log file exists
    if !isfile(LOG_FILE)
        error("Error: $LOG_FILE not found. Please ensure the file exists in the current directory.")
    end
    
    println("Reading data from $LOG_FILE...")
    
    # Read CSV file
    df = CSV.read(LOG_FILE, DataFrame)
    
    if nrow(df) == 0
        error("Error: $LOG_FILE is empty.")
    end
    
    println("Total entries: $(nrow(df))")
    println("CSV columns: $(join(names(df), ", "))")
    
    # Note: CSV format is: id, transaction, datetime, name, value, source, created_at
    
    # Filter for temperature entries (value column may be string or number)
    temp_df = filter(row -> row.name == "temperature", df)
    
    if nrow(temp_df) == 0
        error("Error: No temperature entries found in $LOG_FILE")
    end
    
    println("Temperature entries found: $(nrow(temp_df))")
    
    # Extract datetime and temperature values
    # Convert value column to Float64 (handles both string and numeric types)
    # Handle datetime parsing for RFC3339 format (e.g., "2025-01-15T10:30:00Z")
    temperatures = Float64[]
    datetimes = DateTime[]
    skipped = 0
    
    for (idx, row) in enumerate(eachrow(temp_df))
        try
            # Parse temperature value
            val = row.value
            temp_val = if val isa AbstractString
                # Parse string/AbstractString (e.g., String7) to Float64
                # Convert to String first, strip whitespace, then parse
                parse(Float64, strip(string(val)))
            elseif val isa Number
                # Convert numeric type to Float64
                Float64(val)
            else
                error("Value is not a string or number: $(typeof(val))")
            end
            
            # Parse datetime - handle both DateTime objects and strings
            # CSV format uses RFC3339 (e.g., "2025-01-15T10:30:00Z" or "2026-01-21T16:34:45Z")
            # The 'Z' suffix indicates UTC time, but Julia's DateTime doesn't store timezone
            dt = row.created_at
            
            if dt isa DateTime
                # Already parsed as DateTime by CSV.jl
                # CSV.jl should handle RFC3339 format automatically
                parsed_dt = dt
            elseif dt isa AbstractString
                # Parse RFC3339 format string
                dt_str = strip(string(dt))
                
                # Remove 'Z' or 'z' suffix if present (indicates UTC, but we'll treat as naive datetime)
                if endswith(dt_str, 'Z') || endswith(dt_str, 'z')
                    dt_str = dt_str[1:end-1]
                end
                
                # Parse the datetime string - try multiple formats
                parsed_dt = try
                    # Try ISO8601 format first (most common)
                    DateTime(dt_str, dateformat"yyyy-mm-ddTHH:MM:SS")
                catch
                    try
                        # Try with fractional seconds
                        DateTime(dt_str, dateformat"yyyy-mm-ddTHH:MM:SS.s")
                    catch
                        try
                            # Try with timezone offset (e.g., -05:00)
                            if occursin(r"[+-]\d{2}:\d{2}$", dt_str)
                                # Remove timezone offset for parsing
                                dt_str_no_tz = dt_str[1:end-6]
                                DateTime(dt_str_no_tz, dateformat"yyyy-mm-ddTHH:MM:SS")
                            else
                                # Fallback to automatic parsing
                                DateTime(dt_str)
                            end
                        catch
                            # Last resort: automatic parsing
                            DateTime(dt_str)
                        end
                    end
                end
            else
                error("Datetime is not a DateTime or string: $(typeof(dt))")
            end
            
            push!(temperatures, temp_val)
            push!(datetimes, parsed_dt)
        catch e
            skipped += 1
            println(stderr, "Warning: Skipping row $idx: could not process entry: $e")
            if hasfield(typeof(row), :value)
                println(stderr, "  Value: $(row.value), Datetime: $(row.datetime)")
            end
        end
    end
    
    if length(temperatures) == 0
        error("Error: No valid temperature values could be converted to Float64")
    end
    
    if skipped > 0
        println("Warning: Skipped $skipped invalid temperature value(s)")
    end
    
    println("Successfully converted $(length(temperatures)) temperature values")
    
    # Debug: Show datetime range before filtering
    if length(datetimes) > 0
        println("Datetime range: $(minimum(datetimes)) to $(maximum(datetimes))")
    end
    
    # Filter out noisy data: remove entries where temperature is 0.0 or > 150
    # Note: Removed datetime filter - include all valid temperature entries regardless of date
    original_count = length(temperatures)
    filtered_temperatures = Float64[]
    filtered_datetimes = DateTime[]
    
    for (idx, temp) in enumerate(temperatures)
        dt = datetimes[idx]
        # Keep entries where: temperature is valid (not 0.0 and <= 150.0)
        if temp != 0.0 && temp <= 150.0 && dt >= DateTime(2025, 1, 1)
            push!(filtered_temperatures, temp)
            push!(filtered_datetimes, dt)
        else
            println("Skipping entry $idx: temperature = $temp, datetime = $dt") 
        end
    end
    
    filtered_count = original_count - length(filtered_temperatures)
    if filtered_count > 0
        println("Filtered out $filtered_count data point(s) (temperature = 0.0 or > 150.0, or datetime before 2026)")
    end
    
    if length(filtered_temperatures) == 0
        error("Error: No valid temperature values remaining after filtering")
    end
    
    temperatures = filtered_temperatures
    datetimes = filtered_datetimes
    println("Using $(length(temperatures)) valid temperature values for plotting")
    
    # Convert to EST (Eastern Standard Time, UTC-5)
    # Assume datetimes in CSV are in UTC, convert to EST by subtracting 5 hours
    println("Converting to EST timezone (UTC-5)...")
    est_offset = Hour(-5)
    est_datetimes = [dt + est_offset for dt in datetimes]
    
    # Sort by datetime
    sort_indices = sortperm(est_datetimes)
    est_datetimes_sorted = est_datetimes[sort_indices]
    temperatures_sorted = temperatures[sort_indices]
    
    println("Time range: $(first(est_datetimes_sorted)) to $(last(est_datetimes_sorted)) (EST)")
    println("Temperature range: $(minimum(temperatures_sorted))°C to $(maximum(temperatures_sorted))°C")
    
    # Create the plot
    println("Creating plot...")
    p = plot(
        est_datetimes_sorted,
        temperatures_sorted,
        seriestype=:scatter,
        markersize=4,
        markerstrokewidth=1,
        linewidth=2,
        title="Temperature vs Time (EST)",
        xlabel="Time (EST = UTC-5)",
        ylabel="Temperature (°C)",
        legend=false,
        grid=true,
        size=(1200, 600),
        dpi=150
    )
    
    # Format x-axis dates
    #p = plot!(p, xformatter=x -> Dates.format(DateTime(x), "dd\nHH:MM"))
    
    # Save the plot
    println("Saving plot to $OUTPUT_FILE...")
    savefig(p, OUTPUT_FILE)
    println("Plot saved successfully to $OUTPUT_FILE")
    
    # Display summary statistics
    println("\nSummary Statistics:")
    println("  Minimum temperature: $(minimum(temperatures_sorted))°F")
    println("  Maximum temperature: $(maximum(temperatures_sorted))°F")
    println("  Mean temperature: $(round(mean(temperatures_sorted), digits=2))°F")
    println("  Std deviation: $(round(std(temperatures_sorted), digits=2))°F")
end

# Run the script
if abspath(PROGRAM_FILE) == @__FILE__
    try
        main()
    catch e
        println(stderr, "Error: ", e)
        exit(1)
    end
end
