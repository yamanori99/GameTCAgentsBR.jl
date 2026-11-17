import GameTCLean.Proofs.GroupAssign
import GameTCLean.Proofs.Memory
import GameTCLean.Proofs.Matching
import GameTCLean.Proofs.Payoff
import GameTCLean.Proofs.RememberedPayoffs
import GameTCLean.Proofs.RngSeed
import GameTCLean.Proofs.Override
import GameTCLean.Proofs.EpsilonTie
import GameTCLean.Proofs.GroupSize
import GameTCLean.Proofs.CommonMemory
import GameTCLean.Proofs.Coverage
import GameTCLean.Proofs.Int8Strategy
import GameTCLean.Proofs.Analysis
import GameTCLean.Proofs.BatchExtra
import GameTCLean.Proofs.NoOverride
import GameTCLean.Proofs.PairGame

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

def all : List Entry := [
  mkEntry "assign-groups-prefix-a" "src/model.jl" ["assign_groups"] "First group_a_size agents are GROUP_A." "assign_groups docstring" .proven
    `GameTCLean.Proofs.assignGroupsPrefixProp `GameTCLean.Proofs.assignGroupsPrefix_holds,
  mkEntry "assign-groups-suffix-b" "src/model.jl" ["assign_groups"] "Remaining agents are GROUP_B." "assign_groups docstring" .proven
    `GameTCLean.Proofs.assignGroupsSuffixProp `GameTCLean.Proofs.assignGroupsSuffix_holds,
  mkEntry "memory-mod1-julia" "src/model.jl" ["_push_memory!"] "mod1 matches Julia wrap." "test/test_model.jl ring buffer" .proven
    `GameTCLean.Proofs.pushMemoryRingProp `GameTCLean.Proofs.pushMemoryRing_holds,
  mkEntry "match-one-pair-distinct" "src/model.jl" ["match_agents(::OnePair)"] "OnePair returns distinct indices (example)." "match_agents docstring" .proven
    `GameTCLean.Proofs.matchDistinctProp `GameTCLean.Proofs.matchDistinct_holds,
  mkEntry "match-one-pair-in-range" "src/model.jl" ["match_agents(::OnePair)"] "Returned indices lie in 1:n for valid draws." "test/test_model.jl" .proven
    `GameTCLean.Proofs.matchInRangeProp `GameTCLean.Proofs.matchInRange_holds,
  mkEntry "payoff-equal-length-no-throw" "src/analysis.jl" ["compute_payoff_outcome"] "Equal-length count vectors never throw on a square payoff matrix." "analysis docstring; addressed by merged PR #15 (ArgumentError)" .refuted
    `GameTCLean.Proofs.payoffEqualLengthNoThrowProp `GameTCLean.Proofs.payoffEqualLengthNoThrow_refuted,
  mkEntry "payoff-3x3-ok" "src/analysis.jl" ["compute_payoff_outcome"] "Matching length-3 inputs succeed when dimensions match." "test/test_analysis.jl" .proven
    `GameTCLean.Proofs.payoffThreeByThreeOkProp `GameTCLean.Proofs.payoffThreeByThreeOk_holds,
  mkEntry "payoff-zero-unknown" "src/analysis.jl" ["compute_payoff_outcome"] "Zero totals yield :unknown." "compute_payoff_outcome docstring" .proven
    `GameTCLean.Proofs.payoffAllZeroUnknownProp `GameTCLean.Proofs.payoffAllZeroUnknown_holds,
  mkEntry "remembered-invalid-index" "src/model.jl" ["_add_remembered_payoffs!"] "Strategy code 0 raises ArgumentError." "test/test_model.jl" .proven
    `GameTCLean.Proofs.rememberedInvalidIndexProp `GameTCLean.Proofs.rememberedInvalidIndex_holds,
  mkEntry "run-simulation-preserves-caller-rng" "src/model.jl" ["run_simulation"] "run_simulation leaves task-local RNG unchanged." "README tracking pattern" .refuted
    `GameTCLean.Proofs.runSimulationPreservesCallerRngProp `GameTCLean.Proofs.runSimulationPreservesCallerRng_refuted,
  mkEntry "override-unplayable-recorded" "src/model.jl" ["override_strategies", "_record_observation!"] "Recorded strategies stay in playable sets." "PairGame play_a/play_b doc" .refuted
    `GameTCLean.Proofs.overrideUnplayableRecordedProp `GameTCLean.Proofs.overrideUnplayableRecorded_refuted,
  mkEntry "common-memory-unused" "src/model.jl" ["determine_strategy"] "Strategy choice reads group memories only (never common bank)." "MemorySystem docstring" .proven
    `GameTCLean.Proofs.commonMemoryUnusedProp `GameTCLean.Proofs.commonMemoryUnused_holds,
  mkEntry "memory-reads-group-rows" "src/model.jl" ["determine_strategy"] "Only groupA/groupB banks appear in read set." "model.jl determine_strategy" .proven
    `GameTCLean.Proofs.memoryReadsOnlyGroupRowsProp `GameTCLean.Proofs.memoryReadsOnlyGroupRows_holds,
  mkEntry "group-a-size-doc" "src/model.jl" ["_group_a_size"] "group_a_size matches min(round(Int,n*ratio), n÷2) on documented examples." "SimConfig docstring" .proven
    `GameTCLean.Proofs.groupASizeDocProp `GameTCLean.Proofs.groupASizeDoc_holds,
  mkEntry "group-a-size-simconfig" "src/model.jl" ["_group_a_size", "SimConfig"] "Derived SimConfig group_a_size uses _group_a_size." "SimConfig inner constructor" .proven
    `GameTCLean.Proofs.groupASizeMatchesModelProp `GameTCLean.Proofs.groupASizeMatchesModel_holds,
  mkEntry "group-a-size-halfup-equals-julia" "src/model.jl" ["_group_a_size"] "Half-up milli (n*k+500)÷1000 matches Julia round(Int,n*ratio) at witness." "lean/repro/group-a-size-float-mismatch.jl" .refuted
    `GameTCLean.Proofs.groupASizeFloatGridNoMismatchProp `GameTCLean.Proofs.groupASizeFloatGridNoMismatch_refuted,
  mkEntry "group-a-size-float-rational" "src/model.jl" ["_group_a_size"] "Float64 round matches exact Rational(n*k/1000) on k/1000 grid." "lean/repro/group-a-size-rational-mismatch.jl" .refuted
    `GameTCLean.Proofs.groupASizeFloatRationalGridProp `GameTCLean.Proofs.groupASizeFloatRationalGrid_refuted,
  mkEntry "group-a-size-bounded" "src/model.jl" ["_group_a_size"] "group_a_size never exceeds n÷2." "SimConfig docstring" .proven
    `GameTCLean.Proofs.groupASizeBoundedByHalfProp `GameTCLean.Proofs.groupASizeBoundedByHalf_holds,
  mkEntry "tie-eps-includes-near-best" "src/model.jl" ["determine_strategy"] "Strategies within PAYOFF_TIE_EPS of the best mean are included." "test/test_model.jl tie eps" .proven
    `GameTCLean.Proofs.tieEpsIncludesNearBestProp `GameTCLean.Proofs.tieEpsIncludesNearBest_holds,
  mkEntry "tie-eps-equals-exact" "src/model.jl" ["determine_strategy", "_add_remembered_payoffs!"] "Epsilon tie set equals exact float argmax set." "lean/repro/tie-eps-widens-set.jl" .refuted
    `GameTCLean.Proofs.tieEpsEqualsExactProp `GameTCLean.Proofs.tieEpsEqualsExact_refuted,
  mkEntry "exact-argmax-subset-eps" "src/model.jl" ["determine_strategy"] "Exact argmax ⊆ epsilon tie set (concrete FP means)." "FP counterexample" .proven
    `GameTCLean.Proofs.exactArgmaxSubsetConcreteProp `GameTCLean.Proofs.exactArgmaxSubsetConcrete_holds,
  mkEntry "dyadic-eps-agreement" "src/model.jl" ["determine_strategy"] "Exact argmax ⊆ epsilon set for tied dyadic means." "tie model" .proven
    `GameTCLean.Proofs.dyadicMeansEpsAgreementProp `GameTCLean.Proofs.dyadicMeansEpsAgreement_holds,
  mkEntry "int8-accepts-128" "src/model.jl" ["PairGame", "determine_strategy"] "Strategy code 128 converts to Int8." "Int8 memory slots" .refuted
    `GameTCLean.Proofs.int8Accepts128Prop `GameTCLean.Proofs.int8Accepts128_refuted,
  mkEntry "pairgame-128-runtime" "src/model.jl" ["PairGame", "run_simulation"] "128-strategy games run without Int8 overflow." "lean/repro/pairgame-128-strategies.jl; PR #15 limits n≤127" .refuted
    `GameTCLean.Proofs.pairGame128RuntimeProp `GameTCLean.Proofs.pairGame128Runtime_refuted,
  mkEntry "pairgame-square-matrix" "src/model.jl" ["PairGame"] "Payoff matrix must be square at construction." "PairGame inner constructor" .proven
    `GameTCLean.Proofs.pairGameSquareMatrixProp `GameTCLean.Proofs.pairGameSquareMatrix_holds,
  mkEntry "pairgame-playable-range" "src/model.jl" ["PairGame"] "Playable strategy indices lie in 1:n." "PairGame @argcheck" .proven
    `GameTCLean.Proofs.pairGamePlayableInRangeProp `GameTCLean.Proofs.pairGamePlayableInRange_holds,
  mkEntry "no-override-identity" "src/model.jl" ["override_strategies(::NoOverride)"] "NoOverride leaves strategy pair unchanged." "NoOverride docstring" .proven
    `GameTCLean.Proofs.noOverrideIdentityProp `GameTCLean.Proofs.noOverrideIdentity_holds,
  mkEntry "derive-trial-seeds-length" "src/batch.jl" ["_derive_trial_seeds"] "Given trial_seeds length must equal num_initializations." "batch docstring" .proven
    `GameTCLean.Proofs.deriveTrialSeedsLengthProp `GameTCLean.Proofs.deriveTrialSeedsLength_holds,
  mkEntry "batch-track-callback" "src/batch.jl" ["_batch_track_callback"] "Batch track callback wrapper is defined for all trial indices." "batch.jl" .proven
    `GameTCLean.Proofs.batchTrackNothingProp `GameTCLean.Proofs.batchTrackNothing_holds,
  mkEntry "run-batch-trial-count" "src/batch.jl" ["run_batch", "_derive_trial_seeds"] "One seed per trial when explicit seeds supplied." "batch.jl loop" .proven
    `GameTCLean.Proofs.runBatchTrialCountProp `GameTCLean.Proofs.runBatchTrialCount_holds,
  mkEntry "accumulate-trial-counts" "src/batch.jl" ["_accumulate_trial_counts!"] "Trial accumulation increments slot counters (model scaffold)." "batch.jl" .proven
    `GameTCLean.Proofs.accumulateTrialMonotoneProp `GameTCLean.Proofs.accumulateTrialMonotone_holds,
  mkEntry "empty-memory-uniform" "src/model.jl" ["determine_strategy"] "Empty memory implies uniform choice over playable (count = |playable|)." "determine_strategy docstring" .proven
    `GameTCLean.Proofs.emptyMemoryUniformCountProp `GameTCLean.Proofs.emptyMemoryUniformCount_holds,
  mkEntry "record-writes-common" "src/model.jl" ["_record_observation!"] "Each observation also writes common memory." "model.jl _record_observation!" .proven
    `GameTCLean.Proofs.recordWritesCommonProp `GameTCLean.Proofs.recordWritesCommon_holds,
  mkEntry "accumulate-skips-placeholder" "src/analysis.jl" ["_accumulate_strategy_counts!"] "MEMORY_PLACEHOLDER slots are not counted." "analysis.jl" .proven
    `GameTCLean.Proofs.accumulateSkipsPlaceholderProp `GameTCLean.Proofs.accumulateSkipsPlaceholder_holds,
  mkEntry "count-final-four-keys" "src/analysis.jl" ["count_final_strategies"] "Returns four opponent-conditioned count vectors." "count_final_strategies docstring" .proven
    `GameTCLean.Proofs.countFinalFourKeysProp `GameTCLean.Proofs.countFinalFourKeys_holds,
  mkEntry "share-copy-zero-agents" "src/analysis.jl" ["_share_copy", "sample_strategy_shares"] "Empty agent group yields empty share vector." "_share_copy docstring" .proven
    `GameTCLean.Proofs.shareCopyZeroAgentsProp `GameTCLean.Proofs.shareCopyZeroAgents_holds,
]

end GameTCLean.Registry