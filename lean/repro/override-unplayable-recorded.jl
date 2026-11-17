# Reproducer: StrategyOverride can record a strategy outside playable_B
using GameTCAgentsBR
import GameTCAgentsBR: override_strategies

struct BPlaysThree <: StrategyOverride end

function override_strategies(::BPlaysThree, s1, s2, _a1, agent2, _step, _mem, _pop, _cfg)
    if agent2.group == GROUP_B
        return s1, Int8(3)
    end
    return s1, s2
end

U = [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0]
game = PairGame(["L", "M", "H"], U, [1, 2, 3], [1, 2])
config = SimConfig(
    game = game, num_agents = 2, group_a_ratio = 0.5,
    strategy_override = BPlaysThree(), steps_per_initialization = 5, random_seed = 1,
)
trial = run_simulation(config; seed = 1)
row = trial.memory.group_b_memories[1, :]
if any(==(Int8(3)), row) && game.playable_B == [1, 2]
    println("REPRODUCED override-unplayable-recorded")
else
    error("expected strategy 3 in group_b_memories, got $row")
end
