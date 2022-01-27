digits_font = Dict(
    ' ' => seg_to_bits([]),
    '-' => seg_to_bits([1]),
    '_' => seg_to_bits([4]),
    '0' => seg_to_bits([2:7]...),
    '1' => seg_to_bits([5, 6]),
    '2' => seg_to_bits([7, 6, 1, 3, 4]),
    '3' => seg_to_bits([7, 6, 1, 5, 4]),
    '4' => seg_to_bits([2, 1, 6, 5]),
    '5' => seg_to_bits([7, 2, 1, 5, 4]),
    '6' => seg_to_bits([7, 2, 3, 4, 5, 1]),
    '7' => seg_to_bits([7, 6, 5]),
    '8' => seg_to_bits([1:7]...),
    '9' => seg_to_bits([1, 2, 4, 5, 6, 7]),
    'A' => seg_to_bits([1, 2, 3, 5, 6, 7]),
    'B' => seg_to_bits([1, 2, 3, 4, 5]),
    'C' => seg_to_bits([1, 3, 4]),
    'D' => seg_to_bits([1, 3, 4, 5, 6]),
    'E' => seg_to_bits([7, 2, 1, 3, 4]),
    'F' => seg_to_bits([7, 2, 1, 3]),
    'G' => seg_to_bits([7, 2, 3, 4, 5]),
    'H' => seg_to_bits([2, 3, 1, 5]),
    'I' => seg_to_bits([5]),
    'J' => seg_to_bits([6, 5, 4, 3]),
    'K' => seg_to_bits([7, 2, 1, 3, 5]),
    'L' => seg_to_bits([2, 3, 4]),
    'M' => seg_to_bits([2, 3, 7, 6, 5]),
    'N' => seg_to_bits([3, 1, 5]),
    'O' => seg_to_bits([1, 3, 4, 5]),
    'P' => seg_to_bits([3, 2, 7, 6, 1]),
    'Q' => seg_to_bits([1, 2, 7, 6, 5]),
    'R' => seg_to_bits([3, 1]),
    'S' => seg_to_bits([2, 1, 5, 4]),
    'T' => seg_to_bits([2, 3, 1, 4]),
    'U' => seg_to_bits([3, 4, 5]),
    'V' => seg_to_bits([2, 3, 4, 5, 6]),
    'W' => seg_to_bits([2, 3, 4, 5, 6, 1]),
    'X' => seg_to_bits([2, 3, 6, 5, 1]),
    'Y' => seg_to_bits([2, 1, 6, 5, 4]),
    'Z' => seg_to_bits([7, 6, 3, 4]),
)

dots_font = Dict(
    ' ' => UInt8.([0]),
    '!' => UInt8.([46]),
    '+' => UInt8.([24,  126, 126,  24,  0]),
    '-' => UInt8.([24,   24,  24,  24,  0]),
    '0' => UInt8.([62,   65,  65,  62,  0]),
    '1' => UInt8.([0,   66,  127, 64,  0]),
    '2' => UInt8.([98,   81,  73,  70,  0]),
    '3' => UInt8.([34,   65,  73,  54,  0]),
    '4' => UInt8.([56,   36,  34, 127, 32]),
    '5' => UInt8.([79,   73,  73,  49,  0]),
    '6' => UInt8.([62,   73,  73,  50,  0]),
    '7' => UInt8.([3,    1,   1, 127,  0]),
    '8' => UInt8.([54,   73,  73,  54,  0]),
    '9' => UInt8.([38,   73,  73,  62,  0]),
    'A' => [0x3C, 0x0A, 0x0A, 0x3C],
    'B' => [0x3E, 0x2A, 0x2A, 0x14],
    'C' => [0x1C, 0x22, 0x22, 0x14],
    'D' => [0x3E, 0x22, 0x22, 0x1C],
    'E' => [0x3E, 0x2A, 0x2A],
    'F' => [0x3E, 0x0A, 0x0A],
    'G' => [0x1C, 0x22, 0x2A, 0x2A],
    'H' => [0x3E, 0x08, 0x08, 0x3E],
    'I' => [0x3E],
    'J' => [0x10, 0x20, 0x20, 0x1E],
    'K' => [0x3E, 0x08, 0x14, 0x22],
    'L' => [0x3E, 0x20, 0x20],
    'M' => [0x3E, 0x04, 0x08, 0x04],
    'N' => [0x3E, 0x04, 0x08, 0x3E],
    'O' => [0x1C, 0x22, 0x22, 0x1C],
    'P' => [0x3E, 0x0A, 0x0A, 0x1C, 0x04],
    'Q' => [0x1C, 0x22, 0x12, 0x2C],
    'R' => [0x3E, 0x0A, 0x1A, 0x24],
    'S' => [0x24, 0x2A, 0x2A, 0x12],
    'T' => [0x02, 0x02, 0x3E, 0x02, 0x02],
    'U' => [0x1E, 0x20, 0x20, 0x1E],
    'V' => [0x06, 0x18, 0x20, 0x18, 0x6],
    'W' => [0x1E, 0x20, 0x1E, 0x20, 0x1E],
    'X' => [0x36, 0x08, 0x08, 0x36],
    'Y' => [0x2E, 0x28, 0x28, 0x1E],
    'Z' => [0x32, 0x2A, 0x2A, 0x26],
)
