import GameTCLean.Model.PairGame
import GameTCLean.Proofs.Int8Strategy

namespace GameTCLean.Proofs

open GameTCLean.Model

theorem pairGameSquare_ok : pairGameSquareOk 3 3 = true := rfl
theorem pairGameSquare_bad : pairGameSquareOk 3 4 = false := rfl

def pairGameSquareMatrixProp : Prop :=
  pairGameSquareOk 3 3 = true ∧ pairGameSquareOk 3 4 = false

theorem pairGameSquareMatrix_holds : pairGameSquareMatrixProp :=
  ⟨pairGameSquare_ok, pairGameSquare_bad⟩

theorem pairGameRange_ok : pairGameStrategyInRange 1 3 = true := rfl
theorem pairGameRange_bad : pairGameStrategyInRange 0 3 = false := rfl

def pairGamePlayableInRangeProp : Prop :=
  pairGameStrategyInRange 1 3 = true ∧ pairGameStrategyInRange 0 3 = false

theorem pairGamePlayableInRange_holds : pairGamePlayableInRangeProp :=
  ⟨pairGameRange_ok, pairGameRange_bad⟩

def pairGame128RuntimeProp : Prop :=
  match I8.ofInt 128 with
  | .ok _ => True
  | .error _ => False

theorem pairGame128Runtime_refuted : ¬ pairGame128RuntimeProp :=
  int8Accepts128_refuted

end GameTCLean.Proofs