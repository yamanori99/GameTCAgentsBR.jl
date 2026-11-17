import GameTCLean.Model.Memory

namespace GameTCLean.Proofs

open GameTCLean.Model

def pushMemoryRingProp : Prop :=
  mod1 4 3 = 1 ∧ mod1 3 3 = 3

theorem pushMemoryRing_holds : pushMemoryRingProp := ⟨rfl, rfl⟩

end GameTCLean.Proofs