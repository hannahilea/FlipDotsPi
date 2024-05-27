module FlipBoard

export open_srl, open_srl_iff_available, all_alphazeta_sink, scroll_bytes, flash_reset,
       all_bright,  all_dark, clear, display, clapping_music, AZDotsSink, AZDigitsSink, 
       AZSinks, text_to_bytes

using LibSerialPort

const CURRENTLY_OPEN_SERIAL_PORTS = Dict{Tuple{String,Int64},SerialPort}()

##########
########## AlphaZeta setup
##########

"""
    AlphaZetaSerialPortConfig(; address::UInt8, serial_port::SerialPort, command::UInt8=0x83, 
                              num_msg_bytes::Int=28)

Sink config for AlphaZeta board (of any type) with `address` connected to `srl`.

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
Base.@kwdef struct AlphaZetaSerialPortConfig
    address::UInt8
    serial_port::Any
    command::UInt8 = 0x83
    num_msg_bytes::Int = 28
end

struct AZDotsSink
    serial_port_config::AlphaZetaSerialPortConfig
end

function AZDotsSink(; kwargs...)
    return AZDotsSink(AlphaZetaSerialPortConfig(; kwargs...))
end

struct AZDigitsSink
    serial_port_config::AlphaZetaSerialPortConfig
end

function AZDigitsSink(; kwargs...)
    return AZDigitsSink(AlphaZetaSerialPortConfig(; kwargs...))
end

const AZSinks = Union{AZDotsSink,AZDigitsSink}

num_msg_bytes(sink::AZSinks) = sink.serial_port_config.num_msg_bytes

"""
    display(sink::AZSinks, byte_msg::AbstractVector{UInt8})
    display(sink::AlphaZetaSerialPortConfig, byte_msg::AbstractVector{UInt8})

Write `byte_msg` to `sink`.
"""
function display(sink::AZSinks, byte_msg::AbstractVector{UInt8})
    return display(sink.serial_port_config, byte_msg)
end

function display(sink::AlphaZetaSerialPortConfig, byte_msg::AbstractVector{UInt8})
    num_bytes_displayable = sink.num_msg_bytes
    bytes = view(byte_msg, 1:min(num_bytes_displayable, length(byte_msg)))
    extra_bytes = zeros(UInt8, num_bytes_displayable - length(bytes))
    transmission = [0x80, sink.command, sink.address, bytes..., extra_bytes..., 0x8F]
    write_serial_transmission(sink.serial_port, transmission)
    return nothing
end

write_serial_transmission(serial_port, transmission) = write(serial_port, transmission)
write_serial_transmission(::Missing, transmission) = nothing

"""
    display(sink, message::AbstractString)

Write `message` to `sink` after converting to message to bytes via [`
`](@ref).
"""
function display(sink, message::AbstractString)
    message_bytes = text_to_bytes(sink, message)
    return display(sink, message_bytes)
end

"""
    all_alphazeta_sink(serial_port)

Sink for all AlphaZeta boards connected via `serial_port`.
"""
all_alphazeta_sink(serial_port) = AlphaZetaSerialPort(; address=0xFF, serial_port)

"""
    open_srl(; portname, baudrate)

If it already exists, return it; if it doesn't, make
and open it. If no serial port available, return `missing`.
"""
function open_srl(; portname, baudrate)
    key = (portname, baudrate)
    return get!(CURRENTLY_OPEN_SERIAL_PORTS, key) do
        return LibSerialPort.open(portname, baudrate; mode=SP_MODE_WRITE)
    end
end

function open_srl_iff_available(; portname, baudrate)
    try
        return open_srl(; portname, baudrate)
    catch
        @warn "No serial port connected; ensure port name is correct and serial connection is present"
        return missing
    end
end

##########
########## Construct various byte messages
##########

"""
    all_bright(sink)

Set all `sink` to white (or other color) side up.
"""
all_bright(sink) = display(sink, fill(0xFF, num_msg_bytes(sink)))

"""
    all_dark(sink)

Set all `sink` to black side up.
"""
all_dark(sink) = display(sink, zeros(UInt8, num_msg_bytes(sink)))

"""
    clear(sink)

Set [`all_dark`](@ref).
"""
clear(sink) = all_dark(sink)

"""
    flash_reset(sink; pause=0.6)

Set `sink` to to all bright, wait `pause` seconds, then set all to dark.
"""
function flash_reset(sink; pause=0.6)
    all_bright(sink)
    sleep(pause)
    all_dark(sink)
    return nothing
end

#####
##### Text handling
#####

"""
    text_to_bytes(::AZDotsSink, message; font=dots_font)
    text_to_bytes(::AZDigitsSink, message; font=digits_font)

Return `UInt8[]` of `message` converted to all-uppercase byte message in `font`.
"""
function text_to_bytes(::AZDotsSink, message; font=dots_font)
    return _text_to_bytes(message; font=font, space_btwn_chars=true, space_at_end=false)
end

function text_to_bytes(::AZDigitsSink, message; font=digits_font)
    return _text_to_bytes(message; font=font, space_btwn_chars=false, space_at_end=true)
end

function _text_to_bytes(message::AbstractString; font::Dict, space_btwn_chars::Bool,
                        space_at_end::Bool)
    byte_message = UInt8[]
    foreach(uppercase(message)) do character
        x = get(font, character, missing)
        if !ismissing(x)
            append!(byte_message, x)
            space_btwn_chars && append!(byte_message, 0)
        end
    end
    space_at_end && append!(byte_message, 0)
    return byte_message
end

#####
##### Utils
#####

include("fonts.jl")
include("extras.jl")

end
