module WeatherApp 

export update_with_current_weather, update_with_current_date, update_every_half_hour

using FlipBoard
using FlipBoard: DOTS_SNOW, DOTS_SUN, DOTS_RAIN, DOTS_NIGHT, DOTS_CLOUD
using Dates

#####
##### Weather
#####

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
        return missing, missing
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
    contains(weather_str, "shower") && return DOTS_RAIN

    if _get_bool_value(hourly_forecast, "isDaytime")
        return contains(lowercase(_get_string_value(hourly_forecast, "shortForecast")),
                        "sun") ? DOTS_SUN : DOTS_CLOUD
    end
    return DOTS_NIGHT
end

# Return short form, long form
format_weather(::Missing, ::Missing) = (text_to_dots_bytes("-"), text_to_dots_bytes("Unable to fetch weather"))

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
    #TODO-handle separately, handle 'missing' appropriately
    bytes_static, bytes_scroll = format_weather(get_weather()...)

    # Display it!
    flash_reset(dots_sink)
    if scroll_long_msg
        @info "Displaying scrolling output..."
        scroll_bytes(dots_sink, bytes_scroll; loopcount=1)
    end
    @info "Displaying static output..."
    display_bytes(dots_sink, bytes_static)
    return nothing
end

#####
##### Date 
#####

function update_with_current_date()
    t = Dates.today()
    _rpad = (str) -> rpad(str, 7)

    m = length(monthname(t)) > 7 ? monthabbr(t) : monthname(t)
    d = length(dayname(t)) > 7 ? dayabbr(t) : dayname(t)

    date_str = join(_rpad.([day(t), m, d]))
    bytes = text_to_digits_bytes(date_str)
    display_bytes(digits_sink, bytes)
    return nothing
end


#####
##### Main entrypoint
#####

function update_every_half_hour()
    @info "Running per-half-hour update"
    last_set = now()
    while true
        if Dates.minute(now()) % 30 == 0 && round(now() - last_set, Minute) > Minute(4)
            last_set = now()
            update_with_current_weather(; scroll_long_msg=false)
            update_with_current_date()
            @info "okay"
        end
        sleep(0.2) # half second polling
    end
    return nothing
end

end #WeatherApp
