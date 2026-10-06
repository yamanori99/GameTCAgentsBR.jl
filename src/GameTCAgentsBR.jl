"""
GameTCAgentsBR.jl — simulation of pairwise play with group-specific strategy memory.

GameTCAgentsBR.jl simulates repeated pairwise play in a finite population.
Each agent records opponent strategies in a finite memory and can keep a separate
memory for each opponent group. A run takes a payoff and a configuration and
returns the memories after the trials. Other pairwise payoffs can be supplied.
The simulator was designed to configure the Nash demand game, and the demos
and tests use that game.

# Extended From

This implementation builds upon the following works (in order of importance):

1. O'Connor, C. (2017). The cultural Red King effect. The Journal of Mathematical Sociology, 41(3), 155–171.
   https://doi.org/10.1080/0022250X.2017.1335723
   ** Primary code base (code provided by the author) **

2. O'Connor, C. (2019). The Origins of Unfairness: Social Categories and Cultural Evolution.
   Oxford University Press. (Theoretical foundation)

3. Bruner, J. P. (2017). Minority (dis)advantage in population games. Synthese, 196(1), 413–427.
   https://doi.org/10.1007/s11229-017-1487-8
   (Cultural Red King effect - evolutionary game theory)

4. Cochran, C., & O'Connor, C. (2019). Inequality and inequity in the emergence of conventions.
   Politics, Philosophy & Economics, 18(3), 264–281.
   https://doi.org/10.1177/1470594X19828371
   (Implementation reference - extended Nash demand game ABM)

# Public surface

Experiments vary conditions through `PairGame` and `SimConfig`, run them with
`run_simulation` and `run_batch`, and observe each `TrialResult` plus
`count_final_strategies` and `compute_payoff_outcome`.

# Quick Start

```julia
using GameTCAgentsBR

config = SimConfig(
    game = PairGame(
        ["L", "M", "H"],  # Group A strategies
        ["L", "M", "H"],  # Group B strategies
        [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],  # A's payoff, opponent A
        [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],  # A's payoff, opponent B
        [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],  # B's payoff, opponent B
        [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],  # B's payoff, opponent A
    ),
    num_agents = 500,  # population size
    group_a_ratio = 0.3,  # Group A: minority (30%)
    type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 1.0,  # all agents use opponent-group-specific memory
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = NoOverride(),
    matching = OnePair(),
    num_initializations = 10000,  # independent trials
    steps_per_initialization = 200000,  # steps per trial
    random_seed = nothing,
)

results = run_batch(config)

println(results.b_remembers_a_trial_count)
println(results.a_remembers_b_trial_count)
println(results.a_remembers_a_trial_count)
println(results.b_remembers_b_trial_count)
```
"""
module GameTCAgentsBR

using ArgCheck
using Printf
using Random

include("model.jl")
include("batch.jl")
include("analysis.jl")

# model.jl
export PairGame, SimConfig, payoff_matrix
export GROUP_A, GROUP_B
export Agent, AgentPopulation
export MemorySystem
export NoOverride, StrategyOverride, override_strategies
export MatchingRule, OnePair, match_agents
export TrialResult, run_simulation

# batch.jl
export run_batch

# analysis.jl
export count_final_strategies
export compute_payoff_outcome
export sample_strategy_shares

end # module GameTCAgentsBR
