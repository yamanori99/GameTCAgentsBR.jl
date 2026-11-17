import GameTCLean.Model.Analysis

namespace GameTCLean.Proofs

open GameTCLean.Model
open GameTCLean

theorem accumulatePlaceholder_example :
    accumulateStrategyCounts! [0, 0] [MEMORY_PLACEHOLDER, GROUP_A] 2 = [1, 0] := rfl

def accumulateSkipsPlaceholderProp : Prop :=
  accumulateStrategyCounts! [0, 0] [MEMORY_PLACEHOLDER, GROUP_A] 2 = [1, 0]

theorem accumulateSkipsPlaceholder_holds : accumulateSkipsPlaceholderProp :=
  accumulatePlaceholder_example

theorem shareCopyZero_example : shareCopy [1, 2, 3] 0 3 = [] := rfl

def shareCopyZeroAgentsProp : Prop :=
  shareCopy [1, 2, 3] 0 3 = []

theorem shareCopyZeroAgents_holds : shareCopyZeroAgentsProp :=
  shareCopyZero_example

def countFinalFourKeysProp : Prop :=
  countFinalKeys.length = 4

theorem countFinalFourKeys_holds : countFinalFourKeysProp := rfl

end GameTCLean.Proofs