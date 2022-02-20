## Run FlipBoard.jl from the command line to scroll a single message

# Safety first
using Pkg
if Pkg.project().name != "FlipBoard"
    @warn "Not running from w/in FlipBoard.jl environment; activate environment before running."
end

using FlipBoard
using ArgParse

function parse_commandline()
    s = ArgParseSettings(; description="Scroll a message on a FlipDots display.")
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

# ...when running as script (not from REPL):
if !isinteractive()
    d = parse_commandline()
    args = NamedTuple{Tuple(Symbol.(keys(d)))}(values(d))
    args.verbose && println("Parsed args: $args")

    # Set up
    srl = open_srl(; portname=args.portname, baudrate=args.baudrate)
    sink = AlphaZetaSrl(; address=args.address, srl)

    msg = displaytype == "digits" ? text_to_digits_bytes(args.message) :
          text_to_dots_bytes(args.message)
    args.repeatcount < 1 ? display_bytes(sink, msg) :
        scroll_bytes(sink, msg; scrollpause=args.scrollpause, loopcount=args.loopcount)
end
