#!/usr/bin/env julia
# CLI demo: Nash-demand setups (not part of the package module).
#
# Each `_demo_setup` branch builds `PairGame` + `SimConfig` inline — copy a
# branch and swap labels, matrices, and config.
#
# Args: [case] [mode], or none → l45 counts.
#   case: l40one | l40 | l05 | l10 | l15 | l20 | l25 | l30 | l35 | l45
#   mode: counts | traj
#
# Usage:
#   julia --project=demo demo/run.jl
#   julia --project=demo demo/run.jl l20 counts
#   julia --project=demo demo/run.jl l20 traj --samples 50 --seed 7 --steps 100

using GameTCAgentsBR
using Printf
using ProgressMeter
using Random
using UnicodePlots

const _DEMO_CASES = (
    :l40one, :l40, :l05, :l10, :l15, :l20, :l25, :l30, :l35, :l45,
)
const DEFAULT_DEMO_CASE = :l45
const TRAJ_TARGET_SAMPLES = 200

struct DemoOptions
    case::Symbol
    trajectory_mode::Bool
    samples::Int
    seed::Union{Int, Nothing}
    steps::Union{Int, Nothing}
    show_help::Bool
end

function _rebuild_config(
        config::SimConfig;
        num_initializations = config.num_initializations,
        steps_per_initialization = config.steps_per_initialization,
        random_seed = config.random_seed,
    )
    return SimConfig(;
        game = config.game,
        num_agents = config.num_agents,
        group_a_ratio = config.group_a_ratio,
        type_conditioning_ratio_a = config.type_conditioning_ratio_a,
        type_conditioning_ratio_b = config.type_conditioning_ratio_b,
        memory_length_for_group_a = config.memory_length_for_group_a,
        memory_length_for_group_b = config.memory_length_for_group_b,
        common_memory_length = config.common_memory_length,
        strategy_override = config.strategy_override,
        matching = config.matching,
        num_initializations = num_initializations,
        steps_per_initialization = steps_per_initialization,
        random_seed = random_seed,
    )
end

