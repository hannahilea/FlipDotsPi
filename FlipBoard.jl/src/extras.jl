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
end

#####
##### Sequency rhythms
#####

const rhythm1 = ["1 1 1 1 ", "1 1    1 ", " 1     1 ", "      "]

const rhythm2 = ["1 1 1 1 1 1 1 1 1 1 1 1 1 1",
                 "1   1 1 1   1 1 1 1   1 1 1",
                 "1   1 1 1             1 1 1",
                 ""]

# TODO helper for no srl
function drumbeat_snippet2(srl, board, phrases=rhythm1; pause=.1)
    for i in 1:16
        for p in phrases
            send_transmission(srl, text_to_bytes(board, p))
            sleep(pause)
        end
    end
end
