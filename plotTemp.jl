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
    
    # Filter for temperature entries (value column may be string or number)
    temp_df = filter(row -> row.name == "temperature", df)
    
    if nrow(temp_df) == 0
        error("Error: No temperature entries found in $LOG_FILE")
    end
    
    println("Temperature entries found: $(nrow(temp_df))")
    
    # Extract datetime and temperature values
    # Convert value column to Float64 (handles both string and numeric types)
    temperatures = Float64[]
    datetimes = DateTime[]
    skipped = 0
    
    for (idx, row) in enumerate(eachrow(temp_df))
        try
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
            push!(temperatures, temp_val)
            push!(datetimes, row.datetime)
        catch e
            skipped += 1
            println(stderr, "Warning: Skipping row $idx: could not convert value '$(row.value)' to Float64: $e")
        end
    end
    
    if length(temperatures) == 0
        error("Error: No valid temperature values could be converted to Float64")
    end
    
    if skipped > 0
        println("Warning: Skipped $skipped invalid temperature value(s)")
    end
    
    println("Successfully converted $(length(temperatures)) temperature values")
    
    # Filter out noisy data: remove entries where temperature is 0.0 or > 150, or datetime before 2026
    original_count = length(temperatures)
    filtered_temperatures = Float64[]
    filtered_datetimes = DateTime[]
    min_datetime = DateTime(2026, 1, 1)
    
    for (idx, temp) in enumerate(temperatures)
        dt = datetimes[idx]
        # Keep entries where: temperature is valid AND datetime is >= 2026-01-01
        if temp != 0.0 && temp <= 150.0 && dt >= min_datetime
            push!(filtered_temperatures, temp)
            push!(filtered_datetimes, dt)
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
    p = plot!(p, xformatter=x -> Dates.format(DateTime(x), "dd\nHH:MM"))
    
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
