# Fast slice of search (same logic as rational-vs-float-br-search.jl) to emit minimal.jl
include(joinpath(@__DIR__, "rational-vs-float-br-search.jl"))

function main_lite()
    rng = MersenneTwister(2024)
    stats = SearchStats()
    examples = Dict(:larger => Any[], :smaller => Any[], :symdiff => Any[])
    for n in 2:4
        random_search!(stats, rng, 10, -20:20, n, 20, false, 80, examples)
        length(examples[:larger]) > 0 && break
    end
    for n in 2:4
        random_search!(stats, rng, 100, -30:30, n, 20, false, 40, examples)
        length(examples[:larger]) > 0 && break
    end
    println("lite: cases=$(stats.cases) larger=$(stats.eps_larger) smaller=$(stats.eps_smaller)")
    if isfile(joinpath(@__DIR__, "rational-vs-float-br-minimal.jl"))
        println("wrote minimal.jl")
    else
        println("no counterexample")
    end
    return nothing
end

main_lite()
