import GameTCLean.Core

namespace GameTCLean.Proofs

open GameTCLean

def int8Accepts128Prop : Prop :=
  match I8.ofInt 128 with
  | .ok _ => True
  | .error _ => False

theorem int8Accepts128_refuted : ¬ int8Accepts128Prop := by
  dsimp [int8Accepts128Prop, I8.ofInt]
  decide

end GameTCLean.Proofs