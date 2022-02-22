module FlipBoard

export open_srl, AlphaZetaSrl, all_alphazeta, scroll_bytes, flash_reset, all_bright,
       all_dark, clear, text_to_digits_bytes, text_to_dots_bytes, display_bytes

using LibSerialPort

const OPEN_SERIAL_PORTS = Dict{Tuple{String,Int64},SerialPort}()

##########
########## Sink setup
##########

abstract type AbstractSink end

# For testing: IOSink

"""
    AlphaZetaSrl(; address::UInt8, srl::SerialPort, command::UInt8=0x83, num_msg_bytes::Int=28)

Sink for AlphaZeta board (of any type) with `address` connected to `srl`.

# Arguments
- `srl::Union{SerialPort,IOBuffer}`: Should be a SerialPort when running from a pi;
        the IOBuffer option is so support testing.
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
Base.@kwdef struct AlphaZetaSrl #<: AbstractSink
    address::UInt8
    srl::Union{SerialPort,IOBuffer}
    command::UInt8 = 0x83
    num_msg_bytes::Int = 28
end

"""
    all_alphazeta(srl)

Sink for all AlphaZeta boards connected to `srl`.
"""
all_alphazeta(srl) = AlphaZetaSrl(; address=0xFF, srl)

"""
    display_bytes(sink::AlphaZetaSrl, byte_msg)
"""
function display_bytes(sink::AlphaZetaSrl, byte_msg::AbstractVector{UInt8})
    bytes = view(byte_msg, 1:min(sink.num_msg_bytes, length(byte_msg)))
    extra_bytes = zeros(UInt8, sink.num_msg_bytes - length(bytes))
    transmission = [0x80, sink.command, sink.address, bytes..., extra_bytes..., 0x8F]
    write(sink.srl, transmission)
    return nothing
end

"""
    open_srl(; portname, baudrate)

If it already exists, return it; if it doesn't, make
and open it.
"""
function open_srl(; portname, baudrate)
    key = (portname, baudrate)
    return get!(OPEN_SERIAL_PORTS, key) do
        return LibSerialPort.open(portname, baudrate; mode=SP_MODE_WRITE)
    end
end

##########
########## Construct byte messages
##########

all_bright(sink::AlphaZetaSrl) = display_bytes(sink, fill(0xFF, sink.num_msg_bytes))
all_dark(sink::AlphaZetaSrl) = display_bytes(sink, zeros(UInt8, sink.num_msg_bytes))
clear(sink::AlphaZetaSrl) = all_dark(sink)

function flash_reset(sink; pause=0.6)
    all_bright(sink)
    sleep(pause)
    all_dark(sink)
    return nothing
end

"""
Arguments:
- `font`: Currently supported fonts are `dots_font` and `digits_font`
"""
function text_to_dots_bytes(msg)
    return _text_to_bytes(msg; font=dots_font, space_btwn_chars=true, space_at_end=false)
end

function text_to_digits_bytes(msg)
    return _text_to_bytes(msg; font=digits_font, space_btwn_chars=false, space_at_end=true)
end

function _text_to_bytes(msg; font::Dict, space_btwn_chars::Bool, space_at_end::Bool)
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

#####
##### Utils
#####

# Useful for creating fonts
function seg_to_bits(i_segs::AbstractVector)
    bitstr = zeros(Int, 8)
    foreach(i -> bitstr[i] = 1, i_segs)
    return parse(UInt8, reverse(join(bitstr)); base=2)
end

include("fonts.jl")
include("extras.jl")

end