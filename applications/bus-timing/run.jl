## Display bus timing on a flipdigits display

# e.g.
# https://api-v3.mbta.com/schedules?filter[stop]=2512&filter[route]=91&filter[direction_id]=1&sort=arrival_time&page[limit]=140

using FlipBoard
using HTTP
using JSON

# Set up board
shared_srl = open_srl(; portname="/dev/ttyS0", baudrate=57600)
dots_sink = AlphaZetaSrl(; address=0x00, srl=shared_srl)

##### Helper functions

function find_route_id(name)
    data = JSON.parse(String(HTTP.request("GET", "https://api-v3.mbta.com/routes").body))["data"]
    i = findfirst(data) do d
        return d["attributes"]["short_name"] == name
    end
    return data[i]["id"], data[i]
end

# Direction index: outbound = 0, inbound = 1 (todo: maybe +1??)
function find_stop_id(route_id, direction_index; target_on_street, target_at_street)
    # Get all stops for the route
    route_stops = JSON.parse(String(HTTP.request("GET",
                                                 "https://api-v3.mbta.com//schedules?filter[route]=$(route_id)").body))["data"]
    filter!(r -> r["attributes"]["direction_id"] == direction_index, route_stops)
    route_stops_ids = unique([s["relationships"]["stop"]["data"]["id"] for s in route_stops])

    # Investigate the stop details to find the one we care about
    stop_details = JSON.parse(String(HTTP.request("GET",
                                                  "https://api-v3.mbta.com/stops").body))["data"]
    filter!(s -> s["id"] in route_stops_ids, stop_details)

    i = only(findall(stop_details) do s
                 on_street = s["attributes"]["on_street"]
                 at_street = s["attributes"]["at_street"]
                 return on_street == target_on_street && at_street == target_at_street
             end)
    return stop_details[i]["id"], stop_details[i]
end

function get_next_bus(route_id, stop_id, dir_i=1)
    return nothing
end

#####

DEFAULT_BUSSES = [("91", 1, "Webster Avenue", nothing),
                  ("85", 1, "Webster Avenue", nothing), #TODO
                  ("CT2", 1, "Webster Avenue", nothing), #TODO
                  ("86", 1, "Webster Avenue", nothing)] #TODO

function get_default_routes()
    return map(DEFAULT_BUSSES) do (name, dir_i, target_on_street, target_at_street)
        route_id, _ = find_route_id(name)
        stop_id, _ = find_stop_id(route_id, dir_i; target_on_street, target_at_street)

        return (route_id, stop_id, dir_i)
    end
end

# Set up bus routes
function get_route_timing(; route, verbose=false)
    try
        verbose && (@info route)
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
    short_str = string("     ",
                       _get_first_int_result_after_key(hourly_forecast, "temperature"), "°")
    long_str = string("Now: ",
                      _get_first_int_result_after_key(hourly_forecast, "temperature"), "° ",
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