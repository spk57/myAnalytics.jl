#getssl.jl is a function to get the structural model for a list of prices
using StateSpaceLearning
using Statistics

"Calculate the min and max of a vector of values and return a tuple of the min and max along with the index of the min and max"
function findminmax(v)
    min = findmin(v)
    max = findmax(v)
    rng=max[1]-min[1]
    return (min=min,max=max, rng=rng)
end
const minpoints=10 # minimum number of data points for analysis
function getssl(prices)
    try
        # Convert input to a Julia Vector{Float64} if it's not already
        prices_jl = convert(Vector{Float64}, prices)

        len=length(prices_jl)
        if len < minpoints
            result = Dict{Symbol,Any}(
                :success => false,
                :message => "Insufficient data points for analysis. Need at least $minpoints, got $(length(prices_jl))",
            )        
            return result
        end

        monthlyAnalysis=false
        # Create the model with explicit parameter names
        # The component parameters expect string values indicating the model type
        # only do monthly if more than 40 points (Month)
        if len <= 40
            freq_seasonal=[5]
        else
            monthlyAnalysis=true
            freq_seasonal=[5, 20]
        end
        model_sm = StructuralModel(
            prices_jl,  # Input data
            freq_seasonal=freq_seasonal,  # Weekly and monthly seasonality
        )
        
        # Fit the model
        StateSpaceLearning.fit!(model_sm)
        
        # Forecast
        steps_ahead = 20
        predicted = StateSpaceLearning.forecast(model_sm, steps_ahead)
        
        # Get fitted values and components
        fitted = model_sm.output.fitted
        
        # Calculate components
        components = Dict()
        
        # Level component
        if haskey(model_sm.output.components, "μ1") && haskey(model_sm.output.components, "ξ")
            components[:level] = model_sm.output.components["μ1"]["Values"] + 
                                 model_sm.output.components["ξ"]["Values"]
        end
        
        # Trend component (level + slope)
        if haskey(model_sm.output.components, "ν1") && haskey(model_sm.output.components, "ζ")
            components[:slope] = model_sm.output.components["ν1"]["Values"] + 
                                 model_sm.output.components["ζ"]["Values"]
            components[:trend] = get(components, :level, zeros(length(prices_jl))) .+ 
                                components[:slope]
        end
        
        # Seasonal components
        for (freq, name) in [(5, "week"), (20, "month")]
            gamma_key = "γ1_$freq"
            omega_key = "ω_$freq"
            if haskey(model_sm.output.components, gamma_key) && 
               haskey(model_sm.output.components, omega_key)
                components[Symbol("seasonal_$name")] = 
                    model_sm.output.components[gamma_key]["Values"] + 
                    model_sm.output.components[omega_key]["Values"]
            end
            if !monthlyAnalysis break end
        end
        seasonalWeek = model_sm.output.components["γ1_5"]["Values"] + model_sm.output.components["ω_5"]["Values"]
        minmaxweek=findminmax(seasonalWeek[1:5])
              
        # Calculate statistics
        stats = Dict()
        stats[:mean] = mean(prices_jl)
        stats[:std]  = std(prices_jl)
        stats[:max]  = maximum(prices_jl)
        stats[:min]  = minimum(prices_jl)
        stats[:swmax] = minmaxweek.rng
        stats[:swmaxd] = minmaxweek.max[2]
        stats[:swmind] = minmaxweek.min[2]
        if monthlyAnalysis
            seasonalMonth = model_sm.output.components["γ1_20"]["Values"] + model_sm.output.components["ω_20"]["Values"]
            minmaxmonth=findminmax(seasonalMonth[1:20])
            stats[:smmax]  = minmaxmonth.rng
            stats[:smmaxd] = minmaxmonth.max[2]
            stats[:smmind] = minmaxmonth.min[2]
        end
        stats[:return] = 100.0 * (prices_jl[end] - prices_jl[1]) / prices_jl[1]

        # Prepare the result with error checking
        result = Dict{Symbol,Any}(
            :success => true,
            :message => "Analysis completed successfully",
            :predicted => predicted,
            :fitted => fitted,
            :stats => stats
        )
        
        # Add components to result if they exist
        for (k, v) in components
            result[k] = v
        end
        
        return result
        
    catch e
        return Dict(
            :success => false,
            :message => "Error in analysis: $(sprint(showerror, e))"
        )
    end
end
