import GameTCLean.Core

namespace GameTCLean.Model

def matchOnePair (n a1Pick tempPick : Nat) : Option (Nat × Nat) :=
  if n < 2 ∨ a1Pick < 1 ∨ a1Pick > n ∨ tempPick < 1 ∨ tempPick > n - 1 then
    none
  else
    let a2 := if tempPick ≥ a1Pick then tempPick + 1 else tempPick
    some (a1Pick, a2)

end GameTCLean.Model