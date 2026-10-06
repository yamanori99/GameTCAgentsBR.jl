# Memory counts, payoff summary, and strategy shares.

"""
    _accumulate_strategy_counts!(counts, mem_view, num_strategies_max)

Add one to `counts[s]` for each filled slot holding strategy `s`.
"""
function _accumulate_strategy_counts!(counts::Vector{Int}, mem_view, num_strategies_max::Int)
    for strategy in mem_view
        if strategy != MEMORY_PLACEHOLDER
            s = Int(strategy)
            if 1 <= s <= num_strategies_max
                counts[s] += 1
            end
        end
    end
    return nothing
end

"""
    count_final_strategies(memory::MemorySystem, config::SimConfig) -> NamedTuple

Count strategy observations stored in opponent-group-specific memory at the
stopping step.

Returns memory-slot counts. `a_remembers_b_slot_count[i]` is how many of
A's memory slots hold B strategy `i`. The other fields are
`<observer>_remembers_<actor>_slot_count`. Each vector has length
`max(num_strategies_a, num_strategies_b)`. Repeated observations in different
slots are counted separately. Common memory is not counted.
"""
function count_final_strategies(memory::MemorySystem, config::SimConfig)
    num_strategies_max = max(config.num_strategies_a, config.num_strategies_b)

    aa_counts = zeros(Int, num_strategies_max)
    ab_counts = zeros(Int, num_strategies_max)
    ba_counts = zeros(Int, num_strategies_max)
    bb_counts = zeros(Int, num_strategies_max)

    groups = assign_groups(config)
    for agent_id in 1:config.num_agents
        agent_group = groups[agent_id]
        if agent_group == GROUP_A
            _accumulate_strategy_counts!(aa_counts, @view(memory.group_a_memories[agent_id, :]), num_strategies_max)
            _accumulate_strategy_counts!(ab_counts, @view(memory.group_b_memories[agent_id, :]), num_strategies_max)
        else
            _accumulate_strategy_counts!(ba_counts, @view(memory.group_a_memories[agent_id, :]), num_strategies_max)
            _accumulate_strategy_counts!(bb_counts, @view(memory.group_b_memories[agent_id, :]), num_strategies_max)
        end
    end

    return (
        a_remembers_a_slot_count = aa_counts,
        a_remembers_b_slot_count = ab_counts,
        b_remembers_a_slot_count = ba_counts,
        b_remembers_b_slot_count = bb_counts,
    )
end

"""
    compute_payoff_outcome(a_strategy_counts, b_strategy_counts, payoff_matrix) -> NamedTuple

Payoffs under independent strategy shares derived from two count vectors.

The first vector weights A strategies and the second weights B strategies. This
function applies to a shared square cross-group payoff matrix `U`: if A uses
strategy `i` and B uses strategy `j`, their payoffs are `U[i, j]` and `U[j, i]`.
It therefore does not represent a general `PairGame` with distinct
`payoff_AB` and `payoff_BA` matrices.

`payoff_gap` is the relative absolute difference
`|payoff_A - payoff_B| / (|payoff_A| + |payoff_B|)`. The `advantage = :fair`
label means that the computed payoffs differ by less than the numerical
threshold used below; it is not a normative judgment.
"""
function compute_payoff_outcome(
        a_strategy_counts::AbstractVector{<:Integer},
        b_strategy_counts::AbstractVector{<:Integer},
        payoff_matrix::Matrix{Float64}
    )
    k = length(a_strategy_counts)
    L_value = payoff_matrix[1, 1]

    a_total = sum(a_strategy_counts)
    b_total = sum(b_strategy_counts)

    if a_total == 0 || b_total == 0
        return (
            payoff_gap = NaN, payoff_A = NaN, payoff_B = NaN,
            advantage = :unknown, L_value = L_value,
        )
    end

    a_freq = a_strategy_counts ./ a_total
    b_freq = b_strategy_counts ./ b_total

    payoff_A = 0.0
    payoff_B = 0.0

    for i in 1:k, j in 1:k
        prob = a_freq[i] * b_freq[j]
        payoff_A += prob * payoff_matrix[i, j]
        payoff_B += prob * payoff_matrix[j, i]
    end

    total_magnitude = abs(payoff_A) + abs(payoff_B)
    if total_magnitude ≈ 0.0
        payoff_gap = 0.0
    else
        payoff_gap = abs(payoff_A - payoff_B) / total_magnitude
    end

    ε = 0.01 * max(payoff_A, payoff_B, 0.01)
    if abs(payoff_A - payoff_B) < ε
        advantage = :fair
    elseif payoff_A > payoff_B
        advantage = :a_advantage
    else
        advantage = :b_advantage
    end

    return (
        payoff_gap = payoff_gap, payoff_A = payoff_A, payoff_B = payoff_B,
        advantage = advantage, L_value = L_value,
    )
