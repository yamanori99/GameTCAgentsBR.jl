# Payoff, configuration, population, memory, strategy selection, and one trial.

# Population indices for the two-group game
const GROUP_A = Int8(1)
const GROUP_B = Int8(2)

"""
    PairGame(U)
    PairGame(labels, U, play_a=1:n, play_b=1:n)

One strategy set and one row-player payoff matrix. `U[i, j]` is the payoff of
strategy `i` against strategy `j`. The opponent's payoff is `U[j, i]`.

`labels` names the rows for display. It is not used when a strategy is chosen.
`play_a` and `play_b` are the strategies each group can play. Both default to
every index of `U`.
"""
struct PairGame
    labels::Vector{String}
    U::Matrix{Float64}
    playable_A::Vector{Int}
    playable_B::Vector{Int}

    function PairGame(
            labels::Vector{String},
            U::Matrix{Float64},
            playable_A::Vector{Int},
            playable_B::Vector{Int},
        )
        n = size(U, 1)
        @argcheck size(U, 2) == n "payoff matrix must be square"
        @argcheck length(labels) == n "label count must match the payoff matrix"
        @argcheck !isempty(playable_A) && !isempty(playable_B) "each group must have a strategy"
        @argcheck allunique(playable_A) && allunique(playable_B) "playable strategies must be unique"
        @argcheck all(i -> 1 <= i <= n, playable_A) &&
            all(i -> 1 <= i <= n, playable_B) "playable strategies must be in 1:n"
        return new(labels, U, playable_A, playable_B)
    end
end

function PairGame(
        labels::AbstractVector{<:AbstractString},
        U::AbstractMatrix{<:Real},
        play_a = 1:size(U, 1),
        play_b = 1:size(U, 1),
    )
    return PairGame(String.(labels), Matrix{Float64}(U), collect(Int, play_a), collect(Int, play_b))
end

PairGame(U::AbstractMatrix{<:Real}) = PairGame(string.(1:size(U, 1)), U)

"""Algorithm that may replace the two strategies chosen for an encounter."""
abstract type StrategyOverride end

"""Strategy override that returns the chosen strategies unchanged."""
struct NoOverride <: StrategyOverride end

"""Rule that chooses which agents meet in one step."""
abstract type MatchingRule end

"""One uniformly chosen pair of distinct agents per step."""
struct OnePair <: MatchingRule end

"""
    SimConfig(; game, ...)

Simulation configuration. `game` is a required `PairGame`.
`type_conditioning_ratio_a` and `type_conditioning_ratio_b` are probabilities in
`[0, 1]`. Both default to `1.0`. Group A may be empty (`group_a_ratio` 0).
"""
@kwdef struct SimConfig
    game::PairGame
    num_agents::Int = 200
    group_a_ratio::Float64 = 0.3
    type_conditioning_ratio_a::Float64 = 1.0
    type_conditioning_ratio_b::Float64 = 1.0
    memory_length_for_group_a::Int = 10
    memory_length_for_group_b::Int = 10
    common_memory_length::Int = 20
    strategy_override::StrategyOverride = NoOverride()
    matching::MatchingRule = OnePair()
    num_initializations::Int = 10000
    steps_per_initialization::Int = 200000
    random_seed::Union{Int, Nothing} = nothing
    group_a_size::Int = round(Int, num_agents * group_a_ratio)
    num_strategies::Int = size(game.U, 1)

    function SimConfig(
            game::PairGame,
            num_agents::Int,
            group_a_ratio::Float64,
            type_conditioning_ratio_a::Float64,
            type_conditioning_ratio_b::Float64,
            memory_length_for_group_a::Int,
            memory_length_for_group_b::Int,
            common_memory_length::Int,
            strategy_override::StrategyOverride,
            matching::MatchingRule,
            num_initializations::Int,
            steps_per_initialization::Int,
            random_seed::Union{Int, Nothing},
            group_a_size::Int,
            num_strategies::Int,
        )
        @argcheck 0.0 <= type_conditioning_ratio_a <= 1.0 &&
            0.0 <=
            type_conditioning_ratio_b <=
            1.0 "type_conditioning_ratio must be in [0,1]"
        @argcheck num_agents > 0 "num_agents must be positive"
        @argcheck 0.0 <= group_a_ratio <= 0.5 "group_a_ratio must be in [0, 0.5]"
        @argcheck memory_length_for_group_a > 0 "memory_length_for_group_a must be positive"
        @argcheck memory_length_for_group_b > 0 "memory_length_for_group_b must be positive"
        @argcheck common_memory_length > 0 "common_memory_length must be positive"
        @argcheck num_initializations > 0 "num_initializations must be positive"
        @argcheck steps_per_initialization > 0 "steps_per_initialization must be positive"
        @argcheck group_a_size <
            num_agents "Invalid group_a_ratio: results in empty Group B"
        return new(
            game,
            num_agents,
            group_a_ratio,
            type_conditioning_ratio_a,
            type_conditioning_ratio_b,
            memory_length_for_group_a,
            memory_length_for_group_b,
            common_memory_length,
            strategy_override,
            matching,
            num_initializations,
            steps_per_initialization,
            random_seed,
            group_a_size,
            num_strategies,
        )
    end
