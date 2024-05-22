# Display weather on the flipdots board!
@info "Setting up environment..."
using Pkg
Pkg.resolve()
Pkg.instantiate()

@info "Loading dependencies..."
using FlipBoard
using FlipBoard: DOTS_SNOW, DOTS_SUN, DOTS_RAIN, DOTS_NIGHT, DOTS_CLOUD
using Dates

DEFAULT_LOCATION = "42.3876,-71.0995" # Update with desired lat/long

# Set up board
# Board-specific setup
# Hacky check to see if we're on the pi, to prevent trying to connect to port that
# isn't set up from laptop. For other systems, update `shared_srl` to point to
# the relevant serial port!
@info "Setting up serial port..."
shared_srl = Sys.islinux() ? open_srl(; portname="/dev/ttyS0", baudrate=57600) : IOBuffer()

dots_sink = AlphaZetaSrl(; address=0x00, srl=shared_srl)

# hacky JSON parser substitute
function _get_string_value(body, key; index=2)
    spl_body = split(body, "\"$key\": \"")
    if length(spl_body) < index
        @warn "no can do str" key length(spl_body) index now()
        return ""
    end
    return first(split(spl_body[index], "\","))
end

function _get_int_value(body, key; index=2)
    spl_body = split(body, "\"$key\": ")
    if length(spl_body) < index
        @warn "no can do int" key length(spl_body) index
        return "-"
    end
    return first(split(spl_body[index], ","))
end

function _get_bool_value(body, key; index=2)
    spl_body = split(body, "\"$key\": ")
    if length(spl_body) < index
        @warn "no can do int" key length(spl_body) index
        return true
    end
    return lowercase(first(split(spl_body[index], ","))) == "true"
end

# Set up weather
function get_weather(; location=DEFAULT_LOCATION)
    try
        @debug "Getting weather..." "https://api.weather.gov/points/$location"
        @info "Fetching forecast links..."
        data = read(`curl "https://api.weather.gov/points/$location"`, String)

        # Normally would use JSON to parse this...and HTTP.jl. but for pi, really don't want
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
    if isnothing(i)
        i = 2
        @info "Not sure why hourly forecast didn't have startTime..." now()
        @info hourly_forecast
    end
    weather_str = lowercase(join(map(k -> _get_string_value(hourly_forecast,
                                                            "shortForecast"; index=k), 2:i)))

    contains(weather_str, "snow") && return DOTS_SNOW
    contains(weather_str, "rain") && return DOTS_RAIN

    if _get_bool_value(hourly_forecast, "isDaytime")
        return contains(lowercase(_get_string_value(hourly_forecast, "shortForecast")),
                        "sun") ? DOTS_SUN : DOTS_CLOUD
    end
    return DOTS_NIGHT
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
    @info "Formatting scrolling output..."
    long_str = string("Now: ", _get_int_value(hourly_forecast, "temperature"), "° ",
                      _get_string_value(forecast, "shortForecast"), "! ",
                      _get_string_value(forecast, "name"; index=3), ": ",
                      _get_string_value(forecast, "shortForecast"; index=3), "!")
    @info "\t-> $(long_str)"
    return short_str, text_to_dots_bytes(long_str)
end

function update_with_current_weather(; scroll_long_msg=true)
    @info "Updating!" now()
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

function update_every_half_hour()
    update_pause_sec = 30 * 60
    scroll_long = true
    while true
        update_with_current_weather(; scroll_long_msg=scroll_long)
        scroll_long = false # Only scroll the first time
        sleep(update_pause_sec)
        flash_reset(dots_sink)
    end
    return nothing
end

if isinteractive()
    update_with_current_weather()
else
    # When running as script (not from REPL)...
    # ...update every half hour until we cancel the script
    update_every_half_hour()
end
