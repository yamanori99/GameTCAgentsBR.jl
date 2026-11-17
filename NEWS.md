# Release notes

## 0.2.0 (unreleased)

- **`compute_payoff_outcome`**: `advantage` symbols are renamed to `:balanced`, `:payoff_a_higher`, and `:payoff_b_higher` (replacing `:fair`, `:a_advantage`, and `:b_advantage`). The 1% balance band is documented via internal constant `PAYOFF_BALANCE_REL_TOL` (`0.01`). No aliases.
- **Errors**: `run_batch` mismatched `trial_seeds` now raises `ArgumentError` (not `error(...)`). Constructor and analysis validation messages state what failed, which field, and how to fix (with examples).
- **`compute_payoff_outcome`**: Count vectors must have the same length as each dimension of a square payoff matrix; mismatched, shorter, or longer vectors now raise `ArgumentError` instead of returning wrong payoffs or throwing `BoundsError`.
- **`compute_payoff_outcome`**: The return value no longer includes `L_value` (use `payoff_matrix[1, 1]` when you need that quantity).
- **`PairGame`**: Games with more than 127 strategies now raise `ArgumentError` at construction (memory stores strategy codes as `Int8`).
- **`compute_payoff_outcome`**: Zero total payoff magnitude uses an exact zero check (`iszero`) rather than approximate equality.
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
