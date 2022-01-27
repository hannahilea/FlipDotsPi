# Rewrite of https://raw.githubusercontent.com/vwyf/vwyf_door_sensor/2a281e274d4d14e7d020158d55fd5dc94bfccd13/flipdot_demon.py

### flipdot display
###
### 0:1200
### 1:2400
### 2:4800
### 3:9600 <--- this should be set, means 1-ON 2-ON 3-OFF
### 4:19200
### 5:38200 <-- do not use, most probably wrong speed programmed
### 6: 9600
### 7: 9600
### 8: 9600
###
### 0x80 beginning
###___________________
### 0x81 - 112 bytes / no refresh / C+3E
### 0x82 - refresh
### 0x83 - 28 bytes of data / refresh / 2C
### 0x84 - 28 bytes of data / no refresh / 2C
### 0x85 - 56 bytes of data / refresh / C+E
### 0x86 - 56 bytes of data / no refresh / C+E
### ---------------------------------------
### address or 0xFF for all
### data ... 1 to number of data buytes
### 0x8F end

using LibSerialPort
using ArgParse

const DEFAULT_PANEL_WIDTH = 28

const DEFAULT_PORTNAME = "/dev/ttyS0"  # "/dev/serial0"
const DEFAULT_BAUDRATE = 57600
const DEFAULT_LOOPCOUNT = 1
const DEFAULT_SCROLLPAUSE = 0.3f0
# const DEFAULT_DISPLAYTYPE = "dots"

# font = Dict(
#     ' ' => UInt8.([0]),
#     '!' => UInt8.([46]),
#     '+' => UInt8.([24,  126, 126,  24,  0]),
#     '-' => UInt8.([24,   24,  24,  24,  0]),
#     '0' => UInt8.([62,   65,  65,  62,  0]),
#     '1' => UInt8.([0,   66,  127, 64,  0]),
#     '2' => UInt8.([98,   81,  73,  70,  0]),
#     '3' => UInt8.([34,   65,  73,  54,  0]),
#     '4' => UInt8.([56,   36,  34, 127, 32]),
#     '5' => UInt8.([79,   73,  73,  49,  0]),
#     '6' => UInt8.([62,   73,  73,  50,  0]),
#     '7' => UInt8.([3,    1,   1, 127,  0]),
#     '8' => UInt8.([54,   73,  73,  54,  0]),
#     '9' => UInt8.([38,   73,  73,  62,  0]),
#     'A' => [0x3C, 0x0A, 0x0A, 0x3C],
#     'B' => [0x3E, 0x2A, 0x2A, 0x14],
#     'C' => [0x1C, 0x22, 0x22, 0x14],
#     'D' => [0x3E, 0x22, 0x22, 0x1C],
#     'E' => [0x3E, 0x2A, 0x2A],
#     'F' => [0x3E, 0x0A, 0x0A],
#     'G' => [0x1C, 0x22, 0x2A, 0x2A],
#     'H' => [0x3E, 0x08, 0x08, 0x3E],
#     'I' => [0x3E],
#     'J' => [0x10, 0x20, 0x20, 0x1E],
#     'K' => [0x3E, 0x08, 0x14, 0x22],
#     'L' => [0x3E, 0x20, 0x20],
#     'M' => [0x3E, 0x04, 0x08, 0x04],
#     'N' => [0x3E, 0x04, 0x08, 0x3E],
#     'O' => [0x1C, 0x22, 0x22, 0x1C],
#     'P' => [0x3E, 0x0A, 0x0A, 0x1C, 0x04],
#     'Q' => [0x1C, 0x22, 0x12, 0x2C],
#     'R' => [0x3E, 0x0A, 0x1A, 0x24],
#     'S' => [0x24, 0x2A, 0x2A, 0x12],
#     'T' => [0x02, 0x02, 0x3E, 0x02, 0x02],
#     'U' => [0x1E, 0x20, 0x20, 0x1E],
#     'V' => [0x06, 0x18, 0x20, 0x18, 0x6],
#     'W' => [0x1E, 0x20, 0x1E, 0x20, 0x1E],
#     'X' => [0x36, 0x08, 0x08, 0x36],
#     'Y' => [0x2E, 0x28, 0x28, 0x1E],
#     'Z' => [0x32, 0x2A, 0x2A, 0x26],
# )

# all_bright = [
#     0x80,  # header
#     0x83,  # 28 bytes refresh
#     0xFF,  # address
#     0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, # 28 bytes data
#     0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F,
#     0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F,
#     0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F,
#     0x8F # EOT
# ]