end

"""
    assign_groups(config) -> Vector{Int8}

Group id for each agent (`1:num_agents`). Default layout is A then B,
with sizes from `config.group_a_size`.
"""
function assign_groups(config::SimConfig)
    n = config.num_agents
    n_a = config.group_a_size
    groups = Vector{Int8}(undef, n)
    @inbounds for i in 1:n_a
        groups[i] = GROUP_A
    end
    @inbounds for i in (n_a + 1):n
        groups[i] = GROUP_B
    end
    return groups
end

"""
    Agent

One member of the population.

# Fields
- `id::Int`: Unique agent identifier (1 to num_agents)
- `group::Int8`: Population index (`GROUP_A` or `GROUP_B`)
- `uses_type_conditioning::Bool`: Whether agent uses type-conditional strategies
"""
struct Agent
    id::Int
    group::Int8
    uses_type_conditioning::Bool
end

"""
    AgentPopulation

Manages agent collection with pre-computed group indices for efficient access.

# Fields
- `agents::Vector{Agent}`: All agents
- `group_a_indices::Vector{Int}`: Indices of Group A agents
- `group_b_indices::Vector{Int}`: Indices of Group B agents
"""
struct AgentPopulation
    agents::Vector{Agent}
    group_a_indices::Vector{Int}
    group_b_indices::Vector{Int}

    function AgentPopulation(config::SimConfig)
        (; num_agents) = config
        groups = assign_groups(config)

        agents = Vector{Agent}(undef, num_agents)
        group_a_indices = Int[]
        group_b_indices = Int[]
        sizehint!(group_a_indices, config.group_a_size)
        sizehint!(group_b_indices, num_agents - config.group_a_size)

        for i in 1:num_agents
            group = groups[i]
            ratio = group == GROUP_A ?
                config.type_conditioning_ratio_a :
                config.type_conditioning_ratio_b
            uses_tc = rand() < ratio
            agents[i] = Agent(i, group, uses_tc)
            if group == GROUP_A
                push!(group_a_indices, i)
            else
                push!(group_b_indices, i)
            end
        end

        return new(agents, group_a_indices, group_b_indices)
    end
end

# Empty memory slot
const MEMORY_PLACEHOLDER = Int8(-1)

"""
    MemorySystem

Multi-type memory storage for agent strategy observations.

Each agent keeps three memories:
1. `group_a_memories`: Strategies observed from Group A
2. `group_b_memories`: Strategies observed from Group B
3. `common_memories`: All observed strategies; agents without type conditioning read this memory

# Fields
- `group_a_memories::Matrix{Int8}`: [agent, slot] → strategy
- `group_b_memories::Matrix{Int8}`: [agent, slot] → strategy
- `common_memories::Matrix{Int8}`: [agent, slot] → strategy
- `group_a_idx::Vector{Int}`: Next write position for group_a_memories
- `group_b_idx::Vector{Int}`: Next write position for group_b_memories
- `common_idx::Vector{Int}`: Next write position for common_memories
"""
struct MemorySystem
    group_a_memories::Matrix{Int8}
    group_b_memories::Matrix{Int8}
    common_memories::Matrix{Int8}

    # Next write position in each memory
    group_a_idx::Vector{Int}
    group_b_idx::Vector{Int}
    common_idx::Vector{Int}

    function MemorySystem(config::SimConfig)
        (; num_agents, memory_length_for_group_a, memory_length_for_group_b, common_memory_length) = config

        # Empty slots until a strategy is written
        group_a_memories = fill(MEMORY_PLACEHOLDER, num_agents, memory_length_for_group_a)
        group_b_memories = fill(MEMORY_PLACEHOLDER, num_agents, memory_length_for_group_b)
        common_memories = fill(MEMORY_PLACEHOLDER, num_agents, common_memory_length)

        # Next write starts at the first slot
        group_a_idx = ones(Int, num_agents)
        group_b_idx = ones(Int, num_agents)
        common_idx = ones(Int, num_agents)

        return new(
            group_a_memories,
            group_b_memories,
            common_memories,
            group_a_idx,
            group_b_idx,
            common_idx,
        )
    end
end

