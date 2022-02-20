## Display bus timing on a flipdigits display

update_pause_sec = 30 # update twice per minute
num_updates = 8 # update for four minutes (given update rate)

using FlipBoard

# Set up
srl = open_srl(; portname="/dev/ttyS0", baudrate=57600)
digits_sink = AlphaZetaSrl(; address=0x01, srl=srl) # digits board!

for _ in 1:num_updates
    bus_msg = ""
for bus in ["ct2", "91", "85", "X"]
    bus_msg = string("CT2", "    ", "91 ", "    ", "85", "     ", "X", "    ")
    display_bytes(digits_sink, text_to_digits_bytes(bus_msg))
    sleep(update_pause_sec)
end
