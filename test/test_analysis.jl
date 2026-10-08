"""
Tests for strategy counts, batch trials, payoffs, and strategy shares.
"""

using GameTCAgentsBR: GROUP_A, _push_memory!, _record_observation!

function _trial_presence(trials, key)
    n = length(first(trials).counts[key])
    present = zeros(Int, n)
    for trial in trials
        counts = trial.counts[key]
        for i in 1:n
            counts[i] > 0 && (present[i] += 1)
        end
    end
    return present
end

@testset "Analysis" begin
    @testset "count_final_strategies" begin
        config = SimConfig(
            game = TEST_GAME,
            num_agents = 10,
            group_a_ratio = 0.3,
            memory_length_for_group_a = 5,
            memory_length_for_group_b = 5,
        )
        mem = MemorySystem(config)

        for agent_id in 1:3
            _push_memory!(mem.group_a_memories, mem.group_a_idx, agent_id, Int8(1), config.memory_length_for_group_a)
            _push_memory!(mem.group_b_memories, mem.group_b_idx, agent_id, Int8(2), config.memory_length_for_group_b)
        end
        for agent_id in 4:10
            _push_memory!(mem.group_a_memories, mem.group_a_idx, agent_id, Int8(3), config.memory_length_for_group_a)
            _push_memory!(mem.group_b_memories, mem.group_b_idx, agent_id, Int8(1), config.memory_length_for_group_b)
        end

        counts = count_final_strategies(mem, config)
        @test counts.a_remembers_a_slot_count == [3, 0, 0]
        @test counts.a_remembers_b_slot_count == [0, 3, 0]
        @test counts.b_remembers_a_slot_count == [0, 0, 7]
        @test counts.b_remembers_b_slot_count == [7, 0, 0]

        sparse_config = SimConfig(
            game = TEST_GAME, num_agents = 4, group_a_ratio = 0.5,
            memory_length_for_group_a = 10,
        )
        sparse = MemorySystem(sparse_config)
        _record_observation!(sparse, 1, Int8(2), GROUP_A, sparse_config)
        sparse_counts = count_final_strategies(sparse, sparse_config)
        @test sum(sparse_counts.a_remembers_a_slot_count) == 1
        @test sparse_counts.a_remembers_a_slot_count[2] == 1

        # Two slots of the same strategy count twice. Placeholders and an
        # out-of-range code do not. Common memory is not included.
        slot_config = SimConfig(
            game = TEST_GAME, num_agents = 2, group_a_ratio = 0.5,
            memory_length_for_group_a = 4, memory_length_for_group_b = 4,
            common_memory_length = 3,
        )
        slot_mem = MemorySystem(slot_config)
        slot_mem.group_a_memories[1, 1] = Int8(1)
        slot_mem.group_a_memories[1, 2] = Int8(1)
        slot_mem.group_a_memories[1, 4] = Int8(9)
        slot_mem.group_b_memories[2, 1] = Int8(2)
        slot_mem.group_b_memories[2, 2] = Int8(2)
        fill!(slot_mem.common_memories, Int8(3))
        slot_counts = count_final_strategies(slot_mem, slot_config)
        @test slot_counts.a_remembers_a_slot_count == [2, 0, 0]
        @test slot_counts.a_remembers_b_slot_count == [0, 0, 0]
        @test slot_counts.b_remembers_a_slot_count == [0, 0, 0]
        @test slot_counts.b_remembers_b_slot_count == [0, 2, 0]

        wide = PairGame(["a", "b", "c", "d", "e"], ones(5, 5), 1:3, 4:5)
        wide_config = SimConfig(
            game = wide, num_agents = 2, group_a_ratio = 0.5,
            memory_length_for_group_a = 1, memory_length_for_group_b = 1,
        )
        wide_mem = MemorySystem(wide_config)
        _record_observation!(wide_mem, 2, Int8(1), GROUP_A, wide_config)
        wide_counts = count_final_strategies(wide_mem, wide_config)
        @test wide_counts.b_remembers_a_slot_count == [1, 0, 0, 0, 0]
        _record_observation!(wide_mem, 1, Int8(4), GROUP_B, wide_config)
        wide_counts = count_final_strategies(wide_mem, wide_config)
        @test wide_counts.a_remembers_b_slot_count == [0, 0, 0, 1, 0]
    end

    @testset "run_batch" begin
        config = SimConfig(
            game = TEST_GAME,
            num_agents = 20,
            group_a_ratio = 0.3,
            num_initializations = 3,
            steps_per_initialization = 100,
            random_seed = 42,
        )
        result = run_batch(config)
        @test result.a_remembers_a_trial_count == _trial_presence(result.trials, :a_remembers_a_slot_count)
        @test result.a_remembers_b_trial_count == _trial_presence(result.trials, :a_remembers_b_slot_count)
        @test result.b_remembers_a_trial_count == _trial_presence(result.trials, :b_remembers_a_slot_count)
        @test result.b_remembers_b_trial_count == _trial_presence(result.trials, :b_remembers_b_slot_count)
        @test length(result.trials) == 3
        @test all(trial -> trial isa TrialResult, result.trials)
        @test result.trials[1].seed != result.trials[2].seed
        @test haskey(result.trials[1].counts, :a_remembers_a_slot_count)

        again = run_batch(config)
        @test [trial.seed for trial in again.trials] == [trial.seed for trial in result.trials]
        @test again.a_remembers_a_trial_count == result.a_remembers_a_trial_count
        @test again.a_remembers_b_trial_count == result.a_remembers_b_trial_count
        @test again.b_remembers_a_trial_count == result.b_remembers_a_trial_count
        @test again.b_remembers_b_trial_count == result.b_remembers_b_trial_count

        trial_seeds = [100, 200, 300]
        seeded = SimConfig(
            game = TEST_GAME,
            num_agents = 20,
            num_initializations = 3,
            steps_per_initialization = 100,
        )
        first = run_batch(seeded; trial_seeds)
        second = run_batch(seeded; trial_seeds)
        @test first.a_remembers_b_trial_count == second.a_remembers_b_trial_count
        @test_throws ErrorException run_batch(seeded; trial_seeds = [1, 2])

        callback_data = []
        run_batch(
            config; on_trial_complete = (trial_idx, trial_seed, _counts, sim_result) ->
            push!(callback_data, (trial_idx = trial_idx, seed = trial_seed, memory = sim_result.memory))
        )
        @test length(callback_data) == 3
        @test callback_data[1].trial_idx == 1
        @test callback_data[1].memory isa MemorySystem
        @test callback_data[1].seed isa Int
    end

    @testset "compute_payoff_outcome" begin
        payoff_matrix = [2.0 2.0 2.0; 5.0 5.0 0.0; 8.0 0.0 0.0]

        fair = compute_payoff_outcome([0, 100, 0], [0, 100, 0], payoff_matrix)
        @test fair.payoff_gap ≈ 0.0 atol = 0.001
        @test fair.payoff_A ≈ fair.payoff_B atol = 0.001
        @test fair.advantage == :fair
        @test fair.L_value ≈ 2.0

        a_advantage = compute_payoff_outcome([0, 0, 100], [100, 0, 0], payoff_matrix)
        @test a_advantage.payoff_A ≈ 8.0 atol = 0.001
        @test a_advantage.payoff_B ≈ 2.0 atol = 0.001
        @test a_advantage.payoff_gap ≈ 0.6 atol = 0.001
        @test a_advantage.advantage == :a_advantage

        b_advantage = compute_payoff_outcome([100, 0, 0], [0, 0, 100], payoff_matrix)
        @test b_advantage.payoff_A ≈ 2.0 atol = 0.001
        @test b_advantage.payoff_B ≈ 8.0 atol = 0.001
        @test b_advantage.payoff_gap ≈ 0.6 atol = 0.001
        @test b_advantage.advantage == :b_advantage

        empty = compute_payoff_outcome([0, 0, 0], [0, 0, 0], payoff_matrix)
        @test isnan(empty.payoff_gap)
        @test isnan(empty.payoff_A)
        @test isnan(empty.payoff_B)
        @test empty.advantage == :unknown

        demand = compute_payoff_outcome(
            [0, 0, 100], [100, 0, 0],
            [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
        )
        @test demand.payoff_A ≈ 5.5 atol = 0.001
        @test demand.payoff_B ≈ 4.5 atol = 0.001
        @test demand.payoff_gap ≈ 0.1 atol = 0.001
        @test demand.L_value ≈ 4.5

        config = SimConfig(
            game = pairgame([2.0 2.0 2.0; 5.0 5.0 0.0; 8.0 0.0 0.0]),
            num_agents = 10,
            group_a_ratio = 0.3,
            memory_length_for_group_a = 5,
            memory_length_for_group_b = 5,
        )
        mem = MemorySystem(config)
        for agent_id in 1:3, _ in 1:5
            _push_memory!(mem.group_b_memories, mem.group_b_idx, agent_id, Int8(3), config.memory_length_for_group_b)
        end
        for agent_id in 4:10, _ in 1:5
            _push_memory!(mem.group_a_memories, mem.group_a_idx, agent_id, Int8(1), config.memory_length_for_group_a)
        end
        counts = count_final_strategies(mem, config)
        from_memory = compute_payoff_outcome(
            counts.b_remembers_a_slot_count,
            counts.a_remembers_b_slot_count,
            config.game.U,
        )
        # B remembers A playing L (35 slots). A remembers B playing H (15 slots).
        @test from_memory.payoff_A ≈ 2.0 atol = 0.001
        @test from_memory.payoff_B ≈ 8.0 atol = 0.001
        @test from_memory.payoff_gap ≈ 0.6 atol = 0.001
        @test from_memory.advantage == :b_advantage
    end

    @testset "sample_strategy_shares" begin
        config = SimConfig(
            game = TEST_GAME,
            num_agents = 4,
            group_a_ratio = 0.5,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 2,
            memory_length_for_group_b = 2,
        )
        population = AgentPopulation(config)
        memory = MemorySystem(config)
        for agent_id in population.group_a_indices
            _push_memory!(memory.group_a_memories, memory.group_a_idx, agent_id, Int8(1), config.memory_length_for_group_a)
        end
        shares = sample_strategy_shares(memory, config, population, Random.Xoshiro(1); step = 1)
        @test shares.group_a_against_group_a ≈ [0.0, 0.0, 1.0]
        @test length(shares.group_a_against_group_b) == config.num_strategies
        repeated = sample_strategy_shares(memory, config, population, Random.Xoshiro(1); step = 1)
        @test shares.group_b_against_group_a == repeated.group_b_against_group_a

        one_group = SimConfig(
            game = TEST_GAME, num_agents = 4, group_a_ratio = 0.0,
            type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 1.0,
        )
        one_shares = sample_strategy_shares(
            MemorySystem(one_group), one_group, AgentPopulation(one_group), Random.Xoshiro(1); step = 1,
        )
        @test isempty(one_shares.group_a_against_group_a)
        @test isempty(one_shares.group_a_against_group_b)
        @test length(one_shares.group_b_against_group_b) == one_group.num_strategies

        empty_override = SimConfig(
            game = TEST_GAME, num_agents = 4, group_a_ratio = 0.5,
            type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 1.0,
            strategy_override = PlayMWhenEmpty(),
        )
        empty_shares = sample_strategy_shares(
            MemorySystem(empty_override), empty_override, AgentPopulation(empty_override),
            Random.Xoshiro(1); step = 1,
        )
        @test empty_shares.group_a_against_group_b ≈ [0.0, 1.0, 0.0]

        fast = SimConfig(
            game = TEST_GAME, num_agents = 6, group_a_ratio = 0.5,
            type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 1.0,
            steps_per_initialization = 5, random_seed = 11,
        )
        without = run_simulation(fast; seed = 11)
        with = run_simulation(
            fast; seed = 11, track_interval = 1,
            track_callback = (step, memory, config, population) ->
            sample_strategy_shares(memory, config, population, Random.Xoshiro(99); step),
        )
        @test without.memory.group_a_memories == with.memory.group_a_memories
        @test without.memory.group_b_memories == with.memory.group_b_memories
        @test without.memory.common_memories == with.memory.common_memories
    end
end
