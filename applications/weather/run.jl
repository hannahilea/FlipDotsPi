# Display weather on the flipdots board!
using Pkg
Pkg.instantiate()

using FlipBoard
using HTTP

# Set up board
shared_srl = open_srl(; portname="/dev/ttyS0", baudrate=57600)
dots_sink = AlphaZetaSrl(; address=0x00, srl=shared_srl)

function _get_first_result_after_key(body, key; index=2)
    return first(split(split(body, "\"$key\": \"")[index], "\","))
end

function _get_first_int_result_after_key(body, key; index=2)
    return first(split(split(body, "\"$key\": ")[index], ","))
end

# Set up weather; default loc_str is Somerville, MA
function get_weather(; location="42.3876,-71.0995", verbose=false)
    try
        verbose && (@info "https://api.weather.gov/points/$location")
        result = String(HTTP.request("GET",
                                     "https://api.weather.gov/points/$location").body)

        # Normally would use JSON to parse this...but for pi, really don't want
        # all of those dependencies. So! Doing it the stupid brittle way here :)
        forecast_url = _get_first_result_after_key(result, "forecast")
        hourly_url = _get_first_result_after_key(result, "forecastHourly")
        verbose && (@info "Location urls: " forecast_url hourly_url)

        forecast_result = String(HTTP.request("GET", forecast_url).body)
        hourly_result = String(HTTP.request("GET", hourly_url).body)
        return forecast_result, hourly_result
    catch e
        @warn "Uh oh unable to get weather" e
        return missing
    end
end

# Return short form, long form
format_weather(::Any) = ("N/A", "Unable to fetch weather")

function format_weather(forecast, hourly_forecast)
    short_str = string("     ", _get_first_int_result_after_key(hourly_forecast, "temperature"),
                       "°")
    long_str = string("Now: ", _get_first_int_result_after_key(hourly_forecast, "temperature"), "° ",
                      _get_first_result_after_key(forecast, "shortForecast"), "! ",
                      _get_first_result_after_key(forecast, "name"; index=3), ": ",
                      _get_first_result_after_key(forecast, "shortForecast"; index=3), "!")

    return short_str, long_str
end

function update_with_current_weather()
    # Get weather
    static_msg, scroll_msg = format_weather(get_weather()...)
    bytes_scroll = text_to_dots_bytes(scroll_msg)
    bytes_static = text_to_dots_bytes(static_msg)

    # Display it!
    scroll_bytes(dots_sink, bytes_scroll; loopcount=1)
    display_bytes(dots_sink, bytes_static)
    return nothing
end

# When running as script (not from REPL)...
if !isinteractive()
    # ...update every fifteen minutes for 4 hours
    update_pause_sec = 60 * 15
    num_updates = 4 * 4

    for _ in 1:num_updates
        update_with_current_weather()
        sleep(update_pause_sec)
    end
    display_bytes(text_to_dots_bytes("Huzzah!"))
end