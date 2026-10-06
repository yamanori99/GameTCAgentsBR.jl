"""
GameTCAgentsBR.jl model tests.

Run with: julia --project=. -e 'using Pkg; Pkg.test()'
"""

using GameTCAgentsBR
using Random
using Test

include("common.jl")

@testset "GameTCAgentsBR.jl" begin
    include("test_model.jl")
    include("test_demo.jl")
    include("test_analysis.jl")
end
