# Memory counts, payoff summary, and strategy shares.

"""Relative tolerance for `compute_payoff_outcome` payoff balance (1%)."""
const PAYOFF_BALANCE_REL_TOL = 0.01

"""
    _accumulate_strategy_counts!(counts, mem_view, num_strategies_max, agent_id)

Add one to `counts[s]` for each filled slot holding strategy `s`.
Out-of-range codes raise `ArgumentError` naming the agent and slot.
"""
function _accumulate_strategy_counts!(
        counts::Vector{Int},
        mem_view,
        num_strategies_max::Int,
        agent_id::Int,
    )
    for (slot, strategy) in pairs(mem_view)
        strategy == MEMORY_PLACEHOLDER && continue
        s = Int(strategy)
        if 1 <= s <= num_strategies_max
            counts[s] += 1
        else
            throw(
                ArgumentError(
                    "count_final_strategies: strategy code $s at agent $agent_id memory slot $slot is outside 1:$num_strategies_max for this game; " *
                        "memories store strategy indices from the payoff matrix — reset corrupted slots or align `PairGame` size",
                ),
            )
        end
    end
    return nothing
end

"""
    count_final_strategies(memory::MemorySystem, config::SimConfig) -> StrategySlotCounts

Count strategy observations stored in opponent-group-specific memory at the
stopping step.

Returns memory-slot counts. `a_remembers_b_slot_count[i]` is how many of
A's memory slots hold B strategy `i`. The other fields are
`<observer>_remembers_<actor>_slot_count`. Each vector has length
`num_strategies`. Index `i` is strategy `i`. Repeated observations in different
slots are counted separately. Common memory is not counted.
"""
function count_final_strategies(memory::MemorySystem, config::SimConfig)
    num_strategies_max = num_strategies(config)

    aa_counts = zeros(Int, num_strategies_max)
    ab_counts = zeros(Int, num_strategies_max)
    ba_counts = zeros(Int, num_strategies_max)
    bb_counts = zeros(Int, num_strategies_max)

    groups = assign_groups(config)
    for agent_id in 1:config.num_agents
        agent_group = groups[agent_id]
        if agent_group == GROUP_A
            _accumulate_strategy_counts!(aa_counts, @view(memory.group_a_memories[agent_id, :]), num_strategies_max, agent_id)
            _accumulate_strategy_counts!(ab_counts, @view(memory.group_b_memories[agent_id, :]), num_strategies_max, agent_id)
        else
            _accumulate_strategy_counts!(ba_counts, @view(memory.group_a_memories[agent_id, :]), num_strategies_max, agent_id)
            _accumulate_strategy_counts!(bb_counts, @view(memory.group_b_memories[agent_id, :]), num_strategies_max, agent_id)
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
function applies to the shared square payoff `U`: if A uses strategy `i` and B
uses strategy `j`, their payoffs are `U[i, j]` and `U[j, i]`.

`payoff_gap` is the relative absolute difference
`|payoff_A - payoff_B| / (|payoff_A| + |payoff_B|)`. `advantage = :balanced` when
`abs(payoff_A - payoff_B) < PAYOFF_BALANCE_REL_TOL * max(payoff_A, payoff_B, 0.01)`
(`PAYOFF_BALANCE_REL_TOL` is `0.01`, i.e. a 1% band). Otherwise `advantage` is
`:payoff_a_higher` or `:payoff_b_higher`.

When either count vector sums to zero, payoffs and `advantage` are `missing` and
`missing_reason` is `:empty_strategy_counts` (not `NaN` or `:unknown`).
"""
function compute_payoff_outcome(
        a_strategy_counts::AbstractVector{<:Integer},
        b_strategy_counts::AbstractVector{<:Integer},
        payoff_matrix::Matrix{Float64}
    )
    n = size(payoff_matrix, 1)
    @argcheck size(payoff_matrix, 2) == n "compute_payoff_outcome: payoff_matrix must be square (got $(size(payoff_matrix))); pass an n×n matrix"
    len_a = length(a_strategy_counts)
    len_b = length(b_strategy_counts)
    @argcheck len_a == n && len_b == n "compute_payoff_outcome: count vector lengths must equal payoff matrix size ($n); got a_strategy_counts length $len_a and b_strategy_counts length $len_b — e.g. `zeros(Int, $n)` for each side"

    a_total = sum(a_strategy_counts)
    b_total = sum(b_strategy_counts)

    if a_total == 0 || b_total == 0
        return (
            payoff_gap = missing,
            payoff_A = missing,
            payoff_B = missing,
            advantage = missing,
            missing_reason = :empty_strategy_counts,
        )
    end

    a_freq = a_strategy_counts ./ a_total
    b_freq = b_strategy_counts ./ b_total

    payoff_A = 0.0
    payoff_B = 0.0

    for i in 1:n, j in 1:n
        prob = a_freq[i] * b_freq[j]
        payoff_A += prob * payoff_matrix[i, j]
        payoff_B += prob * payoff_matrix[j, i]
    end

    total_magnitude = abs(payoff_A) + abs(payoff_B)
    if iszero(total_magnitude)
        payoff_gap = 0.0
    else
        payoff_gap = abs(payoff_A - payoff_B) / total_magnitude
    end

    ε = PAYOFF_BALANCE_REL_TOL * max(payoff_A, payoff_B, 0.01)
    if abs(payoff_A - payoff_B) < ε
        advantage = :balanced
    elseif payoff_A > payoff_B
        advantage = :payoff_a_higher
    else
        advantage = :payoff_b_higher
    end

    return (
        payoff_gap = payoff_gap,
        payoff_A = payoff_A,
        payoff_B = payoff_B,
        advantage = advantage,
        missing_reason = missing,
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
        _assert_override_playable(agent, strategy, config.game)
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
    sample_strategy_shares(memory, config, population, rng; step)

Next-strategy shares against one representative opponent from each populated group.
Each share counts the strategy returned by `override_strategies` at `step`.

The representative is the first agent in that group's index list. A returned
vector is empty when either the acting group or the opponent group is empty.
"""
function sample_strategy_shares(
        memory::MemorySystem,
        config::SimConfig,
        population::AgentPopulation,
        rng::AbstractRNG;
        step::Int,
    )
    n_strat = num_strategies(config)
    payoffs = zeros(Float64, n_strat)
    optimal_strategies = Vector{Int}(undef, n_strat)
    counts_a_a = zeros(Int, n_strat)
    counts_a_b = zeros(Int, n_strat)
    counts_b_a = zeros(Int, n_strat)
    counts_b_b = zeros(Int, n_strat)

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
        group_a_against_group_a = _share_copy(counts_a_a, n_a, n_strat),
        group_a_against_group_b = _share_copy(counts_a_b, n_a > 0 && n_b > 0 ? n_a : 0, n_strat),
        group_b_against_group_a = _share_copy(counts_b_a, n_a > 0 && n_b > 0 ? n_b : 0, n_strat),
        group_b_against_group_b = _share_copy(counts_b_b, n_b, n_strat),
    )
end
