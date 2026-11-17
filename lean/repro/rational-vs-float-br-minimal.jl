# Nash demand L=1.2: float PAYOFF_TIE_EPS tie includes strategy 1; rational argmax is {3} only.
using GameTCAgentsBR

include(joinpath(@__DIR__, "rational-vs-float-br-search.jl"))

const x = 1.2
const playable = [1, 3]
const mem = 12

function banks_demo()
    codes_a = [1, 3, 2, 2, 3, 3, 2, 1, 3, 2, 2]
    codes_b = [3, 3, 2, 1, 2, 3, 2, 3, 3, 3, 3]
    ba = fill(PLACEHOLDER, mem)
    bb = fill(PLACEHOLDER, mem)
    for (t, c) in enumerate(codes_a)
        ba[t] = Int8(c)
    end
    for (t, c) in enumerate(codes_b)
        bb[t] = Int8(c)
    end
    return [ba, bb]
end

function main()
    Uf = nash_U(x)
    Ur = nash_Ur(Rational{BigInt}(x))
    banks = banks_demo()
    fset, fμ, _ = float_eps_set(Uf, banks, playable)
    rset, rμ, _ = rational_argmax_set(Ur, banks, playable)
    println("Nash L=$x playable=$playable n_obs=22 (two banks × 11)")
    println("float_means=", [fμ[s] for s in playable])
    println("rat_means=", [Float64(rμ[s]) for s in playable])
    println("float_eps_set=$fset rational_argmax=$rset")
    fset == [1, 3] && rset == [3] || error("unexpected sets")
    println("REPRODUCED rational-vs-float-br-eps-larger")
end

main()
