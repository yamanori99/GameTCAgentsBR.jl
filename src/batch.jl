# A batch of trials.

"""
    _derive_trial_seeds(config, trial_seeds) -> Vector{Int}

Return the given seeds, or draw one seed per trial.
"""
function _derive_trial_seeds(config::SimConfig, trial_seeds::Union{Nothing, Vector{Int}})
    if trial_seeds !== nothing
        length(trial_seeds) == config.num_initializations ||
            error("trial_seeds length must equal num_initializations")
        return trial_seeds
    end
    base = config.random_seed === nothing ? rand(Random.RandomDevice(), Int) : config.random_seed
    return rand(Random.Xoshiro(base), Int, config.num_initializations)
end

"""
    _batch_track_callback(track_callback, trial_idx, track_with_population)

Insert `trial_idx` into a batch tracking callback for `run_simulation`.
"""
function _batch_track_callback(track_callback, trial_idx::Int, track_with_population::Bool)
    track_callback === nothing && return nothing
    if track_with_population
        return (s, m, c, pop) -> track_callback(s, trial_idx, m, c, pop)
    else
        return (s, m, c, _pop) -> track_callback(s, trial_idx, m, c)
    end
end

"""
    _accumulate_trial_counts!(outcomes_aa, outcomes_ab, outcomes_ba, outcomes_bb, counts, num_strategies_max)

Count each strategy once when the stopping-step memory holds it.
"""
function _accumulate_trial_counts!(
        outcomes_aa, outcomes_ab, outcomes_ba, outcomes_bb,
        counts, num_strategies_max::Int
    )
    for strategy_idx in 1:num_strategies_max
        if counts.a_remembers_a_slot_count[strategy_idx] > 0
            outcomes_aa[strategy_idx] += 1
        end
        if counts.a_remembers_b_slot_count[strategy_idx] > 0
            outcomes_ab[strategy_idx] += 1
        end
        if counts.b_remembers_a_slot_count[strategy_idx] > 0
            outcomes_ba[strategy_idx] += 1
        end
        if counts.b_remembers_b_slot_count[strategy_idx] > 0
            outcomes_bb[strategy_idx] += 1
        end
    end
    return nothing
end

"""
    run_batch(config::SimConfig;
             track_callback=nothing,
             track_interval::Int=1000,
             trial_seeds::Union{Nothing,Vector{Int}}=nothing,
             track_with_population::Bool=false,
             on_trial_complete::Union{Function,Nothing}=nothing) -> NamedTuple

Run one `run_simulation` per trial seed. Without `trial_seeds`, the seeds are
drawn from `Xoshiro(config.random_seed)`, or from a fresh base seed when that
is unset.

`a_remembers_b_trial_count[i]` is how many trials ended with A remembering
B strategy `i`. The other fields are `<observer>_remembers_<actor>_trial_count`.
`trials` always contains one
`TrialResult` per trial.

`track_callback` is `(step, trial_idx, memory, config)` by default, or
`(step, trial_idx, memory, config, population)` when `track_with_population` is true.
`on_trial_complete` is `(trial_idx, trial_seed, counts, trial)`.
"""
function run_batch(
        config::SimConfig;
        track_callback = nothing,
        track_interval::Int = 1000,
        trial_seeds::Union{Nothing, Vector{Int}} = nothing,
        track_with_population::Bool = false,
        on_trial_complete::Union{Function, Nothing} = nothing
    )
    seeds = _derive_trial_seeds(config, trial_seeds)
    num_strategies_max = config.num_strategies
    outcomes_aa = zeros(Int, num_strategies_max)
    outcomes_ab = zeros(Int, num_strategies_max)
    outcomes_ba = zeros(Int, num_strategies_max)
    outcomes_bb = zeros(Int, num_strategies_max)
    trial_results = Vector{TrialResult}(undef, config.num_initializations)

    for trial_idx in 1:config.num_initializations
        callback = _batch_track_callback(track_callback, trial_idx, track_with_population)
        trial = run_simulation(
            config;
            seed = seeds[trial_idx],
            track_callback = callback,
            track_interval = track_interval,
        )
        trial_results[trial_idx] = trial
        if on_trial_complete !== nothing
            on_trial_complete(trial_idx, trial.seed, trial.counts, trial)
        end
        _accumulate_trial_counts!(
            outcomes_aa, outcomes_ab, outcomes_ba, outcomes_bb,
            trial.counts, num_strategies_max
        )
    end

    return (
        a_remembers_a_trial_count = outcomes_aa,
        a_remembers_b_trial_count = outcomes_ab,
        b_remembers_a_trial_count = outcomes_ba,
        b_remembers_b_trial_count = outcomes_bb,
        trials = trial_results,
    )
end