# all_dark = [
#     0x80,  #header
#     0x83,  # 28 bytes refresh
#     0xFF,  # address
#     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, # 28 bytes data
#     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
#     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
#     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
#     0x8F # EOT
# ]

# hello_world = [
#     0x80,  #header
#     0x83,  # 28 bytes refresh
#     0xFF,  # address
#     digitsfont['1'], digitsfont['2'], digitsfont['8'], digitsfont['8'], # 28 bytes data
#     0x00, 0x00, 0x00, #0x00, 0x00, 0x00, 0x00,
#     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
#     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
#     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
#     0x8F # EOT
# ]

# digitsfont = Dict(
#     ' ' => seg_to_bits([]),
#     '-' => seg_to_bits([1]),
#     '_' => seg_to_bits([4]),
#     '0' => seg_to_bits([2:7]...),
#     '1' => seg_to_bits([5, 6]),
#     '2' => seg_to_bits([7, 6, 1, 3, 4]),
#     '3' => seg_to_bits([7, 6, 1, 5, 4]),
#     '4' => seg_to_bits([2, 1, 6, 5]),
#     '5' => seg_to_bits([7, 2, 1, 5, 4]),
#     '6' => seg_to_bits([7, 2, 3, 4, 5, 1]),
#     '7' => seg_to_bits([7, 6, 5]),
#     '8' => seg_to_bits([1:7]...),
#     '9' => seg_to_bits([1, 2, 4, 5, 6, 7]),
#     'A' => seg_to_bits([1, 2, 3, 5, 6, 7]),
#     'B' => seg_to_bits([1, 2, 3, 4, 5]),
#     'C' => seg_to_bits([1, 3, 4]),
#     'D' => seg_to_bits([1, 3, 4, 5, 6]),
#     'E' => seg_to_bits([7, 2, 1, 3, 4]),
#     'F' => seg_to_bits([7, 2, 1, 3]),
#     'G' => seg_to_bits([7, 2, 3, 4, 5]),
#     'H' => seg_to_bits([2, 3, 1, 5]),
#     'I' => seg_to_bits([5]),
#     'J' => seg_to_bits([6, 5, 4, 3]),
#     'K' => seg_to_bits([7, 2, 1, 3, 5]),
#     'L' => seg_to_bits([2, 3, 4]),
#     'M' => seg_to_bits([2, 3, 7, 6, 5]),
#     'N' => seg_to_bits([3, 1, 5]),
#     'O' => seg_to_bits([1, 3, 4, 5]),
#     'P' => seg_to_bits([3, 2, 7, 6, 1]),
#     'Q' => seg_to_bits([1, 2, 7, 6, 5]),
#     'R' => seg_to_bits([3, 1]),
#     'S' => seg_to_bits([2, 1, 5, 4]),
#     'T' => seg_to_bits([2, 3, 1, 4]),
#     'U' => seg_to_bits([3, 4, 5]),
#     'V' => seg_to_bits([2, 3, 4, 5, 6]),
#     'W' => seg_to_bits([2, 3, 4, 5, 6, 1]),
#     'X' => seg_to_bits([2, 3, 6, 5, 1]),
#     'Y' => seg_to_bits([2, 1, 6, 5, 4]),
#     'Z' => seg_to_bits([7, 6, 3, 4]),
# )

# function seg_to_bits(i_segs::AbstractVector)
#     bitstr = zeros(Int, 8)
#     foreach(i -> bitstr[i] = 1 , i_segs)
#     return parse(UInt8, reverse(join(bitstr)), base=2)
# end

# function show_slice(t, srl, msg; wrap_msg=false)
#     transmission = [
#         0x80, #header
#         0x83, # 28 bytes, refresh
#         0xFF, # panel address
#     ]
#     for i in t:(t + 27)
#         if i <= length(msg)
#             append!(transmission, msg[i])
#         elseif wrap_msg
#             append!(transmission, msg[i % length(msg)])
#         else
#             append!(transmission, 0x00)
#         end
#     end
#     append!(transmission, 0x8F) # EOT
#     write(srl, transmission)
# end

# function construct_question(message; panel_width=DEFAULT_PANEL_WIDTH, displaytype="dots")
#     # loop over question string and add columns to question
#     font_dict = font
#     add_spacer = true
#     if displaytype != "dots"
#         font_dict = digitsfont
#         add_spacer = false
#     end
#     message = uppercase(message) # TODO: when supporting lowercase on dots board, move into digits only
#     question = UInt8[]
#     for c in message
#         if c in keys(font_dict)
#             append!(question, font_dict[c])
#             add_spacer && append!(question, 0) # put space between letters
#         end
#     end

