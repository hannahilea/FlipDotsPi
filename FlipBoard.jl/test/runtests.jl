using Test
using FlipBoard
using Aqua

@testset "FlipBoard.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(FlipBoard; ambiguities=false)
    end
end
