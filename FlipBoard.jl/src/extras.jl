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
