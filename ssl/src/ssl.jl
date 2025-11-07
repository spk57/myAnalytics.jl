module ssl

using StateSpaceLearning
using Statistics

# Export functions you want to be available when someone does: using ssl
export hello, run_ssl_model

function hello()
    println("Hello from ssl module!")
end

function run_ssl_model()
    println("Running StateSpaceLearning model...")
    # Add your actual SSL model code here
end

end # module

