using DataFrames
using Dates
using Plots

include("plotTemp.jl")
plot_data=main(last_24_hours=true)
study=plot_data["study"]
df=DataFrame([study[1], study[2]], :auto)

# Filter for times after 9pm EST 
df_after_9pm = filter(row -> Time(row.x1) >= Time(21, 0, 0), df)

# Extract just the time component for plotting
times = Time.(df_after_9pm.x1)
time_strings = Dates.format.(times, "HH:MM")
p = plot(time_strings, df_after_9pm.x2)
#p=plot(times, df_after_9pm.x2, xformatter=t -> Dates.format(Time(Nanosecond(Int64(t))), "HH:MM"))
savefig(p, "PlotTemp2.png")
