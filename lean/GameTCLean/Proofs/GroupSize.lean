import GameTCLean.Model.GroupSize

namespace GameTCLean.Proofs

open GameTCLean.Model

theorem groupASize100_300 : groupASizeMilli 100 300 = 30 := rfl
theorem groupASize7_340 : groupASizeMilli 7 340 = 2 := rfl
theorem groupASize3_500 : groupASizeMilli 3 500 = 1 := rfl

def groupASizeDocProp : Prop :=
  groupASizeMilli 100 300 = 30 ∧
  groupASizeMilli 7 340 = 2 ∧
  groupASizeMilli 3 500 = 1

theorem groupASizeDoc_holds : groupASizeDocProp :=
  ⟨groupASize100_300, groupASize7_340, groupASize3_500⟩

theorem groupASize200_300 : simConfigGroupASizeMilli 200 300 = 60 := rfl

def groupASizeMatchesModelProp : Prop :=
  simConfigGroupASizeMilli 200 300 = 60

theorem groupASizeMatchesModel_holds : groupASizeMatchesModelProp :=
  groupASize200_300

def groupASizeBoundedByHalfProp : Prop :=
  ∀ n k, groupASizeMilli n k ≤ n / 2

theorem groupASizeBoundedByHalf_point (n k : Nat) : groupASizeMilli n k ≤ n / 2 := by
  unfold groupASizeMilli
  exact Nat.min_le_right _ _

theorem groupASizeBoundedByHalf_holds : groupASizeBoundedByHalfProp :=
  fun n k => groupASizeBoundedByHalf_point n k

/-- Witness: exact milli model disagrees with Julia Float path at (9995, 300). -/
def groupASizeFloatGridNoMismatchProp : Prop :=
  groupASizeMilli 9995 300 = 2998

theorem groupASizeMilliWitness : groupASizeMilli 9995 300 = 2999 := rfl

theorem groupASizeFloatGridNoMismatch_refuted : ¬ groupASizeFloatGridNoMismatchProp := by
  intro h
  cases h

theorem groupASizeMilli75_140 : groupASizeMilli 75 140 = 11 := rfl

def groupASizeFloatRationalGridProp : Prop :=
  groupASizeMilli 75 140 = 10

theorem groupASizeFloatRationalGrid_refuted : ¬ groupASizeFloatRationalGridProp := by
  intro h
  cases h

end GameTCLean.Proofs