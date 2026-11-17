import GameTCLean.Model.DetermineStrategy

namespace GameTCLean.Model

open GameTCLean

/-- `src/model.jl:638-669` writes group-specific row and common (three calls). -/
structure WriteTargets where
  groupRow : MemoryBank
  alsoCommon : Bool
deriving DecidableEq

def writeTargets (opponentGroup : I8) : WriteTargets :=
  ⟨if opponentGroup = GROUP_A then .groupA else .groupB, true⟩

theorem record_writes_common (g : I8) : (writeTargets g).alsoCommon = true := rfl

end GameTCLean.Model