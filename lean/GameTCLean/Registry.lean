import GameTCLean.Proofs.GroupAssign
import GameTCLean.Proofs.Memory
import GameTCLean.Proofs.Matching
import GameTCLean.Proofs.Payoff
import GameTCLean.Proofs.RememberedPayoffs
import GameTCLean.Proofs.RngSeed
import GameTCLean.Proofs.Override

namespace GameTCLean.Registry

open Lean

inductive Status where
  | proven | refuted | todo
deriving DecidableEq, Repr

structure Entry where
  id : String
  juliaFile : String
  juliaFns : List String
  statement : String
  source : String
  status : Status
  property : Name
  theoremName : Option Name

def mkEntry (id juliaFile : String) (juliaFns : List String) (statement source : String)
    (status : Status) (property thm : Name) : Entry :=
  { id, juliaFile, juliaFns, statement, source, status, property, theoremName := some thm }

def mkTodo (id juliaFile : String) (juliaFns : List String) (statement source : String)
    (property : Name) : Entry :=
  { id, juliaFile, juliaFns, statement, source, status := .todo, property, theoremName := none }

def all : List Entry := [
  mkEntry "assign-groups-prefix-a" "src/model.jl" ["assign_groups(::SimConfig)"]
    "The first group_a_size agents are assigned GROUP_A." "assign_groups docstring" .proven
    `GameTCLean.Proofs.assignGroupsPrefixProp `GameTCLean.Proofs.assignGroupsPrefix_holds,
  mkEntry "assign-groups-suffix-b" "src/model.jl" ["assign_groups(::SimConfig)"]
    "Agents after group_a_size are assigned GROUP_B." "assign_groups docstring" .proven
    `GameTCLean.Proofs.assignGroupsSuffixProp `GameTCLean.Proofs.assignGroupsSuffix_holds,
  mkEntry "memory-mod1-julia" "src/model.jl" ["_push_memory!(...)"]
    "mod1 matches Julia wrap (e.g. mod1(4,3)=1, mod1(3,3)=3)." "test/test_model.jl" .proven
    `GameTCLean.Proofs.pushMemoryRingProp `GameTCLean.Proofs.pushMemoryRing_holds,
  mkEntry "match-one-pair-distinct" "src/model.jl" ["match_agents(::OnePair, ...)"]
    "OnePair always matches two distinct agents when n≥2." "match_agents docstring" .proven
    `GameTCLean.Proofs.matchDistinctProp `GameTCLean.Proofs.matchDistinct_holds,
  mkEntry "match-one-pair-in-range" "src/model.jl" ["match_agents(::OnePair, ...)"]
    "Returned indices lie in 1:n for valid random inputs." "test/test_model.jl OnePair" .proven
    `GameTCLean.Proofs.matchInRangeProp `GameTCLean.Proofs.matchInRange_holds,
  mkEntry "payoff-equal-length-no-throw" "src/analysis.jl" ["compute_payoff_outcome(...)"]
    "Equal-length count vectors never throw on a square payoff matrix."
    "compute_payoff_outcome docstring (implicit sizing)" .refuted
    `GameTCLean.Proofs.payoffEqualLengthNoThrowProp `GameTCLean.Proofs.payoffEqualLengthNoThrow_refuted,
  mkEntry "payoff-3x3-ok" "src/analysis.jl" ["compute_payoff_outcome(...)"]
    "Length-3 counts on a 3×3 matrix succeed when dimensions match size(U,1)."
    "test/test_analysis.jl compute_payoff_outcome" .proven
    `GameTCLean.Proofs.payoffThreeByThreeOkProp `GameTCLean.Proofs.payoffThreeByThreeOk_holds,
  mkEntry "payoff-zero-unknown" "src/analysis.jl" ["compute_payoff_outcome(...)"]
    "Zero count totals yield advantage :unknown and NaN payoffs."
    "compute_payoff_outcome docstring" .proven
    `GameTCLean.Proofs.payoffAllZeroUnknownProp `GameTCLean.Proofs.payoffAllZeroUnknown_holds,
  mkEntry "remembered-invalid-index" "src/model.jl" ["_add_remembered_payoffs!(...)"]
    "Strategy code 0 raises ArgumentError." "test/test_model.jl Memory average" .proven
    `GameTCLean.Proofs.rememberedInvalidIndexProp `GameTCLean.Proofs.rememberedInvalidIndex_holds,
  mkEntry "run-simulation-preserves-caller-rng" "src/model.jl" ["run_simulation(::SimConfig; ...)"]
    "run_simulation does not alter the task-local RNG stream after return."
    "README tracking example (implicit)" .refuted
    `GameTCLean.Proofs.runSimulationPreservesCallerRngProp
    `GameTCLean.Proofs.runSimulationPreservesCallerRng_refuted,
  mkEntry "override-unplayable-recorded" "src/model.jl" ["override_strategies", "_record_observation!(...)"]
    "Recorded strategies always belong to playable_A/playable_B." "PairGame play_a/play_b doc" .refuted
    `GameTCLean.Proofs.overrideUnplayableRecordedProp `GameTCLean.Proofs.overrideUnplayableRecorded_refuted,
  mkTodo "common-memory-unused" "src/model.jl" ["determine_strategy(...)"]
    "Common memory is not read when choosing a strategy." "MemorySystem docstring"
    `GameTCLean.Proofs.commonMemoryUnusedProp,
  mkTodo "group-a-size-formula" "src/model.jl" ["_group_a_size"]
    "group_a_size equals min(round(Int,n*ratio), n÷2) for documented inputs." "SimConfig docstring"
    `GameTCLean.Proofs.groupASizeFormulaProp,
]

end GameTCLean.Registry
