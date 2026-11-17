# Reproducer: run_simulation re-seeds the task-local RNG (README tracking pattern)
using GameTCAgentsBR
using Random

game = PairGame(["L", "M", "H"], [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0])
config = SimConfig(
    game = game, num_agents = 4, group_a_ratio = 0.5,
    steps_per_initialization = 1, random_seed = 1,
)

Random.seed!(999)
_ = rand(1:1000)  # first draw after seed
run_simulation(config; seed = 42)
after_sim = rand(1:1000)

Random.seed!(999)
_ = rand(1:1000)
without_sim = rand(1:1000)

if after_sim != without_sim
    println("REPRODUCED run-simulation-preserves-caller-rng")
else
    error("RNG stream unchanged: after=$after_sim without=$without_sim")
end