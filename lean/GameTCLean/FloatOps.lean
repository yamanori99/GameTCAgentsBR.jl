import GameTCLean.Core

namespace GameTCLean

open GameTCLean

/-- `maximum(s -> payoffs[s], playable)` with 1-based indices into `payoffs`. -/
def maxOnPlayable (payoffs : List Float) (playable : List Nat) : Float :=
  playable.foldl (fun acc s =>
    let idx := s - 1
    if _ : idx < payoffs.length then max acc payoffs[idx]! else acc) (payoffs.head?.getD 0.0)

/-- `src/model.jl:436-444` tie set among playable strategies. -/
def strategiesWithinEps (payoffs : List Float) (playable : List Nat) : List Nat :=
  let m := maxOnPlayable payoffs playable
  playable.filter (fun s =>
    let idx := s - 1
    if h : idx < payoffs.length then payoffs[idx]! ≥ m - PAYOFF_TIE_EPS else false)

/-- Exact floating equality best replies (idealized exact argmax). -/
def exactArgmax (payoffs : List Float) (playable : List Nat) : List Nat :=
  let m := maxOnPlayable payoffs playable
  playable.filter (fun s =>
    let idx := s - 1
    if h : idx < payoffs.length then payoffs[idx]! == m else false)

end GameTCLean