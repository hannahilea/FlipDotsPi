# Demonstrate current functionality on one-each AlphaZeta 7x28 FlipDots board
# and AlphaZeta 7-seg digits board

using FlipBoard

# Board-specific setup
shared_srl = open_srl(; portname="/dev/ttyS0", baudrate=57600)
dots_sink = AlphaZetaSrl(0x01, shared_srl) #TODO set up
digits_sink = AlphaZetaSrl(0x02, shared_srl) #TODO set up
both_boards_sink = all_alphazeta(shared_srl)

# Set up testing environment
macro log_board(label::AbstractString, expr)
    clear(both_boards_sink)
    return _log_board(expr; label)
end

macro log_board(label::AbstractString, wait_sec::Int, expr)
    clear(both_boards_sink)
    return _log_board(expr; label, wait_sec)
end

# Test senging single message
first_message = "Huzzah!"
msg_dots = text_to_bytes(::FlipDots, first_message)
msg_digits = text_to_bytes(::FlipDigits, first_message)

@info "Single text message on both boards"
@log_board "Display dots on both" display_bytes(both_boards_sink, msg_dots)
@log_board "Display digits on both" display_bytes(both_boards_sink, msg_digits)
@log_board "Display dots on dots" display_bytes(dots_sink, msg_dots)
@log_board "Display digits on digits" display_bytes(digits_sink, msg_digits)

# TODO: digits message
# TODO: dots message

## Scroll message
# TODO: digits message
# TODO: dots message

## Give boards different addresses, send messages independently!
# TODO: digits message
# TODO: dots message

## Drum examples :)
# TODO: digits message