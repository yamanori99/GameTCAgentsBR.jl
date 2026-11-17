import GameTCLean.Core

namespace GameTCLean.Model

/-- `PairGame` inner constructor requires a square matrix (`src/model.jl:30-31`). -/
def pairGameSquareOk (nRows nCols : Nat) : Bool :=
  nRows == nCols

def pairGameStrategyInRange (i n : Nat) : Bool :=
  1 ≤ i ∧ i ≤ n

end GameTCLean.Model