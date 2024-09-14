# Generate content filmed for blog post
using FlipBoard
shared_srl = open_srl_iff_available(; portname="/dev/ttyS0", baudrate=57600)
dots_sink = AZDotsSink(; address=0x00, serial_port=shared_srl)
digits_sink = AZDigitsSink(; address=0x01, serial_port=shared_srl)
both_boards_sink = all_alphazeta_sink(shared_srl)

# 1. Original/full clapping music 
flash_reset(both_boards_sink)
FlipBoard.clapping_music(dots_sink, digits_sink; pause=0.15, num_repeats=12,
                         num_dots_to_set=28, num_digits_to_set=2)

#1. Original - 2 repeats only, no prefix 
flash_reset(both_boards_sink)
FlipBoard._clapping_music(dots_sink, digits_sink; pause=0.15, num_repeats=2,
                          num_dots_to_set=28, num_digits_to_set=2)
sleep(1)
flash_reset(both_boards_sink)

# 2A. Demo individual segments: dots
for c in ['.', ':', '!'], num_dots in 1:14
    write_to_sink(dots_sink, text_to_bytes(dots_sink, repeat(c, num_dots)))
    sleep(0.1)
    all_dark(dots_sink)
    sleep(0.1)
end
all_bright(dots_sink)
sleep(0.1)
all_dark(dots_sink)
sleep(0.1)
all_bright(dots_sink)
sleep(0.1)
all_dark(dots_sink)

# 2B. Demo individual segments: dots
for c in ['-', '1', '8'], num_digits in 1:28
    write_to_sink(digits_sink, text_to_bytes(digits_sink, repeat(c, num_digits)))
    sleep(0.1)
    all_dark(digits_sink)
    sleep(0.1)
end
all_bright(digits_sink)
sleep(0.1)
all_dark(digits_sink)
sleep(0.1)
all_bright(digits_sink)
sleep(0.1)
all_dark(digits_sink)

# 3. Demo alternate approaches to clapping music
# Pattern A
all_dark(both_boards_sink)
clap_pattern = Bool[1, 0, 0, 1, 1, 1]
FlipBoard._clapping_music(dots_sink, digits_sink; clap_pattern, pause=0.12, num_repeats=2,
                          num_dots_to_set=14, num_digits_to_set=4)
sleep(1)
all_dark(both_boards_sink)

# Pattern B
all_dark(both_boards_sink)
clap_pattern = Bool[1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0]
FlipBoard._clapping_music(dots_sink, digits_sink; clap_pattern, pause=0.15, num_repeats=2,
                          num_dots_to_set=28, num_digits_to_set=14)
sleep(1)
all_dark(both_boards_sink)
