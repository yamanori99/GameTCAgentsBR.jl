import GameTCLean.Core

namespace GameTCLean.Model

open GameTCLean

structure CountVec where
  data : List Nat
deriving Repr

/--
`src/analysis.jl:73-123`. Dimension guards and zero-total branch follow the
Julia source; the nested `i,j` loop is abbreviated in the Lean model (see
`lean/README.md`) and validated by Julia reproducers / tests.
-/
def computePayoffOutcome (a b : CountVec) (n : Nat) (matrix : List Float) : Jl PayoffOutcome :=
  if a.data.length ≠ n ∨ b.data.length ≠ n ∨ matrix.length ≠ n * n then
    Except.error .boundsError
  else
    let lValue := matrix[0]!
    let aTotal := a.data.foldl (· + ·) 0
    let bTotal := b.data.foldl (· + ·) 0
    if aTotal = 0 ∨ bTotal = 0 then
      .ok { payoffGap := floatNan, payoffA := floatNan, payoffB := floatNan,
            advantage := .unknown, lValue := lValue }
    else
      .ok { payoffGap := (0.0 : Float), payoffA := (0.0 : Float), payoffB := (0.0 : Float),
            advantage := .fair, lValue := lValue }

end GameTCLean.Model