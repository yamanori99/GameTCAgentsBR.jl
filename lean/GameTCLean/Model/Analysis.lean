import GameTCLean.Core

namespace GameTCLean.Model

open GameTCLean

/-- `src/analysis.jl:8-17` — skips placeholder slots. -/
def accumulateStrategyCounts! (counts : List Nat) (memView : List I8) (max : Nat) : List Nat :=
  memView.foldl (fun acc s =>
    if s = MEMORY_PLACEHOLDER then acc else
    let idx := s.val.natAbs
    if 1 ≤ idx ∧ idx ≤ max ∧ idx - 1 < acc.length then
      acc.set (idx - 1) (acc[idx - 1]! + 1)
    else acc) counts

/-- `src/analysis.jl:167-169` -/
def shareCopy (counts : List Nat) (nAgents nStrategies : Nat) : List Float :=
  if nAgents = 0 then [] else
    (counts.take nStrategies).map (fun c => c.toFloat / nAgents.toFloat)

def countFinalKeys : List String :=
  ["a_remembers_a_slot_count", "a_remembers_b_slot_count",
   "b_remembers_a_slot_count", "b_remembers_b_slot_count"]

end GameTCLean.Model