import GameTCLean.Model.Matching

namespace GameTCLean.Proofs

open GameTCLean.Model

def matchDistinctProp : Prop :=
  matchOnePair 5 2 2 = some (2, 3)

theorem matchDistinct_holds : matchDistinctProp := rfl

def matchInRangeProp : Prop :=
  matchOnePair 5 5 4 = some (5, 4)

theorem matchInRange_holds : matchInRangeProp := rfl

end GameTCLean.Proofs