#     # if question is fewer than 28 columns pad it out with spaces
#     while length(question) < panel_width
#         append!(question, font_dict[' '])
#     end
#     displaytype != "dots" && append!(question, font_dict[' '])
#     return question
# end

# function flash_display(srl, sleep_sec=0.5)
#     write(srl, all_bright)
#     sleep(sleep_sec)
#     write(srl, all_dark)
#     sleep(sleep_sec)
#     return nothing
# end

# function scroll_message(message; loopcount::Int=DEFAULT_LOOPCOUNT, baudrate=DEFAULT_BAUDRATE,
#                         portname=DEFAULT_PORTNAME, scrollpause=DEFAULT_SCROLLPAUSE,
#                         panel_width=DEFAULT_PANEL_WIDTH, displaytype=DEFAULT_DISPLAYTYPE, verbose=false)
#     # question = construct_question(message; panel_width, displaytype)
#     # verbose && println("Msg to display: $question")
#     # LibSerialPort.open(portname, baudrate) do srl
#         verbose && println("Displaying message")

#         loopcount == 0 && show_slice(1, srl, question; wrap_msg=false)

#         for i in 1:loopcount
#             wrap_msg = i != loopcount
#             for t in 1:length(question)
#                 show_slice(t, srl, question; wrap_msg)
#                 sleep(scrollpause)
#             end
#         end
#     end
# end

#####
## IFF running from the REPL
#####

function parse_commandline()
    s = ArgParseSettings(; description="Scroll a message on a FlipDots display.")
    @add_arg_table s begin
        "--loopcount"
            help = "Number of times to scroll the message"
            arg_type = Int
            default = DEFAULT_LOOPCOUNT
        "--baudrate"
            help = "Baudrate of the display"
            arg_type = Int
            default = DEFAULT_BAUDRATE
        "--portname"
            help = "Serial port name for the display"
            arg_type = String
            default = DEFAULT_PORTNAME
        "--scrollpause"
            help = "Pause between scroll updates (sec)"
            arg_type = Float32
            default = DEFAULT_SCROLLPAUSE
        "--panelwidth"
            help = "Width of the display (# dots)"
            arg_type = Int
            default = DEFAULT_PANEL_WIDTH
        "--displaytype"
            help = "Font option: flipdots display (`dots`) or flipdigits display (`digits`)"
            arg_type = String
            default = DEFAULT_displaytype
        "--verbose"
            help = "Show additional debug statements"
            action = :store_true
        "message"
            help = "Message to be displayed; supports uppercase letters, numbers, and limited symbols." #TODO list symbols
            required = true
    end
    return parse_args(s)
end

# ...when running as script (not from REPL):
if !isinteractive()
    d = parse_commandline()
    args = NamedTuple{Tuple(Symbol.(keys(d)))}(values(d))
    args.verbose && println("Parsed args: $args")
    scroll_message(args.message; loopcount=args.loopcount, baudrate=args.baudrate,
                   portname=args.portname, scrollpause=args.scrollpause, verbose=args.verbose,
                   panel_width=args.panelwidth, displaytype=args.displaytype)
end

#####
## Fun snippets
#####

function drumbeat_snippet(pause=.1)
    for i in 1:16
        scroll_message("1 1 1 1 "; loopcount=0, displaytype="digits")
        sleep(pause)
        scroll_message("1 1    1 "; loopcount=0, displaytype="digits")
        sleep(pause)
        scroll_message(" 1     1 "; loopcount=0, displaytype="digits")
        sleep(pause)
        scroll_message("      "; loopcount=0, displaytype="digits")
        sleep(pause)
    end
end

function drumbeat_snippet2(pause=.1)
    for i in 1:16
        scroll_message("1 1 1 1 1 1 1 1 1 1 1 1 1 1"; loopcount=0, displaytype="digits")
        sleep(pause)
        scroll_message("1   1 1 1   1 1 1 1   1 1 1"; loopcount=0, displaytype="digits")
        sleep(pause)
        scroll_message("1   1 1 1             1 1 1"; loopcount=0, displaytype="digits")
        sleep(pause)
        scroll_message(""; loopcount=0, displaytype="digits")
        sleep(pause)
    end
end