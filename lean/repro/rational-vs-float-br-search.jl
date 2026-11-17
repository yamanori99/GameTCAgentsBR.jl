# Compare Float64+PAYOFF_TIE_EPS tie sets vs exact Rational{BigInt} argmax (same matrix decimals).
using Random
using GameTCAgentsBR

const PAYOFF_TIE_EPS = GameTCAgentsBR.PAYOFF_TIE_EPS
const PLACEHOLDER = GameTCAgentsBR.MEMORY_PLACEHOLDER

mutable struct SearchStats
    cases::Int
    agree::Int
    eps_larger::Int
    eps_smaller::Int
    eps_symdiff::Int
end

SearchStats() = SearchStats(0, 0, 0, 0, 0)

function matrix_from_grid(nums::Matrix{Int}, q::Int)
    n, _ = size(nums)
    Uf = Matrix{Float64}(undef, n, n)
    Ur = Matrix{Rational{BigInt}}(undef, n, n)
    for i in 1:n, j in 1:n
        r = Rational{BigInt}(nums[i, j], q)
        Ur[i, j] = r
        Uf[i, j] = Float64(r)
    end
    return Uf, Ur
end

function float_eps_set(U::Matrix{Float64}, banks::Vector{Vector{Int8}}, playable::Vector{Int})
    n = size(U, 1)
    payoffs = zeros(Float64, n)
    n_obs = 0
    for bank in banks
        for code in bank
            code == PLACEHOLDER && continue
            j = Int(code)
            for s in playable
                payoffs[s] += U[s, j]
            end
            n_obs += 1
        end
    end
    n_obs > 0 && (payoffs ./= n_obs)
    maxp = maximum(s -> payoffs[s], playable)
    return sort!(collect(Int, s for s in playable if payoffs[s] >= maxp - PAYOFF_TIE_EPS)), payoffs, n_obs
end

function rational_argmax_set(Ur::Matrix{Rational{BigInt}}, banks::Vector{Vector{Int8}}, playable::Vector{Int})
    n = size(Ur, 1)
    payoffs = [zero(Rational{BigInt}) for _ in 1:n]
    n_obs = 0
    for bank in banks
        for code in bank
            code == PLACEHOLDER && continue
            j = Int(code)
            for s in playable
                payoffs[s] += Ur[s, j]
            end
            n_obs += 1
        end
    end
    if n_obs > 0
        for s in playable
            payoffs[s] /= n_obs
        end
    end
    maxp = maximum(payoffs[s] for s in playable)
    return sort!(collect(Int, s for s in playable if payoffs[s] == maxp)), payoffs, n_obs
end

function write_minimal_repro!(nums, q, banks, playable, fset, rset)
    path = joinpath(@__DIR__, "rational-vs-float-br-minimal.jl")
    return open(path, "w") do io
        println(io, "# Auto-generated: float eps set strictly larger than rational argmax.")
        println(io, "using GameTCAgentsBR")
        println(io, "include(joinpath(@__DIR__, \"rational-vs-float-br-search.jl\"))")
        println(io, "const nums = ", nums)
        println(io, "const q = ", q)
        println(io, "const playable = ", playable)
        banks_lit = [[Int(c) for c in bank] for bank in banks]
        println(io, "function banks_vec()")
        println(io, "    ba = fill(GameTCAgentsBR.MEMORY_PLACEHOLDER, ", length(banks[1]), ")")
        for (t, c) in enumerate(banks[1])
            c != PLACEHOLDER && println(io, "    ba[$t] = Int8($c)")
        end
        println(io, "    return [ba]")
        println(io, "end")
        println(
            io, """
            function main()
                Uf, Ur = matrix_from_grid(nums, q)
                banks = banks_vec()
                fset, fμ, _ = float_eps_set(Uf, banks, playable)
                rset, rμ, _ = rational_argmax_set(Ur, banks, playable)
                println("float_means=", [fμ[s] for s in playable])
                println("rat_means=", [Float64(rμ[s]) for s in playable])
                println("float_eps_set=\$fset rational_argmax=\$rset")
                length(fset) > length(rset) || error("not a counterexample")
                println("REPRODUCED rational-vs-float-br-eps-larger")
            end
            main()
            """
        )
    end
end

function compare_once!(stats::SearchStats, Uf, Ur, banks, playable, examples, nums = nothing, q = nothing)
    fset, _, _ = float_eps_set(Uf, banks, playable)
    rset, _, _ = rational_argmax_set(Ur, banks, playable)
    stats.cases += 1
    if fset == rset
        stats.agree += 1
        return
    end
    ex = (; fset, rset, playable, banks)
    return if length(fset) > length(rset)
        stats.eps_larger += 1
        if isempty(examples[:larger])
            nums !== nothing && write_minimal_repro!(nums, q, banks, playable, fset, rset)
        end
        push!(examples[:larger], ex)
    elseif length(fset) < length(rset)
        stats.eps_smaller += 1
        push!(examples[:smaller], ex)
    else
        stats.eps_symdiff += 1
        push!(examples[:symdiff], ex)
    end
