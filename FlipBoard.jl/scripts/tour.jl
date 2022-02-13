# Demonstrate current functionality on one-each AlphaZeta 7x28 FlipDots board
# and AlphaZeta 7-seg digits board

using FlipBoard

# Board-specific setup
shared_srl = IOBuffer()
if false #ON THE PI?!?! SET TO TRUE!
    shared_srl = open_srl(; portname="/dev/ttyS0", baudrate=57600)
else
    show_output = () -> @info("Printed bytes: " * String(take!(both_boards_sink.srl)))
end

# Utils
function _log_board(expr; wait_sec=missing, label=missing)
    ismissing(label) ? println("Trying `$expr`...") : println(label, "...")
    eval(expr)
    println("")
    ismissing(wait_sec) ? Base.prompt("Press any key to continue") : sleep(wait_sec)
    return nothing
end

macro log_board(expr)
    return _log_board(expr)
end

macro log_board(label::AbstractString, expr)
    return _log_board(expr; label)
end

macro log_board(label::AbstractString, wait_sec::Int, expr)
    return _log_board(expr; label, wait_sec)
end

# Set up boards
dots_sink = AlphaZetaSrl(; address=0x03, srl=shared_srl)
digits_sink = AlphaZetaSrl(; address=0x07, srl=shared_srl)
both_boards_sink = all_alphazeta(shared_srl)

@info "Testing reset behavior"
flash_reset(both_boards_sink)
sleep(1)
all_bright(dots_sink)
sleep(1)
all_bright(digits_sink)
sleep(1)
all_dark(both_boards_sink)
sleep(1)

@info """Test single message"
        - Same message sent to both boards at once, so
          message will be garbled on one board at a time
      """
msg_dots = text_to_dots_bytes("YAY DOTS")
msg_digits = text_to_digits_bytes("YAY DIGITS")
@log_board "Display dots on both" display_bytes(both_boards_sink, msg_dots)
clear(both_boards_sink)
@log_board "Display digits on both" display_bytes(both_boards_sink, msg_digits)
clear(both_boards_sink)

@info "Testing single message to single board"
@log_board "Display dots on dots" display_bytes(dots_sink, msg_dots)
clear(both_boards_sink)
@log_board "Display digits on digits" display_bytes(digits_sink, msg_digits)
clear(both_boards_sink)

@info "Testing message scrolling"
@log_board "Scroll dots on dots" scroll_bytes(dots_sink, msg_dots)
clear(both_boards_sink)
@log_board "Scroll digits on digits" scroll_bytes(digits_sink, msg_digits)
clear(both_boards_sink)

## Drum examples :)
# TODO: digits message