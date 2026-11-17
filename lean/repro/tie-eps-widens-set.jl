# Epsilon tie set can be strict superset of exact floating-point argmax.
using GameTCAgentsBR

const PAYOFF_TIE_EPS = GameTCAgentsBR.PAYOFF_TIE_EPS

means = [0.5, 0.49999999999999994]
best = maximum(means)
exact = findall(==(best), means)
eps_set = findall(m -> m >= best - PAYOFF_TIE_EPS, means)

if length(eps_set) > length(exact) && exact ⊆ eps_set
    println("exact=$exact eps_set=$eps_set")
    println("REPRODUCED tie-eps-widens-set")
else
    error("expected strict superset counterexample")
end