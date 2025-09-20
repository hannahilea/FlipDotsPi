## Run FlipBoard.jl from the command line to scroll a single message
@info "Setting up environment..."
using Pkg
Pkg.resolve()
Pkg.instantiate()

@info "Loading dependencies..."
using ArgParse
using FlipBoard
using REPL

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
        help = "Message to be displayed; supports uppercase letters, numbers, and limited symbols. If missing, enters live text mode"
        default = missing
        required = false
    end
    return parse_args(s)
end


# Adapted from which was adapted from plotter-lab which was adapted from 
# https://discourse.julialang.org/t/timed-wait-for-key-press
function realtime_repl_display!(sink)
    @info "Entering live-scroll mode. Any characters you type will immediately be displayed on the board. Hit `esc` to leave."
    if isdefined(Main, :VSCodeServer)
        @warn "Likely cannot run `destination_repl` from an interactive VSCode session; user input broken"
    end

    term = REPL.Terminals.TTYTerminal("xterm", stdin, stdout, stderr)
    REPL.Terminals.raw!(term, true)
    Base.start_reading(stdin)

    msg_buffer = zeros(UInt8, sink.serial_port_config.num_msg_bytes)
    while true
        sleep(0.01) # TODO Tune
        if bytesavailable(stdin) > 0
            b = read(stdin, bytesavailable(stdin))
            if b == UInt8[0x1b] # escape key 
                break 
            end
            msg = text_to_bytes(sink, String(b))
            deleteat!(msg_buffer, 1:length(msg))
            append!(msg_buffer, msg)
            @info "Okay" msg_buffer msg
            write_to_sink(sink, msg_buffer)  
        end
    end
    println("Live-display mode over---thanks for playing! :)")
end

# Support testing locally when setting sink to missing
# write_to_sink(::Missing, msg) = println("TYPED: $msg")
# FlipBoard.text_to_bytes(::Missing, msg::String) = msg

function main()
    d = parse_commandline()
    args = NamedTuple{Tuple(Symbol.(keys(d)))}(values(d))
    args.verbose && println("Parsed args: $args")

    @info "Setting up serial port for flip boards..."
    srl = open_srl_iff_available(; portname=args.portname, baudrate=args.baudrate)

    sink = args.displaytype == "digits" ? AZDigitsSink(; address=args.address, serial_port=srl) :
           AZDotsSink(; address=args.address, serial_port=srl)

    if ismissing(args.message)
        realtime_repl_display!(sink)
    else
        msg = text_to_bytes(sink, args.message)
        args.loopcount < 1 ? write_to_sink(sink, msg) :
        scroll_bytes(sink, msg; scrollpause=args.scrollpause, loopcount=args.loopcount)
    end
    return nothing
end

# ...when running as script (not from REPL):
isinteractive() || main()
