const LOCATION = "42.3876,-71.0995" # Update with desired lat/long
@info "Preparing to display weather on the flipdots board and date on the flipdigits board" LOCATION

# Display weather on the flipdots board!
@info "Setting up environment..."
using Pkg
Pkg.resolve()
Pkg.instantiate()

@info "Loading dependencies..."
include("weather-app.jl")
using .WeatherApp
using FlipBoard

# Set up flipboard serial communication
# For this app, we're communicating with two boards: one flipdots (for weather) 
# and one flipdigits (for date). If only one is present, the script will still run 
@info "Setting up serial port for flip boards..."
shared_srl = missing
try 
    shared_srl = open_srl(; portname="/dev/ttyS0", baudrate=57600) 
catch
    @warn "No serial port found; ensure board is connected and/or portname is correct"
end

dots_sink = AlphaZetaSrl(; address=0x00, srl=shared_srl)
digits_sink = AlphaZetaSrl(; address=0x01, srl=shared_srl)

# ...update every half hour until we cancel the script
# update_with_current_weather(; scroll_long_msg=true, location=DEFAULT_LOCATION)
# update_with_current_date()
update_every_half_hour(; location=DEFAULT_LOCATION)

