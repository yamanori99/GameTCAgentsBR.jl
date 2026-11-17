# Release notes

## 0.2.0 (unreleased)

### Fail closed (explicit configuration)

- **`SimConfig`**: Model-defining keywords (`num_agents`, `group_a_size`, type-conditioning ratios, memory lengths, trial counts, and steps) have no defaults; omitting one raises `ArgumentError` naming the field and an example. Only `strategy_override` (`NoOverride()`), `matching` (`OnePair()`), and `random_seed` (`nothing`) may be omitted.
- **`SimConfig`**: `group_a_ratio` is removed. Set `group_a_size` explicitly (agent count in Group A, not a fraction). The odd-`num_agents` `@warn` for a 50/50 ratio is gone with the ratio field.
- **`SimConfig`**: The `num_strategies` field is removed. Use `num_strategies(config)` (`size(game.U, 1)`).
- **`PairGame`**: Only `PairGame(labels, U, play_a, play_b)` remains. `play_a` and `play_b` are required (no all-strategies default). `PairGame(U)` and keyword defaults for playable sets raise `MethodError`; pass `1:n` explicitly.
- **`count_final_strategies`**: Out-of-range strategy codes in memory raise `ArgumentError` with agent and slot (placeholder `-1` slots remain ignored).

### Payoffs and analysis

- **`compute_payoff_outcome`**: `advantage` symbols are `:balanced`, `:payoff_a_higher`, and `:payoff_b_higher` (replacing `:fair`, `:a_advantage`, and `:b_advantage`). The 1% balance band is documented via `PAYOFF_BALANCE_REL_TOL` (`0.01`). No aliases.
- **`compute_payoff_outcome`**: When either count vector sums to zero, `payoff_*` and `advantage` are `missing` with `missing_reason = :empty_strategy_counts` (replacing `NaN` and `:unknown`). On success, `missing_reason` is `missing`.
- **`compute_payoff_outcome`**: Count vectors must have the same length as each dimension of a square payoff matrix; mismatched lengths raise `ArgumentError` with lengths and an example.
- **`compute_payoff_outcome`**: The return value no longer includes `L_value` (use `payoff_matrix[1, 1]` when you need that quantity).
- **`compute_payoff_outcome`**: Zero total payoff magnitude uses an exact zero check (`iszero`) rather than approximate equality.

### Errors and demo CLI

- **Errors**: Constructor, batch, and analysis validation messages state what failed, which field, and how to fix (with examples). `run_batch` mismatched `trial_seeds` raises `ArgumentError` (not `error(...)`).
- **`demo/run.jl`**: No arguments prints usage to stderr and exits with code 2 (no implicit default run). `-h` / `--help` print usage to stdout and exit 0. Usage errors print an actionable rewrite hint to stderr and exit 2.
- **`demo/run.jl`**: The `trajectory` mode alias is removed; pass `traj` instead.
- **`demo/run.jl`**: Trajectory payoff-gap samples record `missing` with a reason when independent-share payoffs are undefined, instead of substituting `0.0`.
- **`demo/run.jl`**: `effective_traj_interval` raises `ArgumentError` when `samples <= 0` instead of falling back to the default interval.

### RNG, matching, and overrides

- **`PairGame`**: Games with more than 127 strategies now raise `ArgumentError` at construction (memory stores strategy codes as `Int8`).
- **`run_simulation`**: Uses a trial-local `Xoshiro(seed)` instead of `Random.seed!`, so the caller's default RNG is unchanged. The same integer seed no longer reproduces 0.1.x memory trajectories.
- **`match_agents`**: `run_simulation` passes a sixth argument `rng::AbstractRNG`. Custom `MatchingRule` methods must add this parameter (no default). A 0.1.x five-argument signature raises `MethodError` during a trial.
- **`AgentPopulation`**: The one-argument `AgentPopulation(config)` constructor is removed. Pass `AgentPopulation(config, rng)` (for example `AgentPopulation(config, Xoshiro(seed))`).
- **`determine_strategy`**: The `rng` argument is required (no default `Random.default_rng()`).
- **`sample_strategy_shares`**: The `rng` argument is required (no default `Random.default_rng()`). Pass the same trial RNG you use in `track_callback`, for example `sample_strategy_shares(memory, config, population, rng; step)`.
- **`run_simulation`**: A missing seed (`seed` keyword and `config.random_seed` both `nothing`) raises `ArgumentError` instead of drawing from `RandomDevice`. Set `random_seed = 1234` on `SimConfig`, call `run_simulation(config; seed = 1234)`, or generate a seed explicitly (for example `seed = rand(Random.RandomDevice(), Int)`).
- **`run_batch`**: Without `trial_seeds`, `config.random_seed` must be set; otherwise `ArgumentError`. Explicit `trial_seeds = [s1, s2, ...]` remains valid when `random_seed` is unset.
- **`override_strategies`**: After an override, each returned strategy must belong to that agent's group playable set (`playable_A` / `playable_B`); otherwise `run_simulation` and `sample_strategy_shares` raise `ArgumentError`.

## 0.1.2

- Group A is never larger than Group B.
- With `group_a_ratio = 0.5` and an odd number of agents, the groups cannot be equal: Group A is one agent smaller, and a warning is printed (once per session). Even populations, and any other ratio, match 0.1.1.
- The only trial-result change from 0.1.1 is the odd 50/50 case with 3, 7, 11, ... agents (for 7 agents, Group A was 4 and is now 3). With 5, 9, 13, ... agents the sizes are unchanged; only the warning is new.
- A `SimConfig` that could not run correctly now raises `ArgumentError` when you construct it: one agent, a `group_a_size` that does not match `group_a_ratio`, or a `num_strategies` that does not match the game. Previously these either failed later in the trial or ran with inconsistent sizes or counts.