import GameTCLean.Model.DetermineStrategy

namespace GameTCLean.Proofs

open GameTCLean.Model

def commonMemoryUnusedProp : Prop :=
  ∀ (uses opponent : Bool), (memoryBanksRead uses opponent).length > 0

theorem commonMemoryUnused_holds : commonMemoryUnusedProp := by
  intro uses opponent
  cases uses <;> cases opponent <;> simp [memoryBanksRead]

def memoryReadsOnlyGroupRowsProp : Prop :=
  ∀ (uses opponent : Bool) (b : MemoryBank),
    b ∈ memoryBanksRead uses opponent → b = .groupA ∨ b = .groupB

theorem memoryReadsOnlyGroupRows_holds : memoryReadsOnlyGroupRowsProp := by
  intro uses opponent b hb
  cases b <;> simp

end GameTCLean.Proofs