"""
    _push_memory!(memories, index, agent_id, strategy, length)

Write one observed strategy into this agent's memory.

`index[agent_id]` is the next slot to write, in `1:length`. After the write
it advances by one and wraps to `1`. Once every slot has been written, the
oldest strategy is overwritten first.
"""
function _push_memory!(
        memories::Matrix{Int8},
        index::Vector{Int},
        agent_id::Int,
        strategy::Int8,
        length::Int,
    )
    idx = index[agent_id]
    @inbounds memories[agent_id, idx] = strategy
    @inbounds index[agent_id] = mod1(idx + 1, length)
    return nothing
end

"""
    PAYOFF_TIE_EPS

Payoffs within this absolute gap count as a tie when choosing a strategy.
"""
const PAYOFF_TIE_EPS = 1.0e-10

"""
    determine_strategy(memory::MemorySystem, agent::Agent, opponent::Agent,
                      config::SimConfig, payoffs::Vector{Float64},
                      optimal_strategies::Vector{Int},
                      rng::AbstractRNG=Random.default_rng()) -> (Int8, Int, Bool)

Choose a strategy using memory for this encounter type.

Returns `(strategy, num_optimal, has_memory)` where:
- `strategy`: index in `1:num_strategies`
- `num_optimal`: number of playable strategies tied for the highest memory-average payoff
  (or the playable count when memory is empty)
- `has_memory`: whether the relevant memory had any observations

`payoffs` and `optimal_strategies` must be at least as long as `num_strategies`.
`rng` supplies the random choice among tied or uninformed strategies. It defaults
to the global RNG.

# Strategy Selection Rules
1. If the relevant memory has observations:
   - Average `U[s, j]` for each strategy `s` this group can play
   - A type-conditioning agent uses only the current opponent's group memory
   - Otherwise both group memories are used
   - Choose uniformly among the maximizing strategies
2. If that memory is empty:
   - Choose uniformly from the strategies this group can play
"""
function determine_strategy(
        memory::MemorySystem,
        agent::Agent,
        opponent::Agent,
        config::SimConfig,
        payoffs::Vector{Float64},
        optimal_strategies::Vector{Int},
        rng::AbstractRNG = Random.default_rng(),
    )
    playable = agent.group == GROUP_A ? config.game.playable_A : config.game.playable_B

    # Type conditioning reads only the opponent's group memory. Otherwise both
    # group memories are read. Common memory is not a column of U.
    banks = if agent.uses_type_conditioning
        (
            opponent.group == GROUP_A ?
                (@view memory.group_a_memories[agent.id, :]) :
                (@view memory.group_b_memories[agent.id, :]),
        )
    else
        (
            @view(memory.group_a_memories[agent.id, :]),
            @view(memory.group_b_memories[agent.id, :]),
        )
    end

    filled = false
    for bank in banks
        if any(!=(MEMORY_PLACEHOLDER), bank)
            filled = true
            break
        end
    end
    # An empty sample means each playable strategy is equally likely.
    if !filled
        strategy = Int8(playable[rand(rng, eachindex(playable))])
        return (strategy, length(playable), false)
    end

    fill!(payoffs, 0.0)
    n_observations = 0
    for bank in banks
        n_observations += _add_remembered_payoffs!(payoffs, bank, config.game, playable)
    end

    # The mean is the expected payoff under the empirical distribution in this row.
    if n_observations > 0
        payoffs ./= n_observations
    end

    # Keep every own strategy within PAYOFF_TIE_EPS of the best mean.
    max_payoff = maximum(s -> payoffs[s], playable)
    num_optimal = 0
    for s in playable
        if payoffs[s] >= max_payoff - PAYOFF_TIE_EPS
            num_optimal += 1
            optimal_strategies[num_optimal] = s
        end
    end
    # The first num_optimal entries are the tied strategies. Draw one of them.
    strategy = Int8(optimal_strategies[rand(rng, 1:num_optimal)])

    return (strategy, num_optimal, true)
end

"""Add `U[s, j]` for each remembered strategy `j` and each playable `s`."""
function _add_remembered_payoffs!(
        payoffs::Vector{Float64},
        bank,
        game::PairGame,
        playable::Vector{Int},
    )
    n = size(game.U, 1)
    n_observations = 0
    for code in bank
        # An unfilled slot is MEMORY_PLACEHOLDER, not an opponent strategy.
        code == MEMORY_PLACEHOLDER && continue
        j = Int(code)
        if !(1 <= j <= n)
            throw(ArgumentError("remembered strategy $j is outside 1:$n"))
        end
        for s in playable
            payoffs[s] += game.U[s, j]
        end
        n_observations += 1
    end
    return n_observations
end

