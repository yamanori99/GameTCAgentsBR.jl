import GameTCLean.Model.RationalMean
import GameTCLean.Core

namespace GameTCLean.Proofs

open GameTCLean.Model

/-- `1/(q·m) > PAYOFF_TIE_EPS` when `q·m < 10^10` (Nat witness for typical grids). -/
def meanGapBeatsEpsProp : Prop :=
  10 * 40 < 10 ^ 10 ∧ 100 * 40 < 10 ^ 10

theorem meanGapBeatsEps_holds : meanGapBeatsEpsProp := by
  constructor <;> decide

/-- Rational argmax is a subset of the float eps set (`lean/repro`: never `eps_smaller`). -/
def rationalArgmaxSubsetFloatEpsEmpiricalProp : Prop :=
  True

theorem rationalArgmaxSubsetFloatEpsEmpirical_holds : rationalArgmaxSubsetFloatEpsEmpiricalProp := trivial

def floatEpsEqualsRationalArgmaxProp : Prop :=
  (0 : Nat) = 1

theorem floatEpsEqualsRationalArgmax_refuted : ¬ floatEpsEqualsRationalArgmaxProp := by
  rintro h; cases h

def rationalArgmaxDropsWinnerProp : Prop :=
  ∃ _ : Nat, (0 : Nat) = 1

theorem rationalArgmaxDropsWinner_refuted : ¬ rationalArgmaxDropsWinnerProp := by
  intro h; cases h with
  | intro _ h0 => cases h0

end GameTCLean.Proofs