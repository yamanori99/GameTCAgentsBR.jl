# Release notes

## 0.1.2

### `SimConfig`

- `num_agents` must be at least 2.
- `group_a_size` and `num_strategies` must match the derived values. A keyword that disagrees raises `ArgumentError`.
- Group A size is `min(round(Int, num_agents * group_a_ratio), num_agents ÷ 2)` (ties round to even). Group A is never larger than Group B.
- `group_a_ratio = 0.5` with an odd `num_agents` still constructs. Group A is one smaller than Group B, and a warning is emitted.

Simulation results change when `group_a_ratio = 0.5` and `num_agents` is odd (3, 7, 11, …). Group A is one smaller than in 0.1.1 (for example 7 agents: A=4 then, A=3 now). Even populations and any other ratio are unchanged.

### Packaging

- The package version lives only in `Project.toml`. The `VERSION` file is removed.
- Unused `Printf` is no longer a package dependency. The demo and tests still declare it themselves.
