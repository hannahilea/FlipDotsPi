module FlipBoard

export FlipDots, FlipDigits, scroll_message

using LibSerialPort

#TODO: Set up LibSerialPort stuff, entry script, tests
#TODO: Make MockSerialPort for displaying plots of different boards

abstract type AbstractFlipBoard end

_error_not_yet_implemented(f, t) = error("`$f` not yet implemented for type `::$(typeof(t))`")

text_to_bytes(::AbstractFlipBoard, msg::AbstractVector{UInt8}; kwargs...) = msg
function text_to_bytes(fb::AbstractFlipBoard, msg; kwargs...)
    _error_not_yet_implemented("text_to_bytes", fb)
end

#####
##### FlipDots board
#####

Base.@kwdef struct FlipDots <: AbstractFlipBoard
    width::Integer=28
    height::Integer=7
    font::Dict=dots_font
end

text_to_bytes(fb::FlipDots, msg) = _text_to_bytes(msg, fb.font, true, false)

#####
##### FlipDigits board
#####

Base.@kwdef struct FlipDigits <: AbstractFlipBoard
    width::Integer=7
    height::Integer=4
    font::Dict=digits_font
end

text_to_bytes(fb::FlipDigits, msg) = _text_to_bytes(msg, fb.font, false, true)

#####
##### Utils
#####

function seg_to_bits(i_segs::AbstractVector)
    bitstr = zeros(Int, 8)
    foreach(i -> bitstr[i] = 1 , i_segs)
    return parse(UInt8, reverse(join(bitstr)), base=2)
end

function send_transmission(srl, msg::UInt8; num_bytes=0x83, panel_address=0xFF)
    #TODO ensure msg is max bytes OR && it with max bytes so it works
    transmission = [0x80, num_bytes, panel_address, msg...,  0x8F]
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
    for i in 1:loopcount
        wrap_msg = i != loopcount
        for t in 1:length(msg)
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

end