# Shared test fixtures. Included from runtests.jl.

using GameTCAgentsBR: GROUP_A, GROUP_B, MEMORY_PLACEHOLDER
import GameTCAgentsBR: match_agents, override_strategies

const TEST_DEMAND_PAYOFF = [
    4.5 4.5 4.5
    5.0 5.0 0.0
    5.5 0.0 0.0
]

const TEST_GAME = PairGame(["L", "M", "H"], TEST_DEMAND_PAYOFF, 1:3, 1:3)

function pairgame(M::AbstractMatrix)
    n = size(M, 1)
    return PairGame(string.(1:n), M, 1:n, 1:n)
end

"""Build a `SimConfig` with every required keyword set (test fixture only)."""
function test_sim_config(;
        game = TEST_GAME,
        num_agents = 10,
        group_a_size = 5,
        type_conditioning_ratio_a = 1.0,
        type_conditioning_ratio_b = 1.0,
        memory_length_for_group_a = 10,
        memory_length_for_group_b = 10,
        common_memory_length = 20,
        strategy_override = NoOverride(),
        matching = OnePair(),
        num_initializations = 1,
        steps_per_initialization = 100,
        random_seed = nothing,
    )
    return SimConfig(;
        game,
        num_agents,
        group_a_size,
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
    )
end

struct PlayMWhenEmpty <: StrategyOverride end

struct ForceHForB <: StrategyOverride end

struct FixedPair <: MatchingRule
    a1::Int
    a2::Int
end

function match_agents(rule::FixedPair, _step, _memory, _population, _config, _rng)
    return [(rule.a1, rule.a2)]
end

function _memory_observed(memory, agent, opponent)
    if agent.uses_type_conditioning
        row = opponent.group == GROUP_A ?
            memory.group_a_memories[agent.id, :] :
            memory.group_b_memories[agent.id, :]
        return any(!=(MEMORY_PLACEHOLDER), row)
    end
    return any(!=(MEMORY_PLACEHOLDER), memory.group_a_memories[agent.id, :]) ||
        any(!=(MEMORY_PLACEHOLDER), memory.group_b_memories[agent.id, :])
end

function override_strategies(
        ::PlayMWhenEmpty, strategy1, strategy2, agent1, agent2,
        _step, memory, _population, _config
    )
    if !_memory_observed(memory, agent1, agent2)
        strategy1 = Int8(2)
    end
    if !_memory_observed(memory, agent2, agent1)
        strategy2 = Int8(2)
    end
    return strategy1, strategy2
end

function override_strategies(::ForceHForB, s1, s2, _a1, a2, _step, _mem, _pop, _cfg)
    a2.group == GROUP_B && (s2 = Int8(3))
    return s1, s2
end

struct ForceHForActingB <: StrategyOverride end

function override_strategies(::ForceHForActingB, s1, s2, a1, _a2, _step, _mem, _pop, _cfg)
    a1.group == GROUP_B && (s1 = Int8(3))
    return s1, s2
end
