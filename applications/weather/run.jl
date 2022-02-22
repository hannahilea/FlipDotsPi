# Display weather on the flipdots board!
@info "Setting up environment..."
using Pkg
Pkg.resolve()
Pkg.instantiate()

@info "Loading dependencies..."
using FlipBoard

# Set up board
# Board-specific setup
# Hacky check to see if we're on the pi, to prevent trying to connect to port that
# isn't set up from laptop. For other systems, update `shared_srl` to point to
# the relevant serial port!
@info "Setting up serial port..."
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

# hacky JSON parser substitute
function _get_string_value(body, key; index=2)
    return first(split(split(body, "\"$key\": \"")[index], "\","))
end

function _get_int_value(body, key; index=2)
    return first(split(split(body, "\"$key\": ")[index], ","))
end

function _get_bool_value(body, key; index=2)
    return lowercase(first(split(split(body, "\"$key\": ")[index], ","))) == "true"
end

# Set up weather; default loc_str is Somerville, MA
function get_weather(; location="42.3876,-71.0995")
    try
        @debug "Getting weather..." "https://api.weather.gov/points/$location"
        @info "Fetching forecast links..."
        data = read(`curl "https://api.weather.gov/points/$location"`, String)

        # Normally would use JSON to parse this...but for pi, really don't want
        # all of those dependencies. So! Doing it the stupid brittle way here :)
        forecast_url = _get_string_value(data, "forecast")
        hourly_url = _get_string_value(data, "forecastHourly")
        @debug "Location urls: " forecast_url hourly_url

        @info "Fetching forecasts..."
        forecast_result = read(`curl $(forecast_url)`, String)
        hourly_result = read(`curl $(hourly_url)`, String)
        return forecast_result, hourly_result
    catch e
        @warn "Uh oh unable to get weather" e
        return missing
    end
end

function _get_weather_icon_from_hourly(hourly_forecast)
    # Check for rest of day through midnight
    # (_after_ midnight, is for next day)
    @info "Determining weather icon..."
    i = findfirst(1:24) do ind
        return contains(_get_string_value(hourly_forecast, "startTime"; index=ind), "T00")
    end
    weather_str = lowercase(join(map(k -> _get_string_value(hourly_forecast, "shortForecast";
                                                            index=k), 2:i)))

    contains(weather_str, "snow") && return SNOW
    contains(weather_str, "rain") && return RAIN

    if _get_bool_value(hourly_forecast, "isDaytime")
        return contains(lowercase(_get_string_value(hourly_forecast, "shortForecast")),
                        "sun") ? SUN : CLOUD
    end
    return NIGHT
end

# Return short form, long form
format_weather(::Any) = ("N/A", "Unable to fetch weather")

function format_weather(forecast, hourly_forecast)
    @info "Formatting output..."
    weather_icon = _get_weather_icon_from_hourly(hourly_forecast)
    short_str = vcat(text_to_dots_bytes(string("   ",
                                               _get_int_value(hourly_forecast,
                                                              "temperature"), "°")),
                     weather_icon)
    long_str = string("Now: ", _get_int_value(hourly_forecast, "temperature"), "° ",
                      _get_string_value(forecast, "shortForecast"), "! ",
                      _get_string_value(forecast, "name"; index=3), ": ",
                      _get_string_value(forecast, "shortForecast"; index=3), "!")
    return short_str, text_to_dots_bytes(long_str)
end

function update_with_current_weather(; scroll_long_msg=true)
    # Get weather
    bytes_static, bytes_scroll = format_weather(get_weather()...)

    # Display it!
    if scroll_long_msg
        @info "Displaying scrolling output..."
        scroll_bytes(dots_sink, bytes_scroll; loopcount=1)
    end
    @info "Displaying static output..."
    display_bytes(dots_sink, bytes_static)
    return nothing
end

if isinteractive()
    update_with_current_weather()
else
    # When running as script (not from REPL)...
    # ...update every hour until we tell it to stop
    update_pause_sec = 60 * 60
    scroll_long = true
    while true
        update_with_current_weather(; scroll_long_msg=scroll_long)
        global scroll_long = false # Only scroll the first time
        sleep(update_pause_sec)
    end
    display_bytes(text_to_dots_bytes("Huzzah!"))
end