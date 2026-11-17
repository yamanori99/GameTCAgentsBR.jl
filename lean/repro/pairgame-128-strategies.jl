# Reproducer: playable strategy 128 cannot be returned as Int8
using GameTCAgentsBR

game = PairGame(string.(1:128), ones(128, 128), 128:128, 1:1)
config = SimConfig(
    game = game, num_agents = 2, group_a_ratio = 0.5,
    steps_per_initialization = 1, random_seed = 1,
)
error = nothing
try
    run_simulation(config; seed = 1)
catch e
    global error = e
end
if error isa InexactError
    println("REPRODUCED pairgame-128-strategies")
else
    error("expected InexactError for Int8(128), got $(repr(error))")
end