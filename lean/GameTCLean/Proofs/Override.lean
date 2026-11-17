import GameTCLean.Core

namespace GameTCLean.Proofs

def overrideUnplayableRecordedProp : Prop :=
  ∀ (stored : Nat), stored = 3 → stored ∈ [1, 2]

theorem overrideUnplayableRecorded_refuted : ¬ overrideUnplayableRecordedProp := by
  intro h
  have hi := h 3 rfl
  simpa using hi

end GameTCLean.Proofs