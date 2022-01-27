module FlipBoard

export FlipDots, FlipDigits, scroll_message

abstract type AbstractFlipBoard end

_error_not_yet_implemented(f, t) = error("`$f` not yet implemented for type `::$(typeof(t))`")

function scroll_message(fb::AbstractFlipBoard, msg; kwargs...)
    _error_not_yet_implemented("scroll_message", fb)
end

#####
##### FlipDots board
#####

Base.@kwdef struct FlipDots <: AbstractFlipBoard
    width::Integer=28
    height::Integer=7
end

function scroll_message(::FlipDots, msg)

end

#####
##### FlipDigits board
#####

Base.@kwdef struct FlipDigits <: AbstractFlipBoard
    width::Integer=7
    height::Integer=4
end

#####
##### Utils
#####

end
