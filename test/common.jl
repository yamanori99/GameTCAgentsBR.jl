# Shared test fixtures. Included from runtests.jl.

using GameTCAgentsBR: GROUP_A, MEMORY_PLACEHOLDER
import GameTCAgentsBR: match_agents, override_strategies

const TEST_DEMAND_PAYOFF = [
    4.5 4.5 4.5
    5.0 5.0 0.0
    5.5 0.0 0.0
]

const TEST_GAME = PairGame(["L", "M", "H"], TEST_DEMAND_PAYOFF)

function pairgame(M::AbstractMatrix)
    return PairGame(string.(1:size(M, 1)), M)
end

struct PlayMWhenEmpty <: StrategyOverride end

struct FixedPair <: MatchingRule
    a1::Int
    a2::Int
end

function match_agents(rule::FixedPair, _step, _memory, _population, _config)
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
