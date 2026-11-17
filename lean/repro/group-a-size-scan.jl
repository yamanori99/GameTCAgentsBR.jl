# Summary scan: Float vs Rational on k/1000 grid (n≤10_000).
using GameTCAgentsBR

_group_a_size(n, r) = min(round(Int, n * r), n ÷ 2)
exact(n, k) = min(round(Int, Rational(n * k, 1000)), n ÷ 2)

let mismatches = 0
    for n in 1:10_000, k in 1:500
        julia = _group_a_size(n, k / 1000)
        rat = exact(n, k)
        mismatches += (julia != rat)
    end
    println("float_vs_rational_mismatches=$mismatches")
    println("REPRODUCED group-a-size-scan-summary")
end