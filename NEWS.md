# Release notes

## 0.1.2

- Group A is never larger than Group B.
- With `group_a_ratio = 0.5` and an odd number of agents, the groups cannot be equal: Group A is one agent smaller, and a warning is printed (once per session). Even populations, and any other ratio, match 0.1.1.
- The only trial-result change from 0.1.1 is the odd 50/50 case with 3, 7, 11, ... agents (for 7 agents, Group A was 4 and is now 3). With 5, 9, 13, ... agents the sizes are unchanged; only the warning is new.
- A `SimConfig` that could not run correctly now raises `ArgumentError` when you construct it: one agent, a `group_a_size` that does not match `group_a_ratio`, or a `num_strategies` that does not match the game. Previously these either failed later in the trial or ran with inconsistent sizes or counts.
