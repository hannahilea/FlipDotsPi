module FlipBoard

export FlipDots, FlipDigits, scroll_message, log_board

using LibSerialPort

const DEFAULT_PANEL_WIDTH = 28
const DEFAULT_LOOPCOUNT = 1
const DEFAULT_SCROLLPAUSE = 0.3f0

const OPEN_SERIAL_PORTS = Ref{Dict{Tuple{String,Int64},SerialPort}}()

##########
########## Sink setup
##########

abstract type AbstractSink end

# For testing: IOSink

"""
    AlphaZetaSrl(; address::UInt8, srl::SerialPort, command::UInt8=0x83, num_msg_bytes::Int=28)

Sink for AlphaZeta board (of any type) with `address` connected to `srl`.

# Arguments
- `srl::SerialPort`
- `command::UInt8`: Set the display mode for the given display:
    - 0x81 - 112 bytes / no refresh / C+3E
    - 0x82 - refresh
    - 0x83 - 28 bytes of data / refresh / 2C <-- Default for 7x28 dots board OR 28-digit 7-seg digit display.
    - 0x84 - 28 bytes of data / no refresh / 2C
    - 0x85 - 56 bytes of data / refresh / C+E
    - 0x86 - 56 bytes of data / no refresh / C+E
- `num_msg_bytes::Int`: Set the number of data bytes the display expects with
        each message. Default is 28, for 7x28 dots board OR 28-digit 7-seg digit display.
"""
Base.@kwdef struct AlphaZetaSrl <: AbstractSink
    address::UInt8
    srl::SerialPort
    command::UInt8 = 0x83
    num_msg_bytes::Int = 28
end

"""
    all_alphazeta(srl)

Sink for all AlphaZeta boards connected to `srl`.
"""
all_alphazeta(srl) = AlphaZetaSrl(0xFF, srl)

"""
    display_bytes(sink::AlphaZetaSrl, byte_msg; length_msg=28)

`byte_msg` MUST be at least as long as `length_msg` (it can be longer).
TODO: move `length_msg` out...into `AlphaZetaSrl` maybe? Although should be
known ahead of time....not responsibility of sink to know how big it is, maybe...
"""
function display_bytes(sink::AlphaZetaSrl, byte_msg; length_msg=28)
    transmission = [0x80, sink.command, sink.address, byte_msg[1:length_msg]..., 0x8F]
    return write(sink.srl, transmission)
end

"""
    open_srl(; portname, baudrate)

If it already exists, return it; if it doesn't, make
and open it.
"""
function open_srl(; portname, baudrate)
    key = (portname, baudrate)
    return get(key, OPEN_SERIAL_PORTS) do
        srl = open(portname, baudrate; SP_MODE_WRITE)
        return srl
    end
end

##########
########## Construct byte messages
##########

function all_bright(sink::AlphaZetaSrl)
    #full message
    return display_bytes()
end

function all_dark(sink::AlphaZetaSrl)
    #full message
    return display_bytes()
end

function clear(sink::AlphaZetaSrl)
    all_bright()
    all_dark()
    return nothing
end

###

abstract type AbstractFlipBoard end

function _error_not_yet_implemented(f, t)
    return error("`$f` not yet implemented for type `::$(typeof(t))`")
end

text_to_bytes(::AbstractFlipBoard, msg::AbstractVector{UInt8}; kwargs...) = msg
function text_to_bytes(fb::AbstractFlipBoard, msg; kwargs...)
    return _error_not_yet_implemented("text_to_bytes", fb)
end

#####
##### FlipDots board
#####

Base.@kwdef struct FlipDots <: AbstractFlipBoard
    width::Integer = 28
    height::Integer = 7
    font::Dict = dots_font
end

text_to_bytes(fb::FlipDots, msg) = _text_to_bytes(msg, fb.font, true, false)

#####
##### FlipDigits board
#####

Base.@kwdef struct FlipDigits <: AbstractFlipBoard
    width::Integer = 7
    height::Integer = 4
    font::Dict = digits_font
end

text_to_bytes(fb::FlipDigits, msg) = _text_to_bytes(msg, fb.font, false, true)

#####
##### Utils
#####

function seg_to_bits(i_segs::AbstractVector)
    bitstr = zeros(Int, 8)
    foreach(i -> bitstr[i] = 1, i_segs)
    return parse(UInt8, reverse(join(bitstr)); base=2)
end

function send_transmission(srl, msg::UInt8; num_bytes=0x83, panel_address=0xFF)
    #TODO ensure msg is max bytes OR && it with max bytes so it works
    transmission = [0x80, num_bytes, panel_address, msg..., 0x8F]
    write(srl, transmission)
    return nothing
end

function _text_to_bytes(msg, font::Dict, space_btwn_chars::Bool, space_at_end::Bool)
    # loop over question string and add columns to question
    b_msg = UInt8[]
    foreach(uppercase(msg)) do C
        x = get(font, C, missing)
        if !ismissing(x)
            append!(b_msg, x)
            space_btwn_chars && append!(b_msg, 0)
        end
    end
    space_at_end && append!(b_msg, 0)
    return b_msg
end

#todo: rewrite for ring buffer
function scroll_bytes(srl, msg::AbstractVector{UInt8}; loopcount=1, scrollpause=0.3) #TODO defaults
    msg = text_to_bytes(b, msg; kwargs...)
    for i in 1:loopcount, t in 1:length(msg)
        wrap_msg = i != loopcount
        slice = zeros(UInt8, 28) #TODO: generic for width
        for (i_slice, i_msg) in enumerate(t:(t + 27))
            if i_msg <= length(msg)
                slice[i_slice] = msg[i_msg]
            elseif wrap_msg
                slice[i_slice] = msg[i_msg % length(msg)]
            end
        end
        send_transmission(srl, slice)
        sleep(scrollpause)
    end
end

function flash_display(srl, pause=0.5; loopcount=1, buffer_length=28)
    for i in loopcount
        send_transmission(srl, ones(UInt8, buffer_length))
        sleep(pause)
        send_transmission(srl, zeros(UInt8, buffer_length))
        sleep(pause)
    end
    return nothing
end

include("fonts.jl")
include("extras.jl")

end