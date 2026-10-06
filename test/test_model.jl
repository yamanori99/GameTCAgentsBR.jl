"""
Tests for model types and one trial.
"""

using GameTCAgentsBR:
    GROUP_A,
    GROUP_B,
    MEMORY_PLACEHOLDER,
    PAYOFF_TIE_EPS,
    _push_memory!,
    _record_observation!,
    assign_groups,
    determine_strategy

@testset "Model" begin
    @testset "SimConfig" begin
        @testset "Default initialization" begin
            config = SimConfig(game = TEST_GAME)
            @test config.num_agents == 200
            @test config.group_a_ratio == 0.3
            @test config.type_conditioning_ratio_a == 1.0
            @test config.type_conditioning_ratio_b == 1.0
            @test config.memory_length_for_group_a == 10
            @test config.memory_length_for_group_b == 10
            @test config.common_memory_length == 20
            @test config.strategy_override isa NoOverride
            @test config.matching isa OnePair
            @test config.num_initializations == 10000
            @test config.steps_per_initialization == 200000
            @test config.random_seed === nothing
        end

        @testset "Derived fields" begin
            config = SimConfig(game = TEST_GAME, num_agents = 100, group_a_ratio = 0.3)
            @test config.group_a_size == 30
            @test config.num_strategies_a == 3
            @test config.num_strategies_b == 3

            config2 = SimConfig(game = pairgame([1.0 2.0; 3.0 4.0]))
            @test config2.num_strategies_a == 2
            @test config2.num_strategies_b == 2
        end

        @testset "Validation" begin
            @test_throws ArgumentError SimConfig(game = TEST_GAME, num_agents = 0)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, group_a_ratio = -0.1)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, group_a_ratio = 0.6)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, type_conditioning_ratio_a = -0.1)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, type_conditioning_ratio_b = 1.1)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, memory_length_for_group_a = 0)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, memory_length_for_group_b = 0)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, common_memory_length = 0)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, num_initializations = 0)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, steps_per_initialization = 0)
            @test_throws ArgumentError SimConfig(game = TEST_GAME, num_agents = 10, group_a_ratio = 0.51)

            config0 = SimConfig(game = TEST_GAME, num_agents = 10, group_a_ratio = 0.0)
            @test config0.group_a_size == 0
            @test all(==(GROUP_B), assign_groups(config0))

            config_half = SimConfig(game = TEST_GAME, num_agents = 100, group_a_ratio = 0.5)
            @test config_half.group_a_size == 50
        end

        @testset "Payoff matrix sizes" begin
            @test_throws ArgumentError PairGame(
                ["1", "2"], ["1", "2"],
                [1.0 2.0 3.0; 4.0 5.0 6.0], ones(2, 2), ones(2, 2), ones(2, 2),
            )
            asymmetric = PairGame(
                ["L", "H"],
                ["L", "M", "H"],
                [1.0 0.0; 0.0 1.0],
                [1.0 2.0 3.0; 4.0 5.0 6.0],
                ones(3, 3),
                ones(3, 2),
            )
            @test length(asymmetric.strategy_labels_A) == 2
            @test length(asymmetric.strategy_labels_B) == 3
            config = SimConfig(game = asymmetric, num_agents = 4, group_a_ratio = 0.5)
            @test config.num_strategies_a == 2
            @test config.num_strategies_b == 3
        end
    end

    @testset "AgentPopulation" begin
        config = SimConfig(game = TEST_GAME, num_agents = 100, group_a_ratio = 0.3)
        pop = AgentPopulation(config)
        @test length(pop.agents) == 100
        @test pop.group_a_indices == collect(1:30)
        @test pop.group_b_indices == collect(31:100)
        @test [a.group for a in pop.agents] == assign_groups(config)
        @test all(a.id == i for (i, a) in enumerate(pop.agents))

        all_tc = AgentPopulation(
            SimConfig(
                game = TEST_GAME, num_agents = 20,
                type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 1.0,
            )
        )
        @test all(a.uses_type_conditioning for a in all_tc.agents)

        none_tc = AgentPopulation(
            SimConfig(
                game = TEST_GAME, num_agents = 20,
                type_conditioning_ratio_a = 0.0, type_conditioning_ratio_b = 0.0,
            )
        )
        @test all(!a.uses_type_conditioning for a in none_tc.agents)

        by_group = AgentPopulation(
            SimConfig(
                game = TEST_GAME, num_agents = 10, group_a_ratio = 0.4,
                type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 0.0,
            )
        )
        @test all(a.uses_type_conditioning for a in by_group.agents if a.group == GROUP_A)
        @test all(!a.uses_type_conditioning for a in by_group.agents if a.group == GROUP_B)

        Random.seed!(202)
        partial = AgentPopulation(
            SimConfig(
                game = TEST_GAME, num_agents = 1000,
                type_conditioning_ratio_a = 0.5, type_conditioning_ratio_b = 0.5,
            )
        )
        tc_count = count(a.uses_type_conditioning for a in partial.agents)
        @test 400 < tc_count < 600
    end

    @testset "MemorySystem" begin
        config = SimConfig(
            game = TEST_GAME,
            num_agents = 10,
            memory_length_for_group_a = 5,
            memory_length_for_group_b = 8,
            common_memory_length = 12,
        )
        mem = MemorySystem(config)
        @test size(mem.group_a_memories) == (10, 5)
        @test size(mem.group_b_memories) == (10, 8)
        @test size(mem.common_memories) == (10, 12)
        @test all(mem.group_a_memories .== MEMORY_PLACEHOLDER)
        @test all(mem.group_b_memories .== MEMORY_PLACEHOLDER)
        @test all(mem.common_memories .== MEMORY_PLACEHOLDER)
        @test all(mem.group_a_idx .== 1)

        _record_observation!(mem, 1, Int8(2), GROUP_B, config)
        @test mem.group_b_memories[1, 1] == Int8(2)
        @test mem.common_memories[1, 1] == Int8(2)
        @test all(mem.group_a_memories[1, :] .== MEMORY_PLACEHOLDER)

        ring = MemorySystem(SimConfig(game = TEST_GAME, num_agents = 2, memory_length_for_group_a = 3))
        length_a = 3
        for strategy in Int8[1, 2, 3, 4]
            _push_memory!(ring.group_a_memories, ring.group_a_idx, 1, strategy, length_a)
        end
        @test ring.group_a_memories[1, :] == Int8[4, 2, 3]
        @test ring.group_a_idx[1] == 2
    end

    @testset "Strategy functions" begin
        config = SimConfig(
            game = TEST_GAME, num_agents = 10,
            type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 1.0,
        )
        pop = AgentPopulation(config)
        mem = MemorySystem(config)
        agent1 = pop.agents[1]
        agent5 = pop.agents[5]
        payoffs = zeros(Float64, 3)
        optimal_strategies = Vector{Int}(undef, 3)

        Random.seed!(123)
        strategy, num_optimal, has_mem = determine_strategy(
            mem, agent1, agent5, config, payoffs, optimal_strategies,
        )
        @test 1 <= strategy <= 3
        @test num_optimal == 3
        @test has_mem == false

        response_game = pairgame([3.0 3.0 3.0; 5.0 5.0 0.0; 7.0 0.0 0.0])
        response_config = SimConfig(
            game = response_game, num_agents = 10,
            type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 1.0,
        )
        response_pop = AgentPopulation(response_config)
        response_mem = MemorySystem(response_config)
        for _ in 1:10
            _push_memory!(
                response_mem.group_b_memories, response_mem.group_b_idx, 1, Int8(1),
                response_config.memory_length_for_group_b,
            )
        end
        strategy, num_optimal, has_mem = determine_strategy(
            response_mem, response_pop.agents[1], response_pop.agents[5],
            response_config, payoffs, optimal_strategies,
        )
        @test strategy == Int8(3)
        @test num_optimal == 1
        @test has_mem == true

        # Column 1 payoffs sit inside and outside PAYOFF_TIE_EPS of the best.
        inside = 1.0 + PAYOFF_TIE_EPS / 2
        outside = 1.0 + 2 * PAYOFF_TIE_EPS
        tie_game = pairgame(
            [
                1.0 0.0 0.0
                1.0 0.0 0.0
                inside 0.0 0.0
            ]
        )
        tie_config = SimConfig(
            game = tie_game, num_agents = 10,
            type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 1.0,
        )
        tie_pop = AgentPopulation(tie_config)
        tie_mem = MemorySystem(tie_config)
        _push_memory!(
            tie_mem.group_b_memories, tie_mem.group_b_idx, 1, Int8(1),
            tie_config.memory_length_for_group_b,
        )
        _, num_optimal, has_mem = determine_strategy(
            tie_mem, tie_pop.agents[1], tie_pop.agents[5],
            tie_config, payoffs, optimal_strategies,
        )
        @test num_optimal == 3
        @test has_mem == true

        gap_game = pairgame(
            [
                1.0 0.0 0.0
                1.0 0.0 0.0
                outside 0.0 0.0
            ]
        )
        gap_config = SimConfig(
            game = gap_game, num_agents = 10,
            type_conditioning_ratio_a = 1.0, type_conditioning_ratio_b = 1.0,
        )
        gap_pop = AgentPopulation(gap_config)
        gap_mem = MemorySystem(gap_config)
        _push_memory!(
            gap_mem.group_b_memories, gap_mem.group_b_idx, 1, Int8(1),
            gap_config.memory_length_for_group_b,
        )
        strategy, num_optimal, has_mem = determine_strategy(
            gap_mem, gap_pop.agents[1], gap_pop.agents[5],
            gap_config, payoffs, optimal_strategies,
        )
        @test strategy == Int8(3)
        @test num_optimal == 1
        @test has_mem == true

        kept1, kept2 = override_strategies(
            NoOverride(), Int8(1), Int8(2),
            pop.agents[1], pop.agents[2],
            1, mem, pop, config,
        )
        @test (kept1, kept2) == (Int8(1), Int8(2))

        Random.seed!(7)
        pairs = match_agents(OnePair(), 1, mem, pop, config)
        @test length(pairs) == 1
        a1, a2 = only(pairs)
        @test a1 != a2
        @test 1 <= a1 <= config.num_agents
        @test 1 <= a2 <= config.num_agents

        fixed = SimConfig(
            game = TEST_GAME,
            num_agents = 4,
            steps_per_initialization = 1,
            matching = FixedPair(1, 2),
            random_seed = 1,
        )
        trial = run_simulation(fixed)
        filled = row -> any(!=(MEMORY_PLACEHOLDER), row)
        @test filled(trial.memory.common_memories[1, :])
        @test filled(trial.memory.common_memories[2, :])
        @test !filled(trial.memory.common_memories[3, :])
        @test !filled(trial.memory.common_memories[4, :])

        override_config = SimConfig(game = TEST_GAME, num_agents = 4, strategy_override = PlayMWhenEmpty())
        override_pop = AgentPopulation(override_config)
        override_mem = MemorySystem(override_config)
        empty_s1, empty_s2 = override_strategies(
            override_config.strategy_override,
            Int8(1), Int8(3),
            override_pop.agents[1], override_pop.agents[2],
            1, override_mem, override_pop, override_config,
        )
        @test (empty_s1, empty_s2) == (Int8(2), Int8(2))
        _push_memory!(
            override_mem.group_b_memories, override_mem.group_b_idx, 1, Int8(1),
            override_config.memory_length_for_group_b,
        )
        kept_s1, kept_s2 = override_strategies(
            override_config.strategy_override,
            Int8(1), Int8(3),
            override_pop.agents[1], override_pop.agents[2],
            1, override_mem, override_pop, override_config,
        )
        @test (kept_s1, kept_s2) == (Int8(1), Int8(2))
    end

    @testset "run_simulation" begin
        config = SimConfig(
            game = TEST_GAME,
            num_agents = 20,
            group_a_ratio = 0.3,
            steps_per_initialization = 100,
            random_seed = 42,
        )
        result = run_simulation(config)
        @test result isa TrialResult
        @test result.seed == 42
        @test result.memory isa MemorySystem
        @test haskey(result.counts, :a_remembers_b_slot_count)

        again = run_simulation(config)
        @test result.memory.group_a_memories == again.memory.group_a_memories
        @test result.memory.group_b_memories == again.memory.group_b_memories
        @test result.memory.common_memories == again.memory.common_memories

        callback_count = Ref(0)
        run_simulation(
            config;
            track_callback = (_step, _mem, _cfg, _population) -> (callback_count[] += 1),
            track_interval = 10,
        )
        @test callback_count[] == 10
    end
end
