using GameTCAgentsBR
using Random
using Test

include(joinpath(@__DIR__, "..", "demo", "run.jl"))

function _fast_config(base::SimConfig)
    return _rebuild_config(
        base;
        num_initializations = 2,
        steps_per_initialization = 20,
        random_seed = 1,
    )
end

@testset "Demo script utilities" begin
    @testset "one-group case" begin
        title, config = _demo_setup(:l40one)
        _, two = _demo_setup(:l40)
        @test occursin("L=4.0", title)
        @test occursin("one group", title)
        @test config.group_a_ratio == 0.0
        @test config.group_a_size == 0
        @test config.game.payoff_BB == two.game.payoff_BB
        @test config.num_agents == two.num_agents
        @test config.type_conditioning_ratio_a == two.type_conditioning_ratio_a
        @test config.type_conditioning_ratio_b == two.type_conditioning_ratio_b
        @test config.num_initializations == two.num_initializations
        @test config.steps_per_initialization == two.steps_per_initialization
        @test _DEMO_CASES[1] === :l40one
        @test _DEMO_CASES[2] === :l40
        opts = _parse_demo_case(["l40one"])
        @test opts.case === :l40one
    end

    @testset "nine cases" begin
        expected = (
            :l05 => 0.5,
            :l10 => 1.0,
            :l15 => 1.5,
            :l20 => 2.0,
            :l25 => 2.5,
            :l30 => 3.0,
            :l35 => 3.5,
            :l40 => 4.0,
            :l45 => 4.5,
        )
        for (case, L) in expected
            title, config = _demo_setup(case)
            @test occursin("L=$(L)", title)
            @test config.game.payoff_AA[1, 1] == L
            @test config.game.payoff_AA[2, 2] == 5.0
            @test config.game.payoff_AA[3, 1] == 10.0 - L
            opts = _parse_demo_case([String(case)])
            @test opts.case === case
            @test !opts.trajectory_mode
        end
        _, reference = _demo_setup(:l45)
        @test reference.game.strategy_labels_A == ["L", "M", "H"]
        @test reference.game.strategy_labels_B == ["L", "M", "H"]
        @test reference.num_agents == 20
        @test reference.group_a_ratio == 0.3
        @test reference.memory_length_for_group_a == 10
        @test reference.memory_length_for_group_b == 10
        @test reference.common_memory_length == 20
        @test reference.num_initializations == 10_000
        @test reference.steps_per_initialization == 5_000
    end

    @testset "CLI parsing" begin
        defaults = _parse_demo_case(String[])
        @test defaults.case === :l45
        @test !defaults.trajectory_mode
        @test defaults.samples == TRAJ_TARGET_SAMPLES
        @test defaults.seed === nothing
        @test defaults.steps === nothing

        traj = _parse_demo_case(["l20", "traj", "--samples", "50", "--seed", "7", "--steps", "100"])
        @test traj.case === :l20
        @test traj.trajectory_mode
        @test traj.samples == 50
        @test traj.seed == 7
        @test traj.steps == 100

        @test _parse_demo_case(["traj"]).trajectory_mode
        @test !_parse_demo_case(["counts"]).trajectory_mode
        @test_throws ArgumentError _parse_demo_case(["basin"])
        @test _parse_demo_case(["--samples=40"]).samples == 40
        @test _parse_demo_case(["-h"]).show_help
        @test_throws ArgumentError _parse_demo_case(["unknown"])
        @test_throws ArgumentError _parse_demo_case(["--steps", "0"])
        @test_throws ArgumentError _parse_demo_case(["l05", "l10"])
    end

    @testset "trajectory config and seeds" begin
        _, config = _demo_setup(:l45)
        opts = DemoOptions(:l45, true, 40, 11, 80, false)
        traj_cfg = _trajectory_config(config, opts)
        @test traj_cfg.num_initializations == 1
        @test traj_cfg.steps_per_initialization == 80
        @test traj_cfg.random_seed == 11
        @test _trial_seeds(traj_cfg, opts) == [11]

        _, one_group = _demo_setup(:l40one)
        one_group_opts = DemoOptions(:l40one, true, 40, 11, 80, false)
        one_cfg = _trajectory_config(one_group, one_group_opts)
        @test one_cfg.group_a_size == 0
        @test one_cfg.num_initializations == 1

        counts = DemoOptions(:l45, false, 200, 5, nothing, false)
        seeds = _trial_seeds(config, counts)
        @test length(seeds) == config.num_initializations
        @test seeds == rand(Random.Xoshiro(5), Int, config.num_initializations)
    end

    @testset "configuration and results IO" begin
        _, config = _demo_setup(:l20)
        buf = IOBuffer()
        print_configuration(buf, config)
        text = String(take!(buf))
        @test occursin("Configuration", text)
        @test occursin("Payoff (row = own strategy, column = opponent)", text)
        @test occursin("L", text)
        @test occursin("M", text)
        @test occursin("H", text)

        results = (
            a_remembers_a_trial_count = [10, 0, 0],
            a_remembers_b_trial_count = [0, 10, 0],
            b_remembers_a_trial_count = [0, 0, 10],
            b_remembers_b_trial_count = [5, 5, 0],
        )
        print_results(buf, results, config)
        out = String(take!(buf))
        @test occursin("Final-memory trial counts", out)
        @test occursin("A remembers A strategies", out)
        @test occursin("A remembers B strategies", out)
        @test occursin("rows need not sum to 100%", out)
        @test occursin("diagnostic, not payoff", out)

        usage = IOBuffer()
        print_usage(usage)
        usage_text = String(take!(usage))
        @test occursin("Usage: julia --project=demo demo/run.jl", usage_text)
        @test occursin("[case] [mode]", usage_text)
        @test occursin("--samples", usage_text)
        @test occursin("l40one", usage_text)
        @test occursin("l05", usage_text)
        @test occursin("l45", usage_text)
    end

    @testset "trajectory intervals" begin
        _, cfg = _demo_setup(:l45)
        cfg = _rebuild_config(cfg; steps_per_initialization = 500)
        @test default_traj_interval(cfg) == 3
        @test effective_traj_interval(cfg, 50) == 10
        @test effective_traj_interval(cfg, 0) == default_traj_interval(cfg)
        @test effective_traj_interval(cfg, -5) == default_traj_interval(cfg)
    end

    @testset "group indices for trajectory reps" begin
        _, config = _demo_setup(:l45)
        config = _fast_config(config)
        population = AgentPopulation(config)
        mem = MemorySystem(config)
        rec = ShareSeries(1, Random.Xoshiro(1))
        rec(1, mem, config, population)
        @test length(rec.steps) == 1
        @test length(rec.group_a_against_group_a[1]) == config.num_strategies_a
    end

    @testset "one-group trajectory" begin
        _, one_group = _demo_setup(:l40one)
        one_opts = DemoOptions(:l40one, true, 5, 2, 20, false)
        one_cfg = _trajectory_config(_fast_config(one_group), one_opts)
        _, one_rec = _run_demo(one_cfg, one_opts; io = IOBuffer())
        @test one_rec isa ShareSeries
        @test one_rec.steps == [4, 8, 12, 16, 20]
        @test isempty(one_rec.group_a_against_group_a)
        @test isempty(one_rec.group_a_against_group_b)
        @test isempty(one_rec.payoff_gap)
    end
end