function _demo_setup(case::Symbol)
    if case == :l40one
        # Same payoff and run size as l40. Group A is empty, so every agent is Group B.
        # Run: julia --project=demo demo/run.jl l40one counts
        title = "GameTCAgentsBR demo (Nash demand L=4.0, one group)"
        demand_payoff = [
            4.0 4.0 4.0
            5.0 5.0 0.0
            6.0 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.0,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    elseif case == :l05
        # Run: julia --project=demo demo/run.jl l05 counts
        title = "GameTCAgentsBR demo (Nash demand L=0.5)"
        demand_payoff = [
            0.5 0.5 0.5
            5.0 5.0 0.0
            9.5 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.3,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    elseif case == :l10
        # Run: julia --project=demo demo/run.jl l10 counts
        title = "GameTCAgentsBR demo (Nash demand L=1.0)"
        demand_payoff = [
            1.0 1.0 1.0
            5.0 5.0 0.0
            9.0 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.3,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    elseif case == :l15
        # Run: julia --project=demo demo/run.jl l15 counts
        title = "GameTCAgentsBR demo (Nash demand L=1.5)"
        demand_payoff = [
            1.5 1.5 1.5
            5.0 5.0 0.0
            8.5 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.3,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    elseif case == :l20
        # Run: julia --project=demo demo/run.jl l20 counts
        title = "GameTCAgentsBR demo (Nash demand L=2.0)"
        demand_payoff = [
            2.0 2.0 2.0
            5.0 5.0 0.0
            8.0 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.3,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    elseif case == :l25
        # Run: julia --project=demo demo/run.jl l25 counts
        title = "GameTCAgentsBR demo (Nash demand L=2.5)"
        demand_payoff = [
            2.5 2.5 2.5
            5.0 5.0 0.0
            7.5 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.3,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    elseif case == :l30
        # Run: julia --project=demo demo/run.jl l30 counts
        title = "GameTCAgentsBR demo (Nash demand L=3.0)"
        demand_payoff = [
            3.0 3.0 3.0
            5.0 5.0 0.0
            7.0 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.3,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    elseif case == :l35
        # Run: julia --project=demo demo/run.jl l35 counts
        title = "GameTCAgentsBR demo (Nash demand L=3.5)"
        demand_payoff = [
            3.5 3.5 3.5
            5.0 5.0 0.0
            6.5 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.3,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    elseif case == :l40
        # Run: julia --project=demo demo/run.jl l40 counts
        title = "GameTCAgentsBR demo (Nash demand L=4.0)"
        demand_payoff = [
            4.0 4.0 4.0
            5.0 5.0 0.0
            6.0 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.3,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    elseif case == :l45
        # Run: julia --project=demo demo/run.jl l45 counts
        title = "GameTCAgentsBR demo (Nash demand L=4.5)"
        demand_payoff = [
            4.5 4.5 4.5
            5.0 5.0 0.0
            5.5 0.0 0.0
        ]
        game = PairGame(["L", "M", "H"], demand_payoff)
        config = SimConfig(;
            game = game,
            num_agents = 20,
            group_a_ratio = 0.3,
            type_conditioning_ratio_a = 1.0,
            type_conditioning_ratio_b = 1.0,
            memory_length_for_group_a = 10,
            memory_length_for_group_b = 10,
            common_memory_length = 20,
            strategy_override = NoOverride(),
            matching = OnePair(),
            num_initializations = 10_000,
            steps_per_initialization = 5_000,
            random_seed = nothing,
        )
    else
        throw(ArgumentError("unknown demo case: $(case)"))
    end
    return title, config
end

function print_usage(io::IO = stdout)
    println(io, "Usage: julia --project=demo demo/run.jl [case] [mode] [options]")
    println(io, "  case∈{l40one,l40,l05,l10,l15,l20,l25,l30,l35,l45} (default l45)")
    println(io, "  mode∈{counts,traj} (default counts)")
    println(io, "  --samples N   trajectory target sample count (default: $(TRAJ_TARGET_SAMPLES))")
    println(io, "  --steps N     override steps_per_initialization")
    println(io, "  --seed N      override random seed")
    println(io, "  -h, --help")
    return
end

function _parse_int_option(flag::String, value::String)
    n = tryparse(Int, value)
    n === nothing && throw(ArgumentError("$(flag) requires an integer, got $(repr(value))"))
    return n
end

function _take_option_value!(args, i, flag)
    i < length(args) || throw(ArgumentError("$(flag) requires a value"))
    return args[i + 1], i + 1
end

function _parse_demo_case(args)
    case = DEFAULT_DEMO_CASE
    mode = :counts
    samples = TRAJ_TARGET_SAMPLES
    seed = nothing
    steps = nothing
    show_help = false
    saw_case = false
    saw_mode = false
    i = 1
    while i <= length(args)
        a = args[i]
        if a == "-h" || a == "--help"
            show_help = true
        elseif startswith(a, "--samples=")
            samples = _parse_int_option("--samples", a[(length("--samples=") + 1):end])
        elseif a == "--samples"
            value, i = _take_option_value!(args, i, a)
            samples = _parse_int_option(a, value)
        elseif startswith(a, "--steps=")
            steps = _parse_int_option("--steps", a[(length("--steps=") + 1):end])
        elseif a == "--steps"
            value, i = _take_option_value!(args, i, a)
            steps = _parse_int_option(a, value)
        elseif startswith(a, "--seed=")
            seed = _parse_int_option("--seed", a[(length("--seed=") + 1):end])
        elseif a == "--seed"
            value, i = _take_option_value!(args, i, a)
            seed = _parse_int_option(a, value)
        elseif a == "counts"
            saw_mode && throw(ArgumentError("mode specified more than once"))
            mode = :counts
            saw_mode = true
        elseif a == "traj" || a == "trajectory"
            saw_mode && throw(ArgumentError("mode specified more than once"))
            mode = :traj
            saw_mode = true
        else
            token = Symbol(a)
            any(case -> case === token, _DEMO_CASES) ||
                throw(ArgumentError("unknown argument: $(a)"))
            saw_case && throw(ArgumentError("case specified more than once"))
            case = token
            saw_case = true
        end
        i += 1
    end
    samples > 0 || throw(ArgumentError("--samples must be positive"))
    steps === nothing || steps > 0 || throw(ArgumentError("--steps must be positive"))
    return DemoOptions(case, mode === :traj, samples, seed, steps, show_help)
end

function _trajectory_config(config::SimConfig, options::DemoOptions)
    steps = options.steps === nothing ? config.steps_per_initialization : options.steps
    seed = options.seed === nothing ? config.random_seed : options.seed
    return _rebuild_config(
        config;
        num_initializations = 1,
        steps_per_initialization = steps,
        random_seed = seed,
    )
end

function _apply_mode(config::SimConfig, options::DemoOptions)
    if options.trajectory_mode
        return _trajectory_config(config, options)
    end
    options.seed === nothing && options.steps === nothing && return config
    return _rebuild_config(
        config;
        steps_per_initialization = options.steps === nothing ? config.steps_per_initialization : options.steps,
        random_seed = options.seed === nothing ? config.random_seed : options.seed,
    )
end

function _trial_seeds(config::SimConfig, options::DemoOptions)
    if options.trajectory_mode
        seed = options.seed === nothing ? config.random_seed : options.seed
        seed === nothing && (seed = rand(Random.RandomDevice(), Int))
        return [seed]
    end
    base = options.seed === nothing ? config.random_seed : options.seed
    base === nothing && (base = rand(Random.RandomDevice(), Int))
    rng = Random.Xoshiro(base)
    return rand(rng, Int, config.num_initializations)
end

function default_traj_interval(cfg::SimConfig)
    return max(1, cld(cfg.steps_per_initialization, TRAJ_TARGET_SAMPLES))
end

function effective_traj_interval(cfg::SimConfig, samples::Int)
    samples <= 0 && return default_traj_interval(cfg)
    return max(1, cld(cfg.steps_per_initialization, samples))
end

mutable struct ShareSeries
    interval::Int
    rng::AbstractRNG
    steps::Vector{Int}
    group_a_against_group_a::Vector{Vector{Float64}}
    group_a_against_group_b::Vector{Vector{Float64}}
    group_b_against_group_a::Vector{Vector{Float64}}
    group_b_against_group_b::Vector{Vector{Float64}}
    payoff_gap::Vector{Float64}
end

function ShareSeries(interval::Int, rng::AbstractRNG)
    interval > 0 || throw(ArgumentError("interval must be positive"))
    return ShareSeries(
        interval,
        rng,
        Int[],
        Vector{Vector{Float64}}(),
        Vector{Vector{Float64}}(),
        Vector{Vector{Float64}}(),
        Vector{Vector{Float64}}(),
        Float64[],
    )
end

function _push_share!(series, share::Vector{Float64})
    isempty(share) || push!(series, copy(share))
    return nothing
end

function (rec::ShareSeries)(step, memory, config, population)
    step % rec.interval == 0 || return nothing
    shares = sample_strategy_shares(memory, config, population, rec.rng; step)
    push!(rec.steps, step)
    _push_share!(rec.group_a_against_group_a, shares.group_a_against_group_a)
    _push_share!(rec.group_a_against_group_b, shares.group_a_against_group_b)
    _push_share!(rec.group_b_against_group_a, shares.group_b_against_group_a)
    _push_share!(rec.group_b_against_group_b, shares.group_b_against_group_b)
    n_a = length(population.group_a_indices)
    n_b = length(population.group_b_indices)
    if n_a > 0 && n_b > 0
        a_counts = round.(Int, shares.group_a_against_group_b .* n_a)
        b_counts = round.(Int, shares.group_b_against_group_a .* n_b)
        gap = compute_payoff_outcome(a_counts, b_counts, config.game.U).payoff_gap
        push!(rec.payoff_gap, isnan(gap) ? 0.0 : gap)
    end
    return nothing
end

function _progress_callback(progress, rec::Union{ShareSeries, Nothing}, completed_steps::Ref{Int})
    return function (step, trial_idx, mem, config, population = nothing)
        completed_steps[] = (trial_idx - 1) * config.steps_per_initialization + step
        ProgressMeter.update!(progress, completed_steps[])
        rec === nothing && return
        population === nothing && return
        rec(step, mem, config, population)
        return
    end
end

function _print_matrix(io::IO, title::AbstractString, M::AbstractMatrix, row_labels, col_labels)
    println(io, title)
    print(io, "      ")
    for j in axes(M, 2)
        print(io, lpad(col_labels[j], 7))
    end
    println(io)
    for i in axes(M, 1)
        print(io, lpad(row_labels[i], 5), " ")
        for j in axes(M, 2)
            print(io, lpad(@sprintf("%.1f", M[i, j]), 7))
        end
        println(io)
    end
    return
end

const _DEMO_SEPARATOR = "─"^60

function print_configuration(io::IO, config::SimConfig)
    game = config.game
    n_b = config.num_agents - config.group_a_size
    seed = config.random_seed === nothing ? "random" : string(config.random_seed)
    println(io, "Configuration")
    println(io, "  population       $(config.num_agents)  [A=$(config.group_a_size), B=$(n_b)]")
    println(
        io,
        "  type-conditioning A=$(round(config.type_conditioning_ratio_a * 100; digits = 1))%, B=$(round(config.type_conditioning_ratio_b * 100; digits = 1))%",
    )
    println(
        io,
        "  memory           A=$(config.memory_length_for_group_a), B=$(config.memory_length_for_group_b), common=$(config.common_memory_length)",
    )
    println(
        io,
        "  run              $(config.num_initializations) initializations × $(config.steps_per_initialization) steps, seed=$(seed)",
    )
    println(io)
    _print_matrix(
        io,
        "Payoff (row = own strategy, column = opponent)",
        game.U,
        game.labels,
        game.labels,
    )
    return
end

print_configuration(config::SimConfig) = print_configuration(stdout, config)

function _print_counts_table(io::IO, labels, rows, total_trials::Int)
    print(io, rpad("remembered strategies", 41))
    for label in labels
        print(io, lpad(label, 10))
    end
    println(io)
    for (name, counts) in rows
        print(io, rpad(name, 41))
        for i in eachindex(labels)
            pct = total_trials > 0 ? counts[i] / total_trials * 100.0 : 0.0
            print(io, lpad(@sprintf("%5.1f%%", pct), 10))
        end
        println(io)
    end
    return
end

function _print_demand_summary(io::IO, results, config::SimConfig)
    a_counts = results.b_remembers_a_trial_count
    b_counts = results.a_remembers_b_trial_count
    labels = config.game.labels
    n = min(length(labels), length(a_counts), length(b_counts))
    n == 0 && return
    demands = [config.game.U[i, 1] for i in 1:n]
    a_total = sum(a_counts[i] for i in 1:n)
    b_total = sum(b_counts[i] for i in 1:n)
    a_total > 0 && b_total > 0 || return
    a_weighted = sum(demands[i] * a_counts[i] for i in 1:n) / a_total
    b_weighted = sum(demands[i] * b_counts[i] for i in 1:n) / b_total
    @printf(
        io,
        "Cross-group trial-count-weighted demand (diagnostic, not payoff)\n",
    )
    @printf(
        io,
        "  B remembers A strategies: %.2f   A remembers B strategies: %.2f\n",
        a_weighted,
        b_weighted,
    )
    return
end

function print_results(io::IO, results, config::SimConfig; show_summary::Bool = true)
    println(io)
    println(io, _DEMO_SEPARATOR)
    println(io, "Final-memory trial counts")
    println(io, _DEMO_SEPARATOR)
    labels = config.game.labels
    n_trials = config.num_initializations
    println(io)
    println(io, "Trials remembering each strategy across $(n_trials) initializations")
    rows = if config.group_a_size == 0
        ("B remembers B strategies" => results.b_remembers_b_trial_count,)
    else
        (
            "A remembers A strategies" => results.a_remembers_a_trial_count,
            "B remembers A strategies" => results.b_remembers_a_trial_count,
            "A remembers B strategies" => results.a_remembers_b_trial_count,
            "B remembers B strategies" => results.b_remembers_b_trial_count,
        )
    end
    _print_counts_table(io, labels, rows, n_trials)
    println(io, "  Note: strategies can coexist in memory, so rows need not sum to 100%.")
    if show_summary
        println(io)
        _print_demand_summary(io, results, config)
    end
    return
end

print_results(results, config::SimConfig; show_summary::Bool = true) =
    print_results(stdout, results, config; show_summary = show_summary)

function _plot_trajectory_block(io::IO, title::String, rec_steps, data, labels, xmax::Int)
    isempty(data) && return
    n = min(length(labels), length(data[1]))
    n == 0 && return
    ys = hcat(data...)'
    names = labels[1:n]
    plt = lineplot(
        rec_steps,
        ys;
        name = names,
        title = title,
        xlabel = "step",
        ylabel = "share",
        ylim = (0, 1),
        xlim = (0, xmax),
        width = 50,
        height = 10,
    )
    show(io, plt)
    println(io)
    final_freqs = data[end]
    order = sortperm(final_freqs[1:n]; rev = true)
    summary = join((@sprintf("%s %.0f%%", names[i], 100 * final_freqs[i]) for i in order), "  ")
    println(io, "  final  ", summary)
    println(io)
    return
end

function _print_inequality_analysis(io::IO, rec::ShareSeries, config::SimConfig)
    isempty(rec.payoff_gap) && return
    plt = lineplot(
        rec.steps,
        rec.payoff_gap;
        title = "Payoff gap (0=equal, 1=unequal)",
        xlabel = "step",
        ylabel = "gap",
        ylim = (0, 1),
        xlim = (0, config.steps_per_initialization),
        width = 50,
        height = 8,
    )
    show(io, plt)
    println(io)
    println(io)
    n_a = config.group_a_size
    n_b = config.num_agents - config.group_a_size
    final_ab_counts = round.(Int, rec.group_a_against_group_b[end] .* n_a)
    final_ba_counts = round.(Int, rec.group_b_against_group_a[end] .* n_b)
    final_result = compute_payoff_outcome(final_ab_counts, final_ba_counts, config.game.U)
    advantage_str = final_result.advantage == :fair ? "approximately equal" :
        final_result.advantage == :a_advantage ? "A payoff higher" :
        final_result.advantage == :b_advantage ? "B payoff higher" :
        "Unknown"
    @printf(
        io,
        "Final independent-share payoffs  gap %.3f   A %.2f   B %.2f   %s\n",
        final_result.payoff_gap,
        final_result.payoff_A,
        final_result.payoff_B,
        advantage_str,
    )
    return
end

function _print_trajectory(io::IO, rec::ShareSeries, config::SimConfig)
    isempty(rec.steps) && return
    labels = config.game.labels
    xmax = config.steps_per_initialization
    println(io)
    println(io, _DEMO_SEPARATOR)
    println(io, "Single-trial sampled strategy shares")
    println(io, _DEMO_SEPARATOR)
    println(io, "Sampled next strategies against one representative opponent from each populated group")
    _plot_trajectory_block(io, "Strategies by Group A; opponent from Group A", rec.steps, rec.group_a_against_group_a, labels, xmax)
    _plot_trajectory_block(io, "Strategies by Group A; opponent from Group B", rec.steps, rec.group_a_against_group_b, labels, xmax)
    _plot_trajectory_block(io, "Strategies by Group B; opponent from Group A", rec.steps, rec.group_b_against_group_a, labels, xmax)
    _plot_trajectory_block(io, "Strategies by Group B; opponent from Group B", rec.steps, rec.group_b_against_group_b, labels, xmax)
    _print_inequality_analysis(io, rec, config)
    return
end

function _run_demo(config::SimConfig, options::DemoOptions; io::IO = stdout)
    total_steps = config.num_initializations * config.steps_per_initialization
    progress = Progress(total_steps; dt = 0.5, showspeed = true, desc = "  Progress: ")
    rec = nothing
    track_interval = max(1, Int(floor(config.steps_per_initialization / 100)))
    if options.trajectory_mode
        interval = effective_traj_interval(config, options.samples)
        seed = first(_trial_seeds(config, options))
        rec = ShareSeries(interval, Random.Xoshiro(seed))
        track_interval = max(1, interval)
        println(io, "Time-series sampling interval: every $(interval) steps")
        println(io)
    end
    completed_steps = Ref(0)
    callback = _progress_callback(progress, rec, completed_steps)
    results = run_batch(
        config;
        track_callback = callback,
        track_interval = track_interval,
        trial_seeds = _trial_seeds(config, options),
        track_with_population = options.trajectory_mode,
    )
    ProgressMeter.finish!(progress)
    if rec === nothing
        print_results(io, results, config)
    else
        _print_trajectory(io, rec, config)
    end
    return results, rec
end

function _show_model_demo(options::DemoOptions; io::IO = stdout)
    title, config = _demo_setup(options.case)
    config = _apply_mode(config, options)
    println(io, _DEMO_SEPARATOR)
    println(io, title)
    println(io, _DEMO_SEPARATOR)
    print_configuration(io, config)
    return _run_demo(config, options; io = io)
end

function main(args = ARGS)::Cint
    try
        options = _parse_demo_case(args)
        if options.show_help
            print_usage()
            return 0
        end
        _show_model_demo(options)
        return 0
    catch e
        if e isa ArgumentError
            println(stderr, "Error: ", e.msg)
            print_usage(stderr)
            return 1
        end
        rethrow()
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
