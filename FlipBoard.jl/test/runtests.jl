using FlipBoard
using Test

@testset "FlipBoard.jl" begin
    dots = FlipDots(28, 7)
    digits = FlipDigits(7, 28)

    @test_throws ErrorException scroll_message(dots, "woo")
    @test_throws ErrorException  scroll_message(digits, "woo")
end
