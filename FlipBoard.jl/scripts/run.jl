## Run FlipBoard.jl from the command line to scroll a single message

# TODO: check for environment or activate it if need be
using FlipBoard
using ArgParse

#TODO: update functions/function names for rewrite
function parse_commandline()
    s = ArgParseSettings(; description="Scroll a message on a FlipDots display.")
    @add_arg_table s begin
        "--loopcount"
            help = "Number of times to scroll the message"
            arg_type = Int
            default = DEFAULT_LOOPCOUNT
        "--baudrate"
            help = "Baudrate of the display"
            arg_type = Int
            default = DEFAULT_BAUDRATE
        "--portname"
            help = "Serial port name for the display"
            arg_type = String
            default = DEFAULT_PORTNAME
        "--scrollpause"
            help = "Pause between scroll updates (sec)"
            arg_type = Float32
            default = DEFAULT_SCROLLPAUSE
        "--panelwidth"
            help = "Width of the display (# dots)"
            arg_type = Int
            default = DEFAULT_PANEL_WIDTH
        "--displaytype"
            help = "Font option: flipdots display (`dots`) or flipdigits display (`digits`)"
            arg_type = String
            default = DEFAULT_displaytype
        "--verbose"
            help = "Show additional debug statements"
            action = :store_true
        "message"
            help = "Message to be displayed; supports uppercase letters, numbers, and limited symbols." #TODO list symbols
            required = true
    end
    return parse_args(s)
end

# ...when running as script (not from REPL):
if !isinteractive()
    d = parse_commandline()
    args = NamedTuple{Tuple(Symbol.(keys(d)))}(values(d))
    args.verbose && println("Parsed args: $args")

    srl = setup_srl() #TODO implement
        # baudrate=args.baudrate,
        #            portname=args.portname,
    board = FlipDigits() #TODO: construct from options displaytype=args.displaytype
        # panel_width=args.panelwidth
    msg = text_to_bytes(board, args.message)
    scroll_bytes(msg; loopcount=args.loopcount, scrollpause=args.scrollpause)
end
