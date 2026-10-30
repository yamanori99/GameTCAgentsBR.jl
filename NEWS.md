# Release notes

## 0.1.2

- There must be at least two agents.
- Group A is never larger than Group B.
- With `group_a_ratio = 0.5` and an odd number of agents, the groups cannot be equal: Group A is one person smaller, and a warning is printed. Even populations, and any other ratio, match 0.1.1.
- The only trial-result change from 0.1.1 is that odd 50/50 case (for 7 agents, Group A was 4 and is now 3).
- A `SimConfig` that could not run (one agent, or a group size or strategy count that does not match the game) now raises `ArgumentError` when you construct it, instead of failing later in the trial.
