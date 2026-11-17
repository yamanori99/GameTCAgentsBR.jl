import GameTCLean.Core

namespace GameTCLean.Model

open GameTCLean

def addRememberedPayoffs (code : I8) (n : Nat) : Jl Unit :=
  let j := code.val
  if 1 ≤ j ∧ j ≤ n then .ok () else .error .argumentError

end GameTCLean.Model