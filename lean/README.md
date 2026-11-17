# Lean formalization of GameTCAgentsBR.jl

Lean **4.34.1** (`leanprover/lean4:v4.34.1`), no Mathlib. Method adapted from [julia-in-lean](https://github.com/MilesCranmer/julia-in-lean).

## Layout

- `GameTCLean/Core.lean` — `Jl`, `I8`, `mod1`, errors
- `GameTCLean/Model/` — mirrors of `src/model.jl`, `src/analysis.jl` (partial)
- `GameTCLean/Proofs/` — properties and proofs
- `GameTCLean/Registry.lean` — property registry
- `registry.tsv` — exported status list
- `repro/*.jl` — Julia reproducers for refuted properties
- `bugs/*.yaml` — bug write-ups
- `Audit.lean` — registry checker (`lake env lean Audit.lean`)

## Build

```bash
cd lean
lake build
bash scripts/audit.sh
```

`compute_payoff_outcome` uses full dimension/zero-total branches in Lean; the bivariate payoff loop is abbreviated in the model (guards only) — Julia tests and reproducers validate runtime behaviour.

## Julia reproducers

```bash
cd /path/to/GameTCAgentsBR.jl
julia --project=. lean/repro/<id>.jl
```

Each script prints `REPRODUCED <id>` as its last line when the bug is observed.