import GameTCLean.FloatOps

namespace GameTCLean.Model

open GameTCLean

/-- Memory banks exclude `common_memories` (`src/model.jl:399-410`). -/
inductive MemoryBank
  | groupA | groupB
  deriving DecidableEq, Repr

/-- Which group-specific rows `determine_strategy` reads (never `common_memories`). -/
def memoryBanksRead (usesTypeConditioning opponentIsGroupA : Bool) : List MemoryBank :=
  if usesTypeConditioning then
    [if opponentIsGroupA then .groupA else .groupB]
  else
    [.groupA, .groupB]

/-- Empty relevant memory → uniform over playable (`src/model.jl:420-422`). -/
def emptyMemoryOutcome (numPlayable : Nat) : Nat := numPlayable

/-- After means in `payoffs`, strategies within `PAYOFF_TIE_EPS` of the best mean. -/
def optimalSet (payoffs : List Float) (playable : List Nat) : List Nat :=
  strategiesWithinEps payoffs playable

end GameTCLean.Model