# round(Int, n*ratio) as Float64 can differ from round(Int, Rational(n*k,1000)).
using GameTCAgentsBR

_group_a_size(n, r) = min(round(Int, n * r), n ÷ 2)

n, k = 75, 140
ratio = k / 1000
float_sz = _group_a_size(n, ratio)
rational_sz = min(round(Int, Rational(n * k, 1000)), n ÷ 2)

println("n=$n k=$k float_sz=$float_sz rational_sz=$rational_sz")
if float_sz != rational_sz
    println("REPRODUCED group-a-size-rational-mismatch")
else
    error("expected mismatch")
end