end

function random_bank(mem_len::Int, n_obs::Int, n_strat::Int, rng::AbstractRNG)
    bank = fill(PLACEHOLDER, mem_len)
    for t in 1:n_obs
        bank[t] = Int8(rand(rng, 1:n_strat))
    end
    return bank
end

function all_playable_subsets(n::Int)
    return [collect(s for s in 1:n if (mask >> (s - 1)) & 1 == 1) for mask in 1:(2^n - 1)]
end

function nash_U(x::Float64)
    H = 10.0 - x
    return [x x x; 5.0 5.0 0.0; H 0.0 0.0]
end

function nash_Ur(x::Rational{BigInt})
    H = Rational(10) - x
    return [x x x; 5 5 0; H 0 0]
end

function random_search!(stats, rng, q, k_range, n_strat, mem, tc, samples, examples)
    for _ in 1:samples
        nums = rand(rng, k_range, n_strat, n_strat)
        Uf, Ur = matrix_from_grid(nums, q)
        for playable in all_playable_subsets(n_strat)
            for n_obs in 1:mem
                for _ in 1:4
                    if tc
                        banks = [random_bank(mem, n_obs, n_strat, rng)]
                    else
                        banks = [random_bank(mem, n_obs, n_strat, rng), random_bank(mem, n_obs, n_strat, rng)]
                    end
                    compare_once!(stats, Uf, Ur, banks, playable, examples, nums, q)
                end
            end
        end
    end
    return
end

function nash_search!(stats::SearchStats, rng, examples)
    xs = [0.5:0.5:4.5...; [xi / 10 for xi in 5:45]...]
    for xf in xs
        Uf = nash_U(xf)
        xr = Rational{BigInt}(xf)
        Ur = nash_Ur(xr)
        for playable in all_playable_subsets(3)
            for mem in 1:20
                for n_obs in 1:mem
                    for tc in (false, true)
                        for _ in 1:8
                            banks = tc ? [random_bank(mem, n_obs, 3, rng)] :
                                [random_bank(mem, n_obs, 3, rng), random_bank(mem, n_obs, 3, rng)]
                            compare_once!(stats, Uf, Ur, banks, playable, examples)
                        end
                    end
                end
            end
        end
    end
    return
end

function hunt_eps_smaller!(stats, examples)
    rng = MersenneTwister(99)
    for _ in 1:50_000
        q = rand(rng, (10, 100))
        n = rand(rng, 2:4)
        nums = rand(rng, -30:30, n, n)
        mem = rand(rng, 1:40)
        Uf, Ur = matrix_from_grid(nums, q)
        for playable in all_playable_subsets(n)
            for n_obs in 1:mem
                banks = if rand(Bool)
                    [random_bank(mem, n_obs, n, rng)]
                else
                    [random_bank(mem, n_obs, n, rng), random_bank(mem, n_obs, n, rng)]
                end
                compare_once!(stats, Uf, Ur, banks, playable, examples, nums, q)
            end
        end
    end
    return
end

function main()
    rng = MersenneTwister(2024)
    stats = SearchStats()
    examples = Dict(:larger => Any[], :smaller => Any[], :symdiff => Any[])

    println("=== 0.1 grid, randomized ===")
    for n in 2:5
        for tc in (false, true)
            mem = tc ? 20 : 40
            random_search!(stats, rng, 10, -20:20, n, mem, tc, 400, examples)
        end
    end

    println("=== 0.01 grid, randomized ===")
    for n in 2:5
        for tc in (false, true)
            mem = tc ? 20 : 40
            random_search!(stats, rng, 100, -50:50, n, mem, tc, 250, examples)
        end
    end

    println("=== Nash demand matrices ===")
    nash_search!(stats, rng, examples)

    println("=== Targeted eps_smaller hunt ===")
    hunt_eps_smaller!(stats, examples)

    println("\n--- Summary ---")
    println("cases=$(stats.cases) agree=$(stats.agree)")
    println("eps_larger=$(stats.eps_larger) eps_smaller=$(stats.eps_smaller) symdiff=$(stats.eps_symdiff)")

    return if stats.eps_smaller > 0
        println("\nREPRODUCED rational-vs-float-br-eps-smaller")
    elseif stats.eps_larger > 0
        println("\nREPRODUCED rational-vs-float-br-eps-larger")
    else
        println("\nREPRODUCED rational-vs-float-br-no-mismatch")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
