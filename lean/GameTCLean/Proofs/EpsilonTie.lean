import GameTCLean.FloatOps

namespace GameTCLean.Proofs

open GameTCLean

set_option maxRecDepth 10000

def tieEpsIncludesNearBestProp : Prop :=
  let p := [1.0 + PAYOFF_TIE_EPS / 2, 1.0, 1.0]
  [1, 2, 3] ⊆ strategiesWithinEps p [1, 2, 3]

theorem tieEpsIncludesNearBest_holds : tieEpsIncludesNearBestProp := by
  dsimp [tieEpsIncludesNearBestProp, strategiesWithinEps, maxOnPlayable, PAYOFF_TIE_EPS]
  decide

def tieEpsEqualsExactProp : Prop :=
  let p := [1.0 + PAYOFF_TIE_EPS / 2, 1.0, 1.0]
  strategiesWithinEps p [1, 2, 3] = exactArgmax p [1, 2, 3]

theorem tieEpsEqualsExact_refuted : ¬ tieEpsEqualsExactProp := by
  dsimp [tieEpsEqualsExactProp, strategiesWithinEps, exactArgmax, maxOnPlayable, PAYOFF_TIE_EPS]
  decide

def exactArgmaxSubsetConcreteProp : Prop :=
  let p := [0.5, 0.49999999999999994]
  exactArgmax p [1, 2] ⊆ strategiesWithinEps p [1, 2]

theorem exactArgmaxSubsetConcrete_holds : exactArgmaxSubsetConcreteProp := by
  dsimp [exactArgmaxSubsetConcreteProp, exactArgmax, strategiesWithinEps, maxOnPlayable]
  decide

def dyadicMeansEpsAgreementProp : Prop :=
  let p := [0.5, 0.5, 0.25]
  exactArgmax p [1, 2, 3] ⊆ strategiesWithinEps p [1, 2, 3]

theorem dyadicMeansEpsAgreement_holds : dyadicMeansEpsAgreementProp := by
  dsimp [dyadicMeansEpsAgreementProp, exactArgmax, strategiesWithinEps, maxOnPlayable]
  decide

end GameTCLean.Proofs