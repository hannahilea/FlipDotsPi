# Display weather on the flipdots board!
using Pkg
Pkg.resolve()
Pkg.instantiate()

using FlipBoard
using HTTP
using JSON

# Set up board
# Board-specific setup
# Hacky check to see if we're on the pi, to prevent trying to connect to port that
# isn't set up from laptop. For other systems, update `shared_srl` to point to
# the relevant serial port!
shared_srl = Sys.islinux() ? open_srl(; portname="/dev/ttyS0", baudrate=57600) : IOBuffer()

dots_sink = AlphaZetaSrl(; address=0x00, srl=shared_srl)

# Icons!
#TODO: move to fonts
const SNOW = map(FlipBoard.seg_to_bits,
                 [[3, 5], [4], [1, 3, 4, 5, 7], [2, 3, 5, 6], [1, 3, 4, 5, 7], [4], [3, 5]])
const SUN = map(FlipBoard.seg_to_bits,
                [[4], [2, 4, 6], [3, 4, 5], [1, 2, 3, 5, 6, 7], [3, 4, 5], [2, 4, 6], [4]])
const RAIN = map(FlipBoard.seg_to_bits,
                 [[2], [1, 2, 3, 5, 7], [1, 2, 3], [1, 2, 3, 5, 7], [1, 2, 3],
                  [1, 2, 3, 5, 7], [2]])
const NIGHT = map(FlipBoard.seg_to_bits,
                  [[3, 4, 5], [2, 6], [1, 7], [1, 3, 4, 5, 7], [1, 2, 6, 7], [2, 6]])
const CLOUD = map(FlipBoard.seg_to_bits,
                  [[5, 6], [3, 4, 6], [2, 6], [3, 6], [4, 6], [4, 6], [5, 6]])

# Set up weather; default loc_str is Somerville, MA
function get_weather(; location="42.3876,-71.0995", verbose=false)
    try
        verbose && (@info "https://api.weather.gov/points/$location")
        data = JSON.parse(String(HTTP.request("GET",
                                              "https://api.weather.gov/points/$location").body))

        # Normally would use JSON to parse this...but for pi, really don't want
        # all of those dependencies. So! Doing it the stupid brittle way here :)
        forecast_url = data["properties"]["forecast"]
        hourly_url = data["properties"]["forecastHourly"]
        verbose && (@info "Location urls: " forecast_url hourly_url)

        forecast_result = JSON.parse(String(HTTP.request("GET", forecast_url).body))
        hourly_result = JSON.parse(String(HTTP.request("GET", hourly_url).body))
        return forecast_result, hourly_result
    catch e
        @warn "Uh oh unable to get weather" e
        return missing
    end
end

function _get_weather_icon_from_hourly(current_hourly)
    # Check for rest of day through midnight
    # (_after_ midnight, is for next day)
    i = findfirst(c -> contains(c["startTime"], "T00"), current_hourly)
    weather_str = lowercase(join(map(c -> c["shortForecast"], current_hourly[1:i]), " "))

    # Precedence: will there be precipitation today?
    contains(weather_str, "snow") && return SNOW
    contains(weather_str, "rain") && return RAIN

    # If not, what is it like right now?
    if first(current_hourly)["isDaytime"]
        return contains(lowercase(first(current_hourly)["shortForecast"]), "sun") ? SUN : CLOUD
    end
    return NIGHT
end

# Return short form, long form
format_weather(::Any) = ("N/A", "Unable to fetch weather")

function format_weather(forecast, hourly_forecast)
    current = forecast["properties"]["periods"]
    current_hourly = hourly_forecast["properties"]["periods"]

    weather_icon = _get_weather_icon_from_hourly(current_hourly)
    short_str = vcat(text_to_dots_bytes(string("   ", first(current_hourly)["temperature"], "°")),
                                         weather_icon)
    long_str = string("Now: ", first(current_hourly)["temperature"], "° ",
                      first(current)["shortForecast"], "! ", current[2]["name"], ": ",
                      current[2]["shortForecast"], "!")
    return short_str, text_to_dots_bytes(long_str)
end

function update_with_current_weather(; scroll_long_msg=true)
    # Get weather
    bytes_static, bytes_scroll = format_weather(get_weather()...)

    # Display it!
    scroll_long_msg && scroll_bytes(dots_sink, bytes_scroll; loopcount=1)
    display_bytes(dots_sink, bytes_static)
    return nothing
end


if isinteractive()
    update_with_current_weather()
else
    # When running as script (not from REPL)...
    # ...update every hour until we tell it to stop
    update_pause_sec = 60 * 60
    scroll_long_msg = true
    while true
        update_with_current_weather(; scroll_long_msg)
        scroll_long_msg = false # Only scroll the first time
        sleep(update_pause_sec)
    end
    display_bytes(text_to_dots_bytes("Huzzah!"))
end