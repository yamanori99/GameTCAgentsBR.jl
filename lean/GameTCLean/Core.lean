/-!
Shared Julia-flavoured primitives for the GameTCAgentsBR model.
Errors mirror `Except` style from julia-in-lean; fixed-width `I8` matches `Int8`.
-/

namespace GameTCLean

/-- Julia-style errors surfaced as values instead of exceptions. -/
inductive JlError where
  | argumentError
  | boundsError
  | inexactError
  deriving DecidableEq, Repr

abbrev Jl (α : Type) := Except JlError α

/-- `Int8` with Julia conversion semantics (`Int8(i)` throws on overflow). -/
structure I8 where
  val : Int
  h : -128 ≤ val ∧ val ≤ 127
  deriving DecidableEq, Repr

def I8.ofInt (i : Int) : Jl I8 :=
  if hi : -128 ≤ i ∧ i ≤ 127 then
    .ok ⟨i, hi⟩
  else
    .error .inexactError

def I8.toNat (x : I8) : Nat := x.val.natAbs

/-- Julia `mod1(i, n)` for positive `n` and `i ≥ 1`. -/
def mod1 (i n : Nat) : Nat :=
  if h : n = 0 then 0 else
    let r := i % n
    if r = 0 then n else r

/-- Julia `round(Int, x)` for nonnegative `x` (ties to nearest even; here half-integers → floor+1). -/
def roundInt_nonneg (x : Float) : Int :=
  if x - Float.floor x < 0.5 then
    Int.ofNat (Float.floor x).toUInt64.toNat
  else
    Int.ofNat (Float.ceil x).toUInt64.toNat

/-- `src/model.jl:64-65` group size helper (computed in `Float64` in Julia). -/
def groupASize (numAgents : Nat) (ratio : Float) : Nat :=
  let raw := roundInt_nonneg (ratio * numAgents.toFloat)
  let half := numAgents / 2
  min raw.natAbs half

def GROUP_A : I8 := ⟨1, by omega⟩
def GROUP_B : I8 := ⟨2, by omega⟩
def MEMORY_PLACEHOLDER : I8 := ⟨-1, by omega⟩

def PAYOFF_TIE_EPS : Float := 1e-10

/-- Abstract advantage label returned by `compute_payoff_outcome`. -/
inductive Advantage where
  | fair | a_advantage | b_advantage | unknown
deriving DecidableEq, Repr

structure PayoffOutcome where
  payoffGap : Float
  payoffA : Float
  payoffB : Float
  advantage : Advantage
  lValue : Float
deriving Repr

/-- `isnan` for optional payoff sentinels (Julia `NaN` on empty totals). -/
def floatNan : Float := 0 / 0

def isNan (x : Float) : Prop := x ≠ x

end GameTCLean