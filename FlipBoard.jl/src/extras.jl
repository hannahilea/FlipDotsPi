##########
########## Fun stuff
##########

function scroll_message(sink, message; kwargs...)
    return scroll_bytes(sink, text_to_bytes(sink, message); kwargs...)
end

function scroll_bytes(sink, message::AbstractVector{UInt8}; loopcount=2, scrollpause=0.1) #TODO defaults
    # Allocate full message up front. Could be a bit ridiculous if the loopcount is high, but....so it goes. 
    looped_message = repeat(message, loopcount)
    for i in 1:length(looped_message)
        i_end = minimum([i+num_msg_bytes(sink), length(looped_message)])
        slice = @view looped_message[i:i_end]
        write_to_sink(sink, slice)
        sleep(scrollpause)
    end
    return nothing
end

#####
##### Sequency rhythms
#####

const rhythm1 = ["1 1 1 1 ", "1 1    1 ", " 1     1 ", "      "]

const rhythm2 = ["1 1 1 1 1 1 1 1 1 1 1 1 1 1", "1   1 1 1   1 1 1 1   1 1 1",
                 "1   1 1 1             1 1 1", ""]

# TODO helper for no srl
function drumbeat_snippet(sink, phrases=rhythm1; pause=0.1)
    for _ in 1:16
        for p in phrases
            write_to_sink(sink, text_to_bytes(sink, p))
            sleep(pause)
        end
    end
end

#####
##### Clapping music
#####

function _clapping_music(sink_dots, sink_digits; pause=0.1875,
                         clap_pattern=Bool[1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0],
                         num_repeats=12, num_shifts=13, bytes_update_dots=28,
                         bytes_update_digits=7)
    i1 = 1
    i2 = 1
    for _ in 1:num_shifts
        for _ in 1:num_repeats, _ in 1:12 # length of pattern
            clap_pattern[mod1(i1, 12)] &&
                write_to_sink(sink_dots, rand(0x00:0x7F, bytes_update_dots))
            clap_pattern[mod1(i2, 12)] &&
                write_to_sink(sink_digits, rand(0x00:0x7F, bytes_update_digits))
            i1 += 1
            i2 += 1
            sleep(pause)
        end
        i2 += 1
    end
end

# https://en.wikipedia.org/wiki/Clapping_Music, idea by cpain
# traditional pause (bpm = 160-180) is 0.1667-0.1875 sec
function clapping_music(sink_dots, sink_digits; kwargs...)
    # intro
    write_to_sink(sink_dots, text_to_dots_bytes("Clapping"))
    write_to_sink(sink_digits, text_to_digits_bytes("music  Steve  Reich  1972"))
    sleep(3)
    clear(sink_dots)
    clear(sink_digits)
    sleep(2)

    # Play the thing!
    _clapping_music(sink_dots, sink_digits; kwargs...)

    # And roll credits
    write_to_sink(sink_digits, text_to_digits_bytes("       Steve  Reich  1972"))
    scroll_bytes(sink_dots, text_to_dots_bytes("Clapping Music"); loopcount=1)
    write_to_sink(sink_dots, text_to_dots_bytes("Clapping"))
    write_to_sink(sink_digits, text_to_digits_bytes("music  Steve  Reich  1972"))
    return nothing
end
