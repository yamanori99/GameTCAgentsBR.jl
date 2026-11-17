import GameTCLean.Core

namespace GameTCLean.Model

open GameTCLean

def mod1 (i n : Nat) : Nat :=
  if n = 0 then 0 else
    let r := i % n
    if r = 0 then n else r

def pushMemory (bank : List I8) (idx : Nat) (strategy : I8) (length : Nat) : Nat × List I8 :=
  if h : 1 ≤ idx ∧ idx ≤ length ∧ idx - 1 < bank.length then
    let bank' := bank.set (idx - 1) strategy
    (mod1 (idx + 1) length, bank')
  else
    (idx, bank)

noncomputable def pushMemoryN (length : Nat) (strategies : List I8) : List I8 :=
  strategies.foldl (fun (state : Nat × List I8) s =>
    let (idx, bank) := state
  let (idx', bank') := pushMemory bank idx s length
  (idx', bank')) (1, List.replicate length MEMORY_PLACEHOLDER)
  |> Prod.snd

end GameTCLean.Model