"""
    override_strategies(::NoOverride, strategy1, strategy2, agent1, agent2,
                    step, memory, population, config)

Return the two strategies from `determine_strategy` unchanged.

Called once per encounter. The other arguments are that encounter's trial
state. `NoOverride` ignores them. Another `StrategyOverride` method may use
them and return replacement strategies, which the trial then records.
"""
function override_strategies(
        ::NoOverride,
        strategy1::Int8,
        strategy2::Int8,
        _agent1::Agent,
        _agent2::Agent,
        _step::Int,
        _memory::MemorySystem,
        _population::AgentPopulation,
        _config::SimConfig,
    )
    return strategy1, strategy2
end

"""
    match_agents(::OnePair, step, memory, population, config) -> Vector{Tuple{Int,Int}}

One pair of distinct agent indices, drawn uniformly with the task-local RNG.

Called once per step. The other arguments are that step's trial state.
`OnePair` ignores them. Another `MatchingRule` method may use them and return
the pairs for that step.
"""
function match_agents(
        ::OnePair,
        _step::Int,
        _memory::MemorySystem,
        population::AgentPopulation,
        _config::SimConfig,
    )
    n = length(population.agents)
    a1 = rand(1:n)
    temp = rand(1:(n - 1))
    a2 = temp >= a1 ? temp + 1 : temp
    return [(a1, a2)]
end

"""
    TrialResult

One finished trial.

# Fields
- `seed::Int`: Seed used for this trial
- `counts`: `count_final_strategies` at the stopping step
- `memory::MemorySystem`: Memory state at the stopping step
"""
struct TrialResult
    seed::Int
    counts::NamedTuple
    memory::MemorySystem
end

"""
    run_simulation(config::SimConfig;
                   seed::Union{Int,Nothing}=config.random_seed,
                   track_callback=nothing,
                   track_interval::Int=1000) -> TrialResult

Run one trial from `seed` and return that seed, the stopping-step memory
counts, and the memory itself. A missing seed is drawn from `RandomDevice`.
This function does not test whether the process has converged.

`track_callback` is `track_callback(step, memory, config, population)`.
"""
function run_simulation(
        config::SimConfig;
        seed::Union{Int, Nothing} = config.random_seed,
        track_callback = nothing,
        track_interval::Int = 1000,
    )
    # A missing seed is drawn once from the OS.
    seed = seed === nothing ? rand(Random.RandomDevice(), Int) : seed
    # Fix the task-local RNG so later rand calls in this trial follow that seed.
    Random.seed!(seed)

    # Initialize simulation state
    population = AgentPopulation(config)
    memory = MemorySystem(config)

    # Pre-allocate working buffers (use max of both groups)
    num_strategies_max = config.num_strategies
    payoffs = zeros(Float64, num_strategies_max)
    optimal_strategies = Vector{Int}(undef, num_strategies_max)

    # Run interactions
    for step in 1:config.steps_per_initialization
        pairs = match_agents(config.matching, step, memory, population, config)
        for (a1, a2) in pairs
            agent1 = population.agents[a1]
            agent2 = population.agents[a2]

            strategy1, _, _ = determine_strategy(
                memory,
                agent1,
                agent2,
                config,
                payoffs,
                optimal_strategies,
            )
            strategy2, _, _ = determine_strategy(
                memory,
                agent2,
                agent1,
                config,
                payoffs,
                optimal_strategies,
            )
            # Optional replacement of the two chosen strategies. NoOverride leaves them unchanged.
            strategy1, strategy2 = override_strategies(
                config.strategy_override,
                strategy1,
                strategy2,
                agent1,
                agent2,
                step,
                memory,
                population,
                config,
            )

            # Each agent records the opponent's strategy.
            _record_observation!(memory, agent1.id, strategy2, agent2.group, config)
            _record_observation!(memory, agent2.id, strategy1, agent1.group, config)
        end

        # Always pass population; callers that do not need it ignore the 4th argument.
        if track_callback !== nothing && step % track_interval == 0
            track_callback(step, memory, config, population)
        end
    end

    return TrialResult(seed, count_final_strategies(memory, config), memory)
end

"""
    _record_observation!(mem, receiver_id, strategy, opponent_group, config)

Write the opponent's strategy into the receiver's group memory and common memory.

`strategy` is an index of `U`.
"""
function _record_observation!(
        mem::MemorySystem,
        receiver_id::Int,
        strategy::Int8,
        opponent_group::Int8,
        config::SimConfig,
    )
    if opponent_group == GROUP_A
        _push_memory!(
            mem.group_a_memories,
            mem.group_a_idx,
            receiver_id,
            strategy,
            config.memory_length_for_group_a,
        )
    else
        _push_memory!(
            mem.group_b_memories,
            mem.group_b_idx,
            receiver_id,
            strategy,
            config.memory_length_for_group_b,
        )
    end
    _push_memory!(
        mem.common_memories,
        mem.common_idx,
        receiver_id,
        strategy,
        config.common_memory_length,
    )
    return nothing
end
