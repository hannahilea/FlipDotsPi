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
_pattern = Bool[1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0]

function flip_bytes(sink)
    display_bytes(sink_dots, bytes)
    return nothing
end

# https://en.wikipedia.org/wiki/Clapping_Music, idea by cpain
function clapping_music(sink_dots, sink_2; pause=0.2)
    display_bytes(sink_dots, text_to_dots_bytes("Steve"))
    sleep(2)
    display_bytes(sink_dots, text_to_dots_bytes("Reich"))
    sleep(2)
    scroll_bytes(sink_dots, text_to_dots_bytes("Clapping Music"); loopcount=1)
    sleep(2)
    clear(sink_dots)
    sleep(2)

    # Play the thing!
    i1 = 1
    i2 = 1
    num_repeats = 4 #12
    num_shifts = 3 #12
    for _ in 1:num_shifts
        for _ in 1:num_repeats, _ in 1:12 # length of pattern
            downbeat = i1 % 12 == 1 #todo: use downbeat to make just first louder;
            # will only work when we update existing state rather than set whole new state
            _pattern[mod1(i1, 12)] && display_bytes(sink_dots, rand(UInt8, 5))
            _pattern[mod1(i2, 12)] && display_bytes(sink_2, rand(UInt8, 1))
            i1 += 1
            i2 += 1
            sleep(pause)
        end
        i2 += 1
    end

    # And roll credits
    scroll_bytes(sink_dots,
                 text_to_dots_bytes("Clapping Music by Steve Reich ... great idea CPayne! :D ");
                 loopcount=1)
    return nothing
end