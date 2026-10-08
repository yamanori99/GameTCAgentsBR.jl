# GameTCAgentsBR.jl

[English](README.md) | [日本語](README.ja.md)

[![Test](https://img.shields.io/github/actions/workflow/status/yamanori99/GameTCAgentsBR.jl/ci.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=Test)](https://github.com/yamanori99/GameTCAgentsBR.jl/actions/workflows/ci.yml)
[![Codecov](https://img.shields.io/codecov/c/github/yamanori99/GameTCAgentsBR.jl?style=flat-square&logo=codecov&logoColor=white)](https://codecov.io/gh/yamanori99/GameTCAgentsBR.jl)
[![docs-dev](https://img.shields.io/badge/docs-dev-blue?style=flat-square&logo=gitbook&logoColor=white)](https://yamanori99.github.io/GameTCAgentsBR.jl/dev/)
[![Julia 1.13+](https://img.shields.io/badge/Julia-1.13+-9558B2?style=flat-square&logo=julia&logoColor=white)](https://julialang.org/)
[![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)

GameTCAgentsBR.jl is a simulation of repeated pairwise games in a finite population.
Each agent records the opponent's strategy in a finite memory and can keep a separate
record for each opponent type (group).
From that record, the agent chooses an optimal strategy for the next game.

> [!NOTE]
> This implementation substantially generalizes and extends the simulation code of O'Connor (2017). See that paper.
> This simulator was designed to handle the Nash demand game, and the demos and tests use that game.

## Simulation procedure

```txt
PairGame  →  SimConfig                                    src/model.jl
        │
        ▼
run_batch (N trials)                                      src/batch.jl
        │
        │    per trial:
        │         run_simulation                          src/model.jl
        │         │
        │         └──►  step loop:
        │               [1] Pair ──► [2] Strategy ──► [3] Update ──► [4] track_callback
        │         │
        │         ▼
        │         count_final_strategies(memory)  ──► memory-slot counts  src/analysis.jl
        │
        ▼
    aggregate  ──►  number of trials with each strategy present
```

## Setup

Julia 1.13 or later is required. This package is local for now; install it from the directory that contains this file.

```bash
cd GameTCAgentsBR.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Basic use

```bash
cd GameTCAgentsBR.jl
julia --project=.
```

Run the following in the REPL. Run each code block in a new Julia session.

### Strategy frequency at the endpoint

See `demo/run.jl` for concrete parameter settings.

```julia
using GameTCAgentsBR

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = NoOverride(),
    matching = OnePair(),
    num_initializations = 10000,
    steps_per_initialization = 10_000,
    random_seed = 42,
)

results = run_batch(config)
println(results.b_remembers_a_trial_count)
println(results.a_remembers_b_trial_count)
println(results.a_remembers_a_trial_count)
println(results.b_remembers_b_trial_count)
```

The output lists, from the top, strategies A played against B, strategies B played against A, strategies within A, and strategies within B.
Each line is a `Vector{Int}` of trial counts for L, M, and H, in that order.

### Track one trial

To sample next-strategy shares during one trial, call `sample_strategy_shares` from `track_callback`. The series does not by itself show convergence or a basin of attraction.

```julia
using GameTCAgentsBR
using Random

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = NoOverride(),
    matching = OnePair(),
    num_initializations = 1,
    steps_per_initialization = 1_000,
    random_seed = 42,
)

path = NamedTuple[]
rng = Xoshiro(config.random_seed)
function record(step, memory, config, population)
    shares = sample_strategy_shares(memory, config, population, rng; step)
    push!(path, (; step, shares...))
end
run_simulation(config; seed = config.random_seed, track_callback = record, track_interval = 100)
for sample in path
    println(sample.step, " ", sample.group_a_against_group_b)
end
```

### Game definitions

The examples above give both groups every strategy. `U[i, j]` is the payoff of strategy `i` against strategy `j`. The names are the order of the result vectors. They are not used when a strategy is chosen.

B can be kept from playing H. `U` stays `3 × 3`.

```julia
U = [
    4.5 4.5 4.5
    5.0 5.0 0.0
    5.5 0.0 0.0
]
game = PairGame(["L", "M", "H"], U, [1, 2, 3], [1, 2])
```

A plays strategy indices 1, 2, and 3, and B plays indices 4 and 5. These numbers are not a count of strategies. `U` is then `5 × 5`: the upper left is A against A, the upper right is A against B, the lower left is B against A, and the lower right is B against B.

```julia
game = PairGame(
    ["a", "b", "c", "d", "e"],
    [
        1.0 0.0 0.0 0.2 0.2
        0.0 1.0 0.0 0.2 0.2
        0.0 0.0 1.0 0.2 0.2
        0.2 0.2 0.2 1.0 0.0
        0.2 0.2 0.2 0.0 1.0
    ],
    1:3,
    4:5,
)
```

## `demo/`

The two Nash demand runs above the game definitions can also be run with `demo/run.jl`.

`julia --project=demo demo/run.jl` runs the default case `l45 counts`.

Positional args: `[case] [mode]`. Cases start with `l40one`, then `l40`, then `l05` … `l45` except `l40` is not repeated (Nash demand `L = 0.5 … 4.5`).

`l40one` matches `l40` with `group_a_ratio = 0` (every agent is Group B).

`counts` counts trials in which each strategy occurs in memory at the stopping step. `traj` shows sampled next-strategy shares from one trial. A one-group case plots only that group's within-group series.

Trajectory options: `--samples N` (target sample count, default 200), `--steps N`, `--seed N`.

## Change the matching rule

### Example 1 `Round`

Pair the whole population in one step. When the number of agents is odd, one agent sits out that step. `Round` is not in the package; this block adds it.

```julia
using GameTCAgentsBR
using Random
import GameTCAgentsBR: match_agents

struct Round <: MatchingRule end

function match_agents(::Round, _step, _memory, population, _config)
    order = randperm(length(population.agents))
    n_pairs = length(order) ÷ 2
    pairs = Vector{Tuple{Int,Int}}(undef, n_pairs)
    for i in 1:n_pairs
        pairs[i] = (order[2i - 1], order[2i])
    end
    return pairs
end

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = NoOverride(),
    matching = Round(),
    num_initializations = 100,
    steps_per_initialization = 10_000,
    random_seed = 42,
)

results = run_batch(config)
println(results.b_remembers_a_trial_count)
println(results.a_remembers_b_trial_count)
println(results.a_remembers_a_trial_count)
println(results.b_remembers_b_trial_count)
```

### Example 2 `SameGroupBias`

Draw the partner from the same group with probability 0.8. An empty pool falls back to the other group.

```julia
using GameTCAgentsBR
import GameTCAgentsBR: match_agents

struct SameGroupBias <: MatchingRule
    probability::Float64
end

function match_agents(rule::SameGroupBias, _step, _memory, population, _config)
    agents = population.agents
    n = length(agents)
    a1 = rand(1:n)
    same = Int[]
    other = Int[]
    for i in 1:n
        i == a1 && continue
        if agents[i].group == agents[a1].group
            push!(same, i)
        else
            push!(other, i)
        end
    end
    prefer_same = rand() < rule.probability
    pool = prefer_same ? same : other
    if isempty(pool)
        pool = prefer_same ? other : same
    end
    return [(a1, rand(pool))]
end

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = NoOverride(),
    matching = SameGroupBias(0.8),
    num_initializations = 100,
    steps_per_initialization = 10_000,
    random_seed = 42,
)

results = run_batch(config)
println(results.b_remembers_a_trial_count)
println(results.a_remembers_b_trial_count)
println(results.a_remembers_a_trial_count)
println(results.b_remembers_b_trial_count)
```

## Change an agent's behavior rule

Best response is the base. `strategy_override` can replace the strategy that is then played.

### Example `PlayMWhenEmpty`

Add a method of `override_strategies` and pass it as `strategy_override`. The method that runs is dispatched on the type of the first argument. Use `NoOverride` when you are not making such a change.

The example below plays M (`2`) when the memory read for that opponent is empty. An empty slot is `Int8(-1)`.

```julia
using GameTCAgentsBR
import GameTCAgentsBR: override_strategies

struct PlayMWhenEmpty <: StrategyOverride end

function row_has_observation(memory, agent, opponent)
    if agent.uses_type_conditioning
        row = if opponent.group == GROUP_A
            memory.group_a_memories[agent.id, :]
        else
            memory.group_b_memories[agent.id, :]
        end
        return any(!=(Int8(-1)), row)
    end
    return any(!=(Int8(-1)), memory.group_a_memories[agent.id, :]) ||
        any(!=(Int8(-1)), memory.group_b_memories[agent.id, :])
end

function override_strategies(::PlayMWhenEmpty, strategy1, strategy2, agent1, agent2,
        step, memory, population, config)
    if !row_has_observation(memory, agent1, agent2)
        strategy1 = Int8(2)
    end
    if !row_has_observation(memory, agent2, agent1)
        strategy2 = Int8(2)
    end
    return strategy1, strategy2
end

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = PlayMWhenEmpty(),
    matching = OnePair(),
    num_initializations = 100,
    steps_per_initialization = 10_000,
    random_seed = 42,
)

results = run_batch(config)
println(results.b_remembers_a_trial_count)
println(results.a_remembers_b_trial_count)
println(results.a_remembers_a_trial_count)
println(results.b_remembers_b_trial_count)
```

### Tracking `PlayMWhenEmpty`

Record next-strategy shares during one trial.

```julia
using GameTCAgentsBR
using Random
import GameTCAgentsBR: override_strategies

struct PlayMWhenEmpty <: StrategyOverride end

function row_has_observation(memory, agent, opponent)
    if agent.uses_type_conditioning
        row = if opponent.group == GROUP_A
            memory.group_a_memories[agent.id, :]
        else
            memory.group_b_memories[agent.id, :]
        end
        return any(!=(Int8(-1)), row)
    end
    return any(!=(Int8(-1)), memory.group_a_memories[agent.id, :]) ||
        any(!=(Int8(-1)), memory.group_b_memories[agent.id, :])
end

function override_strategies(::PlayMWhenEmpty, strategy1, strategy2, agent1, agent2,
        step, memory, population, config)
    if !row_has_observation(memory, agent1, agent2)
        strategy1 = Int8(2)
    end
    if !row_has_observation(memory, agent2, agent1)
        strategy2 = Int8(2)
    end
    return strategy1, strategy2
end

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = PlayMWhenEmpty(),
    matching = OnePair(),
    num_initializations = 1,
    steps_per_initialization = 1_000,
    random_seed = 42,
)

path = NamedTuple[]
rng = Xoshiro(config.random_seed)
function record(step, memory, config, population)
    shares = sample_strategy_shares(memory, config, population, rng; step)
    push!(path, (; step, shares...))
end
run_simulation(config; seed = config.random_seed, track_callback = record, track_interval = 100)
for sample in path
    println(sample.step, " ", sample.group_a_against_group_b)
end
```

## Tests

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
./.github/jetls-check.sh
```

## References

The works below are listed in this document and in the module docstring of `src/GameTCAgentsBR.jl`.

1. O'Connor, C. (2017). The cultural Red King effect. *The Journal of Mathematical Sociology*, 41(3), 155–171. [https://doi.org/10.1080/0022250X.2017.1335723](https://doi.org/10.1080/0022250X.2017.1335723)
2. O'Connor, C. (2019). *The Origins of Unfairness: Social Categories and Cultural Evolution*. Oxford University Press.
3. Bruner, J. P. (2017). Minority (dis)advantage in population games. *Synthese*, 196(1), 413–427. [https://doi.org/10.1007/s11229-017-1487-8](https://doi.org/10.1007/s11229-017-1487-8)
4. Cochran, C., & O'Connor, C. (2019). Inequality and inequity in the emergence of conventions. *Politics, Philosophy & Economics*, 18(3), 264–281. [https://doi.org/10.1177/1470594X19828371](https://doi.org/10.1177/1470594X19828371)
