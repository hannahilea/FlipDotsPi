##########
########## Fun stuff
##########

#todo: rewrite for ring buffer
function scroll_bytes(sink, msg::AbstractVector{UInt8}; loopcount=2, scrollpause=0.1) #TODO defaults
    for i in 1:loopcount, t in 1:length(msg)
        wrap_msg = i != loopcount
        slice = zeros(UInt8, sink.num_msg_bytes)
        for (i_slice, i_msg) in enumerate(t:(t + sink.num_msg_bytes - 1))
            if i_msg <= length(msg)
                slice[i_slice] = msg[i_msg]
            elseif wrap_msg
                slice[i_slice] = msg[i_msg % length(msg) + 1]
            end
        end
        display_bytes(sink, slice)
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
function drumbeat_snippet2(srl, board, phrases=rhythm1; pause=0.1)
    for i in 1:16
        for p in phrases
            send_transmission(srl, text_to_bytes(board, p))
            sleep(pause)
        end
    end
end

#####
##### Sequency rhythms
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
                display_bytes(sink_dots, rand(0x00:0x7F, bytes_update_dots))
            clap_pattern[mod1(i2, 12)] &&
                display_bytes(sink_digits, rand(0x00:0x7F, bytes_update_digits))
            i1 += 1
            i2 += 1
            sleep(pause)
        end
        i2 += 1
    end
end

# https://en.wikipedia.org/wiki/Clapping_Music, idea by cpain
# traditional pause (bpm = 160-180) is 0.1667-0.1875 sec
function clapping_music(sink_dots, sink_digits; pause=0.1875)
    # intro
    display_bytes(sink_dots, text_to_dots_bytes("Clapping"))
    display_bytes(sink_digits, text_to_digits_bytes("music  Steve  Reich  1972"))
    sleep(3)
    clear(sink_dots)
    clear(sink_digits)
    sleep(2)

    # Play the thing!
    _clapping_music(sink_dots, sink_digits; pause, num_repeats=4)

    # And roll credits
    display_bytes(sink_digits, text_to_digits_bytes("       Steve  Reich  1972"))
    scroll_bytes(sink_dots, text_to_dots_bytes("Clapping Music"); loopcount=1)
    display_bytes(sink_dots, text_to_dots_bytes("Clapping"))
    display_bytes(sink_digits, text_to_digits_bytes("music  Steve  Reich  1972"))
    return nothing
end