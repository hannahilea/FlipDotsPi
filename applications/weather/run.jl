## Display bus timing on a flipdigits display

update_pause_sec = 15 * 60 # update every 15 min
num_updates = 8 # update for four minutes (given update rate)

using FlipBoard

# Set up
srl = open_srl(; portname="/dev/ttyS0", baudrate=57600)
dots_sink = AlphaZetaSrl(; address=0x00, srl=srl)



for _ in 1:num_updates
    weather_scroll_msg = ""
    weather_static_msg = ""


    display_bytes(sink, text_to_digits_bytes(bus_msg))
    sleep(update_pause_sec)
end