end

"""
    _count_strategies_against!(counts, memory, agent_indices, opponent, config, population, payoffs, optimal_strategies, rng, step)

Count the strategy each listed agent would play against `opponent` after `override_strategies`.
"""
function _count_strategies_against!(
        counts::Vector{Int},
        memory::MemorySystem,
        agent_indices,
        opponent::Agent,
        config::SimConfig,
        population::AgentPopulation,
        payoffs::Vector{Float64},
        optimal_strategies::Vector{Int},
        rng::AbstractRNG,
        step::Int,
    )
    fill!(counts, 0)
    for idx in agent_indices
        agent = population.agents[idx]
        strategy, _, _ = determine_strategy(
            memory, agent, opponent, config, payoffs, optimal_strategies, rng,
        )
        opponent_strategy, _, _ = determine_strategy(
            memory, opponent, agent, config, payoffs, optimal_strategies, rng,
        )
        strategy, _ = override_strategies(
            config.strategy_override,
            strategy, opponent_strategy,
            agent, opponent,
            step, memory, population, config,
        )
        counts[Int(strategy)] += 1
    end
    return counts
end

"""
    _share_copy(counts, n_agents, n_strategies) -> Vector{Float64}

Return the first `n_strategies` counts divided by `n_agents`.
"""
function _share_copy(counts::Vector{Int}, n_agents::Int, n_strategies::Int)
    n_agents == 0 && return Float64[]
    return counts[1:n_strategies] ./ n_agents
end

"""
    sample_strategy_shares(memory, config, population, rng=Random.default_rng(); step)

Next-strategy shares against one representative opponent from each populated group.
Each share counts the strategy returned by `override_strategies` at `step`.

The representative is the first agent in that group's index list. A returned
vector is empty when either the acting group or the opponent group is empty.
"""
function sample_strategy_shares(
        memory::MemorySystem,
        config::SimConfig,
        population::AgentPopulation,
        rng::AbstractRNG = Random.default_rng();
        step::Int,
    )
    num_strategies_max = max(config.num_strategies_a, config.num_strategies_b)
    payoffs = zeros(Float64, num_strategies_max)
    optimal_strategies = Vector{Int}(undef, num_strategies_max)
    counts_a_a = zeros(Int, config.num_strategies_a)
    counts_a_b = zeros(Int, config.num_strategies_a)
    counts_b_a = zeros(Int, config.num_strategies_b)
    counts_b_b = zeros(Int, config.num_strategies_b)

    n_a = length(population.group_a_indices)
    n_b = length(population.group_b_indices)
    rep_a = n_a > 0 ? population.agents[first(population.group_a_indices)] : nothing
    rep_b = n_b > 0 ? population.agents[first(population.group_b_indices)] : nothing

    if n_a > 0
        _count_strategies_against!(
            counts_a_a, memory, population.group_a_indices, rep_a::Agent,
            config, population, payoffs, optimal_strategies, rng, step,
        )
    end
    if n_a > 0 && n_b > 0
        _count_strategies_against!(
            counts_a_b, memory, population.group_a_indices, rep_b::Agent,
            config, population, payoffs, optimal_strategies, rng, step,
        )
        _count_strategies_against!(
            counts_b_a, memory, population.group_b_indices, rep_a::Agent,
            config, population, payoffs, optimal_strategies, rng, step,
        )
    end
    if n_b > 0
        _count_strategies_against!(
            counts_b_b, memory, population.group_b_indices, rep_b::Agent,
            config, population, payoffs, optimal_strategies, rng, step,
        )
    end

    return (
        group_a_against_group_a = _share_copy(counts_a_a, n_a, config.num_strategies_a),
        group_a_against_group_b = _share_copy(counts_a_b, n_a > 0 && n_b > 0 ? n_a : 0, config.num_strategies_a),
        group_b_against_group_a = _share_copy(counts_b_a, n_a > 0 && n_b > 0 ? n_b : 0, config.num_strategies_b),
        group_b_against_group_b = _share_copy(counts_b_b, n_b, config.num_strategies_b),
    )
end
