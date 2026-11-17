# Tests for strategy counts, batch trials, payoffs, and strategy shares.

using GameTCAgentsBR: GROUP_A, _push_memory!, _record_observation!, num_strategies

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
        config = test_sim_config(
            num_agents = 10,
            group_a_size = 3,
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

        sparse_config = test_sim_config(
            num_agents = 4, group_a_size = 2,
            memory_length_for_group_a = 10,
        )
        sparse = MemorySystem(sparse_config)
        _record_observation!(sparse, 1, Int8(2), GROUP_A, sparse_config)
        sparse_counts = count_final_strategies(sparse, sparse_config)
        @test sum(sparse_counts.a_remembers_a_slot_count) == 1
        @test sparse_counts.a_remembers_a_slot_count[2] == 1

        # Two slots of the same strategy count twice. Placeholders are skipped.
        # Out-of-range codes raise `ArgumentError`. Common memory is not included.
        slot_config = test_sim_config(
            num_agents = 2, group_a_size = 1,
            memory_length_for_group_a = 4, memory_length_for_group_b = 4,
            common_memory_length = 3,
        )
        slot_mem = MemorySystem(slot_config)
        slot_mem.group_a_memories[1, 1] = Int8(1)
        slot_mem.group_a_memories[1, 2] = Int8(1)
        slot_mem.group_b_memories[2, 1] = Int8(2)
        slot_mem.group_b_memories[2, 2] = Int8(2)
        fill!(slot_mem.common_memories, Int8(3))
        slot_counts = count_final_strategies(slot_mem, slot_config)
        @test slot_counts.a_remembers_a_slot_count == [2, 0, 0]
        @test slot_counts.a_remembers_b_slot_count == [0, 0, 0]
        @test slot_counts.b_remembers_a_slot_count == [0, 0, 0]
        @test slot_counts.b_remembers_b_slot_count == [0, 2, 0]
        slot_mem.group_a_memories[1, 4] = Int8(9)
        @test_throws ArgumentError count_final_strategies(slot_mem, slot_config)

        wide = PairGame(["a", "b", "c", "d", "e"], ones(5, 5), 1:3, 4:5)
        wide_config = test_sim_config(
            game = wide, num_agents = 2, group_a_size = 1,
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
        config = test_sim_config(
            num_agents = 20,
            group_a_size = 6,
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
        seeded = test_sim_config(
            num_agents = 20,
            group_a_size = 6,
            num_initializations = 3,
            steps_per_initialization = 100,
        )
        first = run_batch(seeded; trial_seeds)
        second = run_batch(seeded; trial_seeds)
        @test first.a_remembers_b_trial_count == second.a_remembers_b_trial_count
        @test_throws ArgumentError run_batch(seeded; trial_seeds = [1, 2])
        @test_throws ArgumentError run_batch(seeded)

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
        @test fair.advantage == :balanced
        @test !hasproperty(fair, :L_value)

        a_advantage = compute_payoff_outcome([0, 0, 100], [100, 0, 0], payoff_matrix)
        @test a_advantage.payoff_A ≈ 8.0 atol = 0.001
        @test a_advantage.payoff_B ≈ 2.0 atol = 0.001
        @test a_advantage.payoff_gap ≈ 0.6 atol = 0.001
        @test a_advantage.advantage == :payoff_a_higher

        b_advantage = compute_payoff_outcome([100, 0, 0], [0, 0, 100], payoff_matrix)
        @test b_advantage.payoff_A ≈ 2.0 atol = 0.001
        @test b_advantage.payoff_B ≈ 8.0 atol = 0.001
        @test b_advantage.payoff_gap ≈ 0.6 atol = 0.001
        @test b_advantage.advantage == :payoff_b_higher

        empty = compute_payoff_outcome([0, 0, 0], [0, 0, 0], payoff_matrix)
        @test ismissing(empty.payoff_gap)
        @test ismissing(empty.payoff_A)
        @test ismissing(empty.payoff_B)
        @test ismissing(empty.advantage)
        @test empty.missing_reason == :empty_strategy_counts

        skewed = compute_payoff_outcome([0, 0, 100], [100, 0, 0], payoff_matrix)
        @test skewed.payoff_A ≈ 8.0 atol = 0.001
        @test skewed.payoff_B ≈ 2.0 atol = 0.001
        @test skewed.payoff_gap ≈ 0.6 atol = 0.001
        @test skewed.advantage == :payoff_a_higher

        zero_matrix = zeros(3, 3)
        zero_payoff = compute_payoff_outcome([100, 0, 0], [0, 100, 0], zero_matrix)
        @test zero_payoff.payoff_A == 0.0
        @test zero_payoff.payoff_B == 0.0
        @test zero_payoff.payoff_gap == 0.0
        @test zero_payoff.advantage == :balanced

        @test_throws ArgumentError compute_payoff_outcome([1, 2], [1, 2, 3], payoff_matrix)
        @test_throws ArgumentError compute_payoff_outcome([1, 2, 3, 4], [1, 2, 3, 4], payoff_matrix)
        @test_throws ArgumentError compute_payoff_outcome([1, 2, 3], [1, 2], payoff_matrix)
        nonsquare = [1.0 2.0; 3.0 4.0; 5.0 6.0]
        @test_throws ArgumentError compute_payoff_outcome([1, 2, 3], [1, 2, 3], nonsquare)

        config = test_sim_config(
            game = pairgame([2.0 2.0 2.0; 5.0 5.0 0.0; 8.0 0.0 0.0]),
            num_agents = 10,
            group_a_size = 3,
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
        @test from_memory.advantage == :payoff_b_higher
    end

    @testset "sample_strategy_shares" begin
        config = test_sim_config(
            num_agents = 4,
            group_a_size = 2,
            memory_length_for_group_a = 2,
            memory_length_for_group_b = 2,
        )
        population = AgentPopulation(config, Random.Xoshiro(1))
        memory = MemorySystem(config)
        for agent_id in population.group_a_indices
            _push_memory!(memory.group_a_memories, memory.group_a_idx, agent_id, Int8(1), config.memory_length_for_group_a)
        end
        shares = sample_strategy_shares(memory, config, population, Random.Xoshiro(1); step = 1)
        @test shares.group_a_against_group_a ≈ [0.0, 0.0, 1.0]
        @test length(shares.group_a_against_group_b) == num_strategies(config)
        repeated = sample_strategy_shares(memory, config, population, Random.Xoshiro(1); step = 1)
        @test shares.group_b_against_group_a == repeated.group_b_against_group_a

        one_group = test_sim_config(num_agents = 4, group_a_size = 0)
        one_shares = sample_strategy_shares(
            MemorySystem(one_group), one_group, AgentPopulation(one_group, Random.Xoshiro(1)), Random.Xoshiro(1); step = 1,
        )
        @test isempty(one_shares.group_a_against_group_a)
        @test isempty(one_shares.group_a_against_group_b)
        @test length(one_shares.group_b_against_group_b) == num_strategies(one_group)

        empty_override = test_sim_config(
            num_agents = 4, group_a_size = 2,
            strategy_override = PlayMWhenEmpty(),
        )
        empty_shares = sample_strategy_shares(
            MemorySystem(empty_override), empty_override, AgentPopulation(empty_override, Random.Xoshiro(1)),
            Random.Xoshiro(1); step = 1,
        )
        @test empty_shares.group_a_against_group_b ≈ [0.0, 1.0, 0.0]

        limited_game = PairGame(["s1", "s2", "s3"], TEST_PAYOFF_3, [1, 2, 3], [1, 2])
        bad_shares = test_sim_config(
            game = limited_game, num_agents = 4, group_a_size = 1,
            strategy_override = ForceHForActingB(),
        )
        bad_shares_pop = AgentPopulation(bad_shares, Random.Xoshiro(1))
        @test_throws ArgumentError sample_strategy_shares(
            MemorySystem(bad_shares), bad_shares, bad_shares_pop, Random.Xoshiro(1); step = 1,
        )

        fast = test_sim_config(
            num_agents = 6, group_a_size = 3,
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
