module WeatherApp 

export update_with_current_weather, update_with_current_date, update_every_half_hour

using FlipBoard
using FlipBoard: DOTS_SNOW, DOTS_SUN, DOTS_RAIN, DOTS_NIGHT, DOTS_CLOUD
using Dates

#####
##### Weather
#####

function get_weather(; location)
    try
        url = "https://api.weather.gov/points/$location"
        @info "Fetching forecast links from $url..."

        # Normally would use JSON to parse this...and HTTP.jl. but for pi, really don't want
        # all of those dependencies. So! Doing it a brittle way here :)
        # TODO: consider adding dep on the jq_dll?
        forecast_url, hourly_url = let 
            str = readlines(pipeline(`curl $url`,
            `jq '.properties.forecast, .properties.forecastHourly'`))
            map(s -> replace(s, "\""=>""), str)
        end
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

function _get_weather_icon_from_hourly(hourly_forecast_file)
    @info "Determining weather icon..."
    # Daily weather is split into hours, starting with the current hour  
    # We want to read all hours until midnight to figure out 
    # if there's going to be precipitation before then 

    # When is the current period?
    i_now = let 
        hour = last(split(string(now()), 'T'))[1:2]
        now_str = "T$hour"
        strs = readlines(pipeline(`cat $hourly_forecast_file`,
            `jq ".properties.periods[].startTime"`))
        i = findfirst(contains(now_str), strs)
        # We need the *json* index, which is 0-indexed 
        i - 1
    end

    # When is last period before midnight??
    i_midnight = let 
        midnight_str="T00:00:00"
        strs = readlines(pipeline(`cat $hourly_forecast_file`,
            `jq ".properties.periods[].endTime"`))
        i = findfirst(contains(midnight_str), strs)
        # We need the *json* index, which is 0-indexed 
        i - 1
    end
    short_forecasts_str = lowercase(read(pipeline(`cat $hourly_forecast_file`,
            `jq ".properties.periods[range($i_now; $i_midnight)].shortForecast"`), String))
    @info short_forecasts_str
    
    # Can we return early?
    contains(short_forecasts_str, "snow") && (@info "SNOW"; return DOTS_SNOW)
    contains(short_forecasts_str, "rain") && (@info "RAIN"; return DOTS_RAIN)
    contains(short_forecasts_str, "shower") && (@info "SHOWER"; return DOTS_RAIN)

    # Okay, we aren't obviously raining or snowing...
    current_short_forecast = lowercase(read(pipeline(`cat $hourly_forecast_file`,
            `jq ".properties.periods[$i_now].shortForecast"`), String))
    is_day = let 
        str = read(pipeline(`cat $hourly_forecast_file`,
            `jq ".properties.periods[$i_now].isDaytime"`), String)
        chomp(str) == "true"
    end
    if is_day
        @info "IS DAY!"
        return contains(current_short_forecast, "sun") ? (@info "SUN"; DOTS_SUN) : (@info "CLOUD"; DOTS_CLOUD)
    end
    @info "IS NOT DAY!"
    return contains(current_short_forecast, "mostly cloudy") ? (@info "CLOUD"; DOTS_CLOUD) : (@info "NIGHT"; DOTS_NIGHT)
end

# Return short form, long form
format_weather(sink, ::Missing, ::Missing) = (text_to_bytes(sink, "-"), text_to_bytes(sink, "Unable to fetch weather"))

_hour_from_time(str) = last(split(string(str), 'T'))[1:2]

function format_weather(sink, forecast, hourly_forecast)
    @info "Formatting output..."
    hourly_forecast_file = "_most_recent_hourly_forecast.json"
    write(hourly_forecast_file, hourly_forecast)
    forecast_file = "_most_recent_forecast.json"
    write(forecast_file, forecast)

    @info "Formatting short output..."
    weather_icon = _get_weather_icon_from_hourly(hourly_forecast_file)
    now_hour = _hour_from_time(now())
    i_now = let 
        now_str = "T$now_hour"
        strs = readlines(pipeline(`cat $hourly_forecast_file`,
            `jq ".properties.periods[].startTime"`))
        i = findfirst(contains(now_str), strs)
        # We need the *json* index, which is 0-indexed 
        i - 1
    end
    str = read(pipeline(`cat $hourly_forecast_file`, `jq ".properties.periods[$i_now].temperature"`), String)
    temp = chomp(str)
    short_str = vcat(text_to_bytes(sink, string("   ", temp, "°")), weather_icon)
    
    @info "Formatting scrolling output..."
    short_forecast = let 
        # Basic forecast is split into periods, where the current hour is first
        str = read(pipeline(`cat $hourly_forecast_file`, `jq ".properties.periods[$i_now].shortForecast"`), String)
        replace(chomp(str), "\"" => "")
    end
    next_forecast = let 
        hour = parse(Int, now_hour)
        strs = readlines(pipeline(`cat $forecast_file`, `jq ".properties.periods[].endTime"`))
        hours = map(s -> parse(Int, _hour_from_time(s)), strs)
        for i in 2:length(hours)
            while hours[i] < hours[i - 1]
                hours[i] += 24
            end
        end 
        i_now = findfirst(>(hour), hours)
        if abs(hours[i_now] - hour) < 1
            # If we're near the end of the current time block, look ahead one block
            i_now += 1
        end
        i_now -= 1 # b/c json

        name = read(pipeline(`cat $forecast_file`, `jq ".properties.periods[$i_now].name"`), String)
        content = read(pipeline(`cat $forecast_file`, `jq ".properties.periods[$i_now].shortForecast"`), String)
        replace(chomp(name) * ": " * chomp(content), "\"" => "")
    end

    long_str = string("Now: ", temp, "° ", short_forecast * "! ", next_forecast * "!")
    @info "\t-> $(long_str)"
    return short_str, text_to_bytes(sink, long_str)
end

function update_with_current_weather(sink; scroll_long_msg=true, location)
    @info "Updating!" now()
    
    # Get weather
    forecast_result, hourly_result = get_weather(; location)
    bytes_static, bytes_scroll = format_weather(sink, forecast_result, hourly_result)

    # Display it!
    flash_reset(sink)
    if scroll_long_msg
        @info "Displaying scrolling output..."
        scroll_bytes(sink, bytes_scroll; loopcount=1)
    end
    @info "Displaying static output..."
    write_to_sink(sink, bytes_static)
    return nothing
end

#####
##### Date 
#####

function update_with_current_date(sink)
    t = Dates.today()
    _rpad = (str) -> rpad(str, 7)

    m = length(monthname(t)) > 7 ? monthabbr(t) : monthname(t)
    d = length(dayname(t)) > 7 ? dayabbr(t) : dayname(t)

    date_str = join(_rpad.([day(t), m, d]))
    bytes = text_to_bytes(sink, date_str)
    write_to_sink(sink, bytes)
    return nothing
end


#####
##### Main entrypoint
#####

function update_every_half_hour(dots_sink, digits_sink; location)
    @info "Running per-half-hour update"
    last_set = now()
    while true
        if Dates.minute(now()) % 30 == 0 && round(now() - last_set, Minute) > Minute(4)
            last_set = now()
            update_with_current_weather(dots_sink; scroll_long_msg=false, location)
            update_with_current_date(digits_sink)
        end
        sleep(0.2) # half second polling
    end
    return nothing
end

end #WeatherApp
