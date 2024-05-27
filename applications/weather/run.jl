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
shared_srl = open_srl_iff_available(; portname="/dev/ttyS0", baudrate=57600)

dots_sink = AZDotsSink(; address=0x00, serial_port=shared_srl)
digits_sink = AZDigitsSink(; address=0x01, serial_port=shared_srl)

# ...update every half hour until we cancel the script
update_with_current_weather(dots_sink; scroll_long_msg=true, location=LOCATION)
update_with_current_date(digits_sink)
update_every_half_hour(dots_sink, digits_sink; location=LOCATION)
