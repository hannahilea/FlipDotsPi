# Demonstrate current functionality on one-each AlphaZeta 7x28 FlipDots board
# and AlphaZeta 7-seg digits board
using FlipBoard

# In our system, both boards are connectd to the same pi0 port:
shared_srl = open_srl_iff_available(; portname="/dev/ttyS0", baudrate=57600)

# If we aren't connected to the serial port (ie aren't connected to a board), 
# nothing is going to happen. Sorry! :D (One could write a visualization tool, 
# if one was annoyed by this....)

# Set up boards
dots_sink = AZDotsSink(; address=0x00, serial_port=shared_srl)
digits_sink = AZDigitsSink(; address=0x01, serial_port=shared_srl)
both_boards_sink = all_alphazeta_sink(shared_srl)

@info "Testing reset behavior"
flash_reset(both_boards_sink)
sleep(1)
all_bright(dots_sink)
sleep(1)
all_dark(dots_sink)
sleep(1)
all_bright(digits_sink)
sleep(1)
all_dark(digits_sink)

@info "Test single message"
write_to_sink(dots_sink, "YAY DOTS")
write_to_sink(digits_sink, "YAY DIGITS")
clear(both_boards_sink)

@info "Testing message scrolling"
scroll_message(dots_sink, "Yay dots")
scroll_message(digits_sink, "Yay digits")

@info "Testing `clapping_music`"
FlipBoard.perform_clapping_music(dots_sink, digits_sink; num_repeats=4, num_shifts=2)

## Drum examples
const rhythm1 = ["1 1 1 1 ", "1 1    1 ", " 1     1 ", "      "]

const rhythm2 = ["1 1 1 1 1 1 1 1 1 1 1 1 1 1", "1   1 1 1   1 1 1 1   1 1 1",
                 "1   1 1 1             1 1 1", ""]
FlipBoard.drumbeat_snippet(dots_sink, rhythm1)
FlipBoard.drumbeat_snippet(digits_sink, rhythm2)
