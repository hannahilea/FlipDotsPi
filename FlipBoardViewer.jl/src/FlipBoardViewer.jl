module FlipBoardViewer

# Add functions that you want to be visible w/out namespace prefix
# e.g. "plot_matrix_as_dots(...)` instead of `FlipBoardViewer.plot_matrix_as_dots`
export plot_matrix_as_dots

using FlipBoard

const DEFAULT_DIGIT_BOARD_WIDTH = 7
const DEFAULT_DIGIT_BOARD_HEIGHT = 4
const DEFAULT_DOTS_BOARD_WIDTH = 7
const DEFAULT_DOTS_BOARD_HEIGHT = 4

function bytes_to_matrix(byte_array_message)
    # byte_array_message = byte_array_message[4:end-1]
    img = zeros(Int8, 7, 28) #TODO now it only handles 28 size message
    for i_byte in 1:length(byte_array_message)
        byte = byte_array_message[i_byte]
        s = string(byte; base=2)
        s = lpad(s, 7, '0')
        # @info s
        for i_bit in 1:length(s)
            img[8 - i_bit, i_byte] = parse(Int8, s[i_bit])
        end
    end
    return img
end

img = bytes_to_matrix(byte_array_message)

function matrix_to_bytes(img)
    byte_array_message = Array{UInt8}(undef, size(img, 2))
    for i_col in 1:size(img, 2)
        column = img[:, i_col]
        bit_string = join(column)
        reversed = reverse(bit_string)
        parsed = parse(Int, reversed; base=2)
        byte_array_message[i_col] = UInt8(parsed)
    end
    return byte_array_message
end

msg = "HELLO"
byte_array_message = make_message(msg)
img = bytes_to_matrix(byte_array_message)
test = matrix_to_bytes(img)

x = 1:28
y = 1:7
image(x, y, rotr90(img))

#TODO make this plot white on black background
function plot_matrix_as_dots(img; panel_width=DEFAULT_DOTS_BOARD_WIDTH,
                             panel_height=DEFAULT_DOTS_BOARD_HEIGHT)
    f = Figure(; resolution=(2800, 800))
    ax = Axis(f[1, 1])
    xs = repeat((1:panel_width), panel_height)
    ys = repeat((1:panel_height); inner=panel_width)
    img_colors = map(pixel -> pixel == 1 ? :black : :white, rotr90(img))
    scatter!(xs, ys; markersize=85, color=vec(img_colors), strokecolor=:black,
             strokewidth=3)
    return current_figure()
end
plot_matrix_as_dots(img)

function plot_seven_seg(x, y)
    # 0, 3
    MARKER_SIZE = 75
    #horizontal lines
    bottom_line = [0.5, 0]
    middle_line = [0.5, 1]
    top_line = [0.5, 2]
    horiz = hcat(bottom_line, middle_line, top_line)
    scatter!(x .+ horiz[1, :], y .+ horiz[2, :]; marker=:hline,
             markersize=MARKER_SIZE * 1.3, color=:black)

    #vertical lines
    left_top = [0, 1.5]
    right_top = [1, 1.5]
    left_bottom = [0, 0.5]
    right_bottom = [1, 0.5]
    vert = hcat(left_top, right_top, left_bottom, right_bottom)
    scatter!(x .+ vert[1, :], y .+ vert[2, :]; marker=:vline, markersize=MARKER_SIZE,
             color=:black)
    return current_figure()
end

function make_flip_digits_plot()
    # f = Figure(; resolution = (800, 1600))
    # ax = Axis(f[1, 1])

    y_loc = [0, 3, 6, 9]
    # y_loc = [0:DIGITS_HEIGHT-1] .* (DIGITS_HEIGHT - 1)
    x_loc = [0, 2, 4, 6, 8, 10, 12]
    # x_loc = [0:DIGITS_WIDTH-1] .* (DIGITS_HEIGHT - 1)

    for i_digits_x in x_loc
        for i_digits_y in y_loc
            plot_seven_seg(i_digits_x, i_digits_y)
        end
    end
    return current_figure()
end

end