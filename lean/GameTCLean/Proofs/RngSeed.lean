import GameTCLean.Core

/-!
Model of `run_simulation`'s `Random.seed!(seed)` (`src/model.jl:570`).
-/

namespace GameTCLean.Proofs

/-- Task-local RNG state (simplified). -/
structure RngState where
  val : Nat
deriving Repr

def Random_seed (seed : Nat) (_ : RngState) : RngState := ⟨seed⟩

def randUpto (r : RngState) (n : Nat) : Nat × RngState :=
  let next := (r.val * 1664525 + 1013904223) % (if n = 0 then 1 else n)
  (next + 1, ⟨r.val + 1⟩)

/-- Pure model of `run_simulation` RNG effect: always re-seeds the caller stream. -/
def runSimulationRngStep (seed : Nat) (caller : RngState) : RngState :=
  Random_seed seed caller

/-- Doc-shaped expectation: simulation leaves the caller RNG unchanged (false). -/
def runSimulationPreservesCallerRngProp : Prop :=
  ∀ (seed : Nat) (caller : RngState),
    runSimulationRngStep seed caller = caller

theorem runSimulationPreservesCallerRng_refuted :
    ¬ runSimulationPreservesCallerRngProp := by
  intro h
  have h1 := h 42 ⟨999⟩
  dsimp [runSimulationRngStep, Random_seed] at h1
  cases h1

end GameTCLean.Proofs