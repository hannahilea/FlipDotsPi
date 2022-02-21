## Display bus timing on a flipdigits display

# Using MBTA API:
# https://api-v3.mbta.com/docs/swagger/index.html#/Schedule/ApiWeb_ScheduleController_index
# e.g.
# https://api-v3.mbta.com/schedules?filter[stop]=2512&filter[route]=91&filter[direction_id]=1&sort=arrival_time&page[limit]=140

using FlipBoard
using HTTP
using JSON

# Set up board
# Board-specific setup
# Hacky check to see if we're on the pi, to prevent trying to connect to port that
# isn't set up from laptop. For other systems, update `shared_srl` to point to
# the relevant serial port!
shared_srl = Sys.islinux() ? open_srl(; portname="/dev/ttyS0", baudrate=57600) : IOBuffer()

digits_sink = AlphaZetaSrl(; address=0x01, srl=shared_srl)

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

function update_with_current_timing()
    bus_strs = map(default_busses) do bus
        t = get_next_bus(bus)
        return string(bus.name, " ", t)
    end
    formatted_msg = join(rpad.(bus_strs, 7))
    bytes_static = text_to_digits_bytes(formatted_msg)

    # Display it!
    display_bytes(digits_sink, bytes_static)
    return nothing
end

# When running as script (not from REPL)...
if !isinteractive()
    # ...update every 30 sec for 44 minutes
    update_pause_sec = 30
    num_updates = 2 * 4

    for _ in 1:num_updates
        update_with_current_timing()
        sleep(update_pause_sec)
    end
    display_bytes(text_to_dots_bytes("Huzzah!"))
end