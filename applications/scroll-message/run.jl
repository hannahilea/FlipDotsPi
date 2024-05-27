## Run FlipBoard.jl from the command line to scroll a single message
@info "Setting up environment..."
using Pkg
Pkg.resolve()
Pkg.instantiate()

@info "Loading dependencies..."
using ArgParse
using FlipBoard

# # Set up flipboard serial communication
# # For this app, we're communicating with two boards: one flipdots (for weather) 
# # and one flipdigits (for date). If only one is present, the script will still run 
# @info "Setting up serial port for flip boards..."
# shared_srl = missing
# try
#     shared_srl = open_srl(; portname="/dev/ttyS0", baudrate=57600)
# catch
#     @warn "No serial port found; ensure board is connected and/or portnmae is correct"
# end

# dots_sink = AlphaZetaSrl(; address=0x00, srl=shared_srl)
# digits_sink = AlphaZetaSrl(; address=0x01, srl=shared_srl)

######

function parse_commandline()
    s = ArgParseSettings(;
                         description="Scroll a message on a FlipDots or FlipDigits display.")
    @add_arg_table s begin
        "--loopcount"
        help = "Number of times to repeat the message. (To display with no scroll, set o `0`.)"
        arg_type = Int
        default = 2
        "--baudrate"
        help = "Baudrate of the display"
        arg_type = Int
        default = 57600
        "--portname"
        help = "Serial port name for the display"
        arg_type = String
        default = "/dev/ttyS0"
        "--scrollpause"
        help = "Pause between scroll updates (sec)"
        arg_type = Float64
        default = 0.2
        "--displaytype"
        help = "Font option: flipdots display (`dots`) or flipdigits display (`digits`)"
        arg_type = String
        default = "dots"
        "--address"
        help = "Board address: display address (defaults to `0xFF` which sends to all boards)"
        arg_type = UInt8
        default = 0xFF #all connected boards
        "--verbose"
        help = "Show additional debug statements"
        action = :store_true
        "message"
        help = "Message to be displayed; supports uppercase letters, numbers, and limited symbols."
        required = true
    end
    return parse_args(s)
end

function main()
    d = parse_commandline()
    args = NamedTuple{Tuple(Symbol.(keys(d)))}(values(d))
    args.verbose && println("Parsed args: $args")

    @info "Setting up serial port for flip boards..."
    srl = open_srl_iff_available(; portname=args.portname, baudrate=args.baudrate)

    sink = args.displaytype == "digits" ? AZDigitsSink(; address=args.address, serial_port=srl) :
           AZDotsSink(; address=args.address, serial_port=srl)
    msg = text_to_bytes(sink, args.message)

    args.loopcount < 1 ? write_to_sink(sink, msg) :
    scroll_bytes(sink, msg; scrollpause=args.scrollpause, loopcount=args.loopcount)
    return nothing
end

# ...when running as script (not from REPL):
isinteractive() || main()
