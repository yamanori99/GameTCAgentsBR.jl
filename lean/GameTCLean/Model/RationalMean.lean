import GameTCLean.Core

namespace GameTCLean.Model

/-- Each remembered payoff lies in `(1/q) ℤ`; with `n_obs` summands, numerator sums live in `(1/q) ℤ`. -/
def minMeanGapDenom (q nObs : Nat) : Nat := q * nObs

/-- If numerators differ by at least 1, mean gap is at least `1 / (q * n_obs)`. -/
def distinctMeanGap (q nObs : Nat) : Nat := 1

end GameTCLean.Model