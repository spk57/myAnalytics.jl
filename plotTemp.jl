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
# CSV format: id, transaction, datetime, name, value, source, location, created_at
const LOG_FILE = "logger.csv"
const OUTPUT_FILE = "temperature_plot.png"

function main(; last_24_hours::Bool=false)
    # Check if log file exists
    if !isfile(LOG_FILE)
        error("Error: $LOG_FILE not found. Please ensure the file exists in the current directory.")
    end
    
    if last_24_hours
        println("Filtering to last 24 hours of data...")
    end
    
    println("Reading data from $LOG_FILE...")
    
    # Read CSV file
    df = CSV.read(LOG_FILE, DataFrame)
    
    if DataFrames.nrow(df) == 0
        error("Error: $LOG_FILE is empty.")
    end
    
    println("Total entries: $(DataFrames.nrow(df))")
    println("CSV columns: $(join(names(df), ", "))")
    
    # Note: CSV format is: id, transaction, datetime, name, value, source, location, created_at
    
    # First, filter for only "logging" transactions to ensure consistent structure
    # This ensures we only process rows with the expected column structure
    logging_df = filter(row -> begin
        if !hasproperty(row, :transaction)
            return false
        end
        trans = row.transaction
        if ismissing(trans)
            return false
        end
        string(trans) == "logging"
    end, df)
    
    if DataFrames.nrow(logging_df) == 0
        error("Error: No 'logging' transaction entries found in $LOG_FILE")
    end
    
    println("Logging transaction entries: $(DataFrames.nrow(logging_df))")
    
    # Note: We don't strictly check for location column here because:
    # 1. The location extraction code handles missing columns gracefully
    # 2. Some CSV files might have location as an optional column
    # 3. Empty location values will be handled as "Unspecified"
    
    # Filter for temperature entries (value column may be string or number)
    temp_df = filter(row -> row.name == "temperature", logging_df)
    
    if DataFrames.nrow(temp_df) == 0
        error("Error: No temperature entries found in $LOG_FILE")
    end
    
    println("Temperature entries found: $(DataFrames.nrow(temp_df))")
    
    # Extract datetime, temperature values, and location
    # Convert value column to Float64 (handles both string and numeric types)
    # Group data by location
    location_data = Dict{String, Vector{Tuple{DateTime, Float64}}}()
    # Track source-to-location mapping for note annotations
    source_to_location = Dict{String, String}()
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
            
            dt = row.created_at
            
            if dt isa DateTime
                parsed_dt = dt
            elseif dt isa AbstractString
                # Parse datetime string (e.g., "2026-01-25T15:05:13-05:00")
                dt_str = strip(string(dt))
                
                # Remove timezone offset if present (e.g., -05:00 or +05:00)
                if occursin(r"[+-]\d{2}:\d{2}$", dt_str)
                    # Remove timezone offset for parsing
                    dt_str_no_tz = dt_str[1:end-6]
                    parsed_dt = try
                        DateTime(dt_str_no_tz, dateformat"yyyy-mm-ddTHH:MM:SS")
                    catch
                        try
                            # Try with fractional seconds
                            DateTime(dt_str_no_tz, dateformat"yyyy-mm-ddTHH:MM:SS.s")
                        catch
                            # Fallback to automatic parsing
                            DateTime(dt_str_no_tz)
                        end
                    end
                else
                    # No timezone offset, parse directly
                    parsed_dt = try
                        DateTime(dt_str, dateformat"yyyy-mm-ddTHH:MM:SS")
                    catch
                        try
                            # Try with fractional seconds
                            DateTime(dt_str, dateformat"yyyy-mm-ddTHH:MM:SS.s")
                        catch
                            # Fallback to automatic parsing
                            DateTime(dt_str)
                        end
                    end
                end
            else
                error("Datetime is not a DateTime or string: $(typeof(dt))")
            end
            
            # Get location - handle missing or empty values
            # Try to access location column, handling various cases
            location = try
                if hasproperty(row, :location)
                    loc_val = getproperty(row, :location)
                    if ismissing(loc_val)
                        "Unspecified"
                    else
                        loc_str = strip(string(loc_val))
                        isempty(loc_str) ? "Unspecified" : loc_str
                    end
                else
                    "Unspecified"
                end
            catch e
                # If location column doesn't exist or can't be accessed, use default
                "Unspecified"
            end
            
            # Track source-to-location mapping (use most recent mapping for each source)
            source = try
                if hasproperty(row, :source) && !ismissing(row.source)
                    string(row.source)
                else
                    ""
                end
            catch
                ""
            end
            
            if !isempty(source)
                source_to_location[source] = location
            end
            
            # Add to location-specific data
            if !haskey(location_data, location)
                location_data[location] = Vector{Tuple{DateTime, Float64}}()
            end
            push!(location_data[location], (parsed_dt, temp_val))
        catch e
            skipped += 1
            println(stderr, "Warning: Skipping row $idx: could not process entry: $e")
            if hasfield(typeof(row), :value)
                println(stderr, "  Value: $(row.value), Datetime: $(row.datetime)")
            end
        end
    end
    
    if isempty(location_data)
        error("Error: No valid temperature values could be converted to Float64")
    end
    
    if skipped > 0
        println("Warning: Skipped $skipped invalid temperature value(s)")
    end
    
    total_values = sum(length(v) for v in values(location_data))
    println("Successfully converted $total_values temperature values across $(length(location_data)) location(s)")
    
    # Filter out noisy data: remove entries where temperature is 0.0 or > 150
    # Note: Removed datetime filter - include all valid temperature entries regardless of date
    filtered_location_data = Dict{String, Vector{Tuple{DateTime, Float64}}}()
    original_count = 0
    filtered_count = 0
    
    for (location, data) in location_data
        original_count += length(data)
        filtered_data = Vector{Tuple{DateTime, Float64}}()
        
        for (dt, temp) in data
            # Keep entries where: temperature is valid (not 0.0 and <= 150.0)
            if temp != 0.0 && temp <= 150.0 && dt >= DateTime(2025, 1, 1)
                push!(filtered_data, (dt, temp))
            else
                filtered_count += 1
            end
        end
        
        if !isempty(filtered_data)
            filtered_location_data[location] = filtered_data
        end
    end
    
    if filtered_count > 0
        println("Filtered out $filtered_count data point(s) (temperature = 0.0 or > 150.0, or datetime before 2025)")
    end
    
    if isempty(filtered_location_data)
        error("Error: No valid temperature values remaining after filtering")
    end
    
    location_data = filtered_location_data
    println("Using $(sum(length(v) for v in values(location_data))) valid temperature values for plotting")
    
    # Calculate cutoff time for 24-hour filter if enabled (before processing notes)
    est_offset = Hour(-5)
    cutoff_time = if last_24_hours
        now() - Hour(24)  # 24 hours ago from current time
    else
        nothing
    end
    
    # Read note transactions for annotations
    println("Reading note transactions for annotations...")
    note_df = filter(row -> begin
        if !hasproperty(row, :transaction)
            return false
        end
        trans = row.transaction
        if ismissing(trans)
            return false
        end
        string(trans) == "note"
    end, df)
    
    # Parse note transactions
    #2929,note,2026-01-25T20:06:54Z,note,removed heater,arduino-r4-wifi-5ED2C4,,2026-01-25T15:06:54-05:00
    notes = Vector{Tuple{DateTime, String, String, String}}()  # (datetime, note_text, source, location)
    for row in eachrow(note_df)
        try
            # Parse datetime from created_at column to match temperature data timing
            # Temperature data uses created_at, so notes should too for proper alignment
            dt = row.created_at
            parsed_dt = if dt isa DateTime
                dt
            elseif dt isa AbstractString
                # Parse datetime string (e.g., "2026-01-25T20:06:54Z")
                dt_str = strip(string(dt))
                
                # Remove 'Z' or 'z' suffix if present (indicates UTC)
                if endswith(dt_str, 'Z') || endswith(dt_str, 'z')
                    dt_str = dt_str[1:end-1]
                end
                
                # Remove timezone offset if present (e.g., -05:00 or +05:00)
                if occursin(r"[+-]\d{2}:\d{2}$", dt_str)
                    # Remove timezone offset for parsing
                    dt_str_no_tz = dt_str[1:end-6]
                    parsed_dt = try
                        DateTime(dt_str_no_tz, dateformat"yyyy-mm-ddTHH:MM:SS")
                    catch
                        try
                            # Try with fractional seconds
                            DateTime(dt_str_no_tz, dateformat"yyyy-mm-ddTHH:MM:SS.s")
                        catch
                            # Fallback to automatic parsing
                            DateTime(dt_str_no_tz)
                        end
                    end
                else
                    # No timezone offset, parse directly
                    parsed_dt = try
                        DateTime(dt_str, dateformat"yyyy-mm-ddTHH:MM:SS")
                    catch
                        try
                            # Try with fractional seconds
                            DateTime(dt_str, dateformat"yyyy-mm-ddTHH:MM:SS.s")
                        catch
                            # Fallback to automatic parsing
                            DateTime(dt_str)
                        end
                    end
                end
                parsed_dt
            else
                println(stderr, "Warning: Note datetime is not DateTime or string: $(typeof(dt)), skipping")
                continue
            end
            
            # Get note text (value field)
            note_text = try
                if hasproperty(row, :value) && !ismissing(row.value)
                    string(row.value)
                else
                    continue
                end
            catch
                continue
            end
            
            # Get source
            source = try
                if hasproperty(row, :source) && !ismissing(row.source)
                    string(row.source)
                else
                    ""
                end
            catch
                ""
            end
            
            # Map source to location
            location = get(source_to_location, source, "Unspecified")
            
            push!(notes, (parsed_dt, note_text, source, location))
        catch e
            println(stderr, "Warning: Skipping note entry: $e")
        end
    end
    
    println("Found $(length(notes)) note(s) to annotate")
    
    # Filter notes to last 24 hours if enabled
    if last_24_hours && cutoff_time !== nothing
        notes = [(dt, text, src, loc) for (dt, text, src, loc) in notes 
                 if (dt) >= cutoff_time]
        println("Filtered to $(length(notes)) note(s) in last 24 hours")
    end
    
    if last_24_hours && cutoff_time !== nothing
        println("Filtering data to last 24 hours (from $(cutoff_time) to $(now()))")
    end
    
    # Prepare data for plotting - sort
    plot_data = Dict{String, Tuple{Vector{DateTime}, Vector{Float64}}}()
    all_temps = Float64[]
    
    for (location, data) in location_data
        est_datetimes = [dt for (dt, _) in data]
        temps = [temp for (_, temp) in data]
        
        # Apply 24-hour filter if enabled
        if last_24_hours && cutoff_time !== nothing
            filtered_indices = [i for i in 1:length(est_datetimes) if est_datetimes[i] >= cutoff_time]
            est_datetimes = est_datetimes[filtered_indices]
            temps = temps[filtered_indices]
        end
        
        if length(est_datetimes) == 0
            continue  # Skip locations with no data in the filtered range
        end
        
        # Sort by datetime
        sort_indices = sortperm(est_datetimes)
        est_datetimes_sorted = est_datetimes[sort_indices]
        temps_sorted = temps[sort_indices]
        
        plot_data[location] = (est_datetimes_sorted, temps_sorted)
        append!(all_temps, temps_sorted)
    end
    
    if isempty(plot_data)
        error("Error: No temperature data found in the specified time range")
    end
    
    # Find overall time and temperature ranges
    all_datetimes = vcat([v[1] for v in values(plot_data)]...)
    time_range = (minimum(all_datetimes), maximum(all_datetimes))
    temp_range = (minimum(all_temps), maximum(all_temps))
    
    println("Time range: $(time_range[1]) to $(time_range[2]) (EST)")
    println("Temperature range: $(temp_range[1])°C to $(temp_range[2])°C")
    
    # Create overlay plot with different series for each location
    println("Creating overlay plot...")
    
    # Get locations sorted for consistent ordering
    locations = sort(collect(keys(plot_data)))
    num_locations = length(locations)
    println("Plotting data for $num_locations location(s): $(join(locations, ", "))")
    
    # Create the plot with first location
    first_location = locations[1]
    first_datetimes, first_temps = plot_data[first_location]
    
    # Plots.jl will automatically assign distinct colors to each series
    p = plot(
        first_datetimes,
        first_temps,
        seriestype=:scatter,
        markersize=4,
        markerstrokewidth=1,
        linewidth=2,
        label=first_location,
        title="Temperature vs Time by Location (EST)",
        xlabel="Time (EST = UTC-5)",
        ylabel="Temperature (°C)",
        legend=:topright,
        grid=true,
        size=(1200, 600),
        dpi=150
    )
    
    # Add remaining locations as overlay plots
    # Each series will automatically get a different color
    for location in locations[2:end]
        datetimes, temps = plot_data[location]
        plot!(
            p,
            datetimes,
            temps,
            seriestype=:scatter,
            markersize=4,
            markerstrokewidth=1,
            linewidth=2,
            label=location
        )
    end
    
    # Add note annotations to the plot
    if length(notes) > 0
        println("Adding $(length(notes)) note annotation(s) to plot...")
        
        for (note_dt, note_text, note_source, note_location) in notes
            
            # Find the temperature value at this datetime for the note's location
            # If the location exists in plot_data, find the closest temperature point
            if  haskey(plot_data, note_location)
                datetimes, temps = plot_data[note_location]
                
                # Find the closest datetime point
                if length(datetimes) > 0
                    # Find index of closest datetime
                    time_diffs = [abs((dt - note_dt).value) for dt in datetimes]
                    closest_idx = argmin(time_diffs)
                    closest_dt = datetimes[closest_idx]
                    closest_temp = temps[closest_idx]
                    
                    # Add a marker at the annotation point
                    scatter!(
                        p,
                        [closest_dt],
                        [closest_temp],
                        markershape=:star5,
                        markersize=8,
                        markercolor=:red,
                        markerstrokewidth=2,
                        markerstrokecolor=:darkred,
                        label=""
                    )
                        
                    # Add text annotation
                    # Format: (x, y, text)
                    annotate!(
                        p,
                        [(closest_dt, closest_temp, text(note_text, 7, :darkred, :left, :top))]
                    )
                end
            else
                println(stderr, "Warning: No data found for note location: $note_location")
            end
        end
    end
    
    # Save the plot
    println("Saving plot to $OUTPUT_FILE...")
    savefig(p, OUTPUT_FILE)
    println("Plot saved successfully to $OUTPUT_FILE")
    
    # Display summary statistics for each location
    println("\nSummary Statistics by Location:")
    for location in locations
        datetimes, temps = plot_data[location]
        println("\n  $location:")
        println("    Data points: $(length(temps))")
        println("    Minimum temperature: $(minimum(temps))°C")
        println("    Maximum temperature: $(maximum(temps))°C")
        println("    Mean temperature: $(round(mean(temps), digits=2))°C")
        println("    Std deviation: $(round(std(temps), digits=2))°C")
        println("    Time range: $(minimum(datetimes)) to $(maximum(datetimes))")
    end
    
    # Overall statistics
    println("\n  Overall:")
    println("    Total data points: $(length(all_temps))")
    println("    Minimum temperature: $(minimum(all_temps))°C")
    println("    Maximum temperature: $(maximum(all_temps))°C")
    println("    Mean temperature: $(round(mean(all_temps), digits=2))°C")
    println("    Std deviation: $(round(std(all_temps), digits=2))°C")
    return plot_data
end

# Parse command-line arguments
function parse_args()
    last_24_hours = false
    
    for arg in ARGS
        if arg == "-d" || arg == "--last-24-hours"
            last_24_hours = true
        elseif arg == "-h" || arg == "--help"
            println("Usage: julia plotTemp.jl [OPTIONS]")
            println("")
            println("Options:")
            println("  -d, --last-24-hours    Filter data to last 24 hours")
            println("  -h, --help            Show this help message")
            exit(0)
        end
    end
    
    return last_24_hours
end

# Run the script
if abspath(PROGRAM_FILE) == @__FILE__
    try
        last_24_hours = parse_args()
        main(last_24_hours=last_24_hours)
    catch e
        println(stderr, "Error: ", e)
        exit(1)
    end
end
