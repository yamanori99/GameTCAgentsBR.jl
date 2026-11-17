import GameTCLean.Core

namespace GameTCLean.Model

/-- `src/batch.jl:8-16` — explicit RNG inputs replace `rand(RandomDevice())` / `Xoshiro`. -/
def deriveTrialSeeds (numInit : Nat) (givenSeeds : Option (List Nat)) (baseSeed : Nat)
    (rngSeeds : List Nat) : List Nat :=
  match givenSeeds with
  | some seeds => seeds
  | none => rngSeeds.take numInit

def deriveTrialSeedsValid (numInit : Nat) (seeds : List Nat) : Bool :=
  seeds.length = numInit

/-- `src/batch.jl:23-29` -/
def batchTrackCallback (trackWithPopulation : Bool) (trialIdx : Nat) : Bool :=
  trackWithPopulation || trialIdx ≥ 0

end GameTCLean.Model