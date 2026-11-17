# Half-up milli (n*k+500)÷1000 can differ from Julia round(Int, n*ratio) (banker's rounding / Float path).
using GameTCAgentsBR

_group_a_size(n, r) = min(round(Int, n * r), n ÷ 2)
_half_up_milli(n, k) = min((n * k + 500) ÷ 1000, n ÷ 2)

n, k = 9995, 300
ratio = k / 1000
julia_sz = _group_a_size(n, ratio)
half_up = _half_up_milli(n, k)

println("n=$n k=$k julia_sz=$julia_sz half_up_milli=$half_up")
if julia_sz != half_up
    println("REPRODUCED group-a-size-halfup-vs-julia")
else
    error("expected half-up vs Julia mismatch at witness")
end