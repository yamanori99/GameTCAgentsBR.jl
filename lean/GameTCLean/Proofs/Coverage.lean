import GameTCLean.Model.Batch
import GameTCLean.Model.RecordObservation
import GameTCLean.Model.DetermineStrategy

namespace GameTCLean.Proofs

open GameTCLean
open GameTCLean.Model

def deriveTrialSeedsLengthProp : Prop :=
  deriveTrialSeedsValid 3 [1, 2, 3]

theorem deriveTrialSeedsLength_holds : deriveTrialSeedsLengthProp := rfl

def batchTrackNothingProp : Prop :=
  batchTrackCallback false 1 = true

theorem batchTrackNothing_holds : batchTrackNothingProp := rfl

def emptyMemoryUniformCountProp : Prop :=
  emptyMemoryOutcome 3 = 3

theorem emptyMemoryUniformCount_holds : emptyMemoryUniformCountProp := rfl

def recordWritesCommonProp : Prop :=
  ∀ g : I8, (writeTargets g).alsoCommon = true

theorem recordWritesCommon_holds : recordWritesCommonProp :=
  fun g => record_writes_common g

end GameTCLean.Proofs