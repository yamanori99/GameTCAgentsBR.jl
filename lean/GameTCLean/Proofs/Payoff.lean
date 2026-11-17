import GameTCLean.Model.Payoff

namespace GameTCLean.Proofs

open GameTCLean GameTCLean.Model

def payoffEqualLengthNoThrowProp : Prop :=
  let a : CountVec := ⟨[0, 0, 0, 0, 100]⟩
  let b : CountVec := ⟨[0, 0, 0, 0, 100]⟩
  let matrix := [2.0, 2.0, 2.0, 5.0, 5.0, 0.0, 8.0, 0.0, 0.0]
  match computePayoffOutcome a b 3 matrix with
  | .ok _ => True
  | .error _ => False

theorem payoffEqualLengthNoThrow_refuted : ¬ payoffEqualLengthNoThrowProp := by
  dsimp [payoffEqualLengthNoThrowProp, computePayoffOutcome]
  intro h
  cases h

def payoffThreeByThreeOkProp : Prop :=
  let a : CountVec := ⟨[0, 0, 100]⟩
  let b : CountVec := ⟨[0, 0, 100]⟩
  let matrix := [2.0, 2.0, 2.0, 5.0, 5.0, 0.0, 8.0, 0.0, 0.0]
  match computePayoffOutcome a b 3 matrix with
  | .ok _ => True
  | .error _ => False

theorem payoffThreeByThreeOk_holds : payoffThreeByThreeOkProp := by
  dsimp [payoffThreeByThreeOkProp, computePayoffOutcome]

def payoffAllZeroUnknownProp : Prop :=
  let a : CountVec := ⟨[0, 0, 0]⟩
  let b : CountVec := ⟨[0, 0, 0]⟩
  let matrix := [2.0, 2.0, 2.0, 5.0, 5.0, 0.0, 8.0, 0.0, 0.0]
  match computePayoffOutcome a b 3 matrix with
  | .ok r => r.advantage = .unknown
  | .error _ => False

theorem payoffAllZeroUnknown_holds : payoffAllZeroUnknownProp := by
  dsimp [payoffAllZeroUnknownProp, computePayoffOutcome]

end GameTCLean.Proofs