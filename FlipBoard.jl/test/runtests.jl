using Test
using FlipBoard
using Aqua

@testset "FlipBoard.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(FlipBoard; ambiguities=false)
    end

    # dot_board = FlipDots()
    # msg = construct_message(dot_board, "avast")
    # scroll = scroll_message(dot_board, "avast")

    # digit_board = FlipDigits()
    # msg = construct_message(digit_board, "avast")
    # @test_throws ErrorException  scroll_message(digit_board, "woo")
end
