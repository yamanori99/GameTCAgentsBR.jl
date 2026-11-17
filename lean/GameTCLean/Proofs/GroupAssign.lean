import GameTCLean.Model.GroupAssign

namespace GameTCLean.Proofs

open GameTCLean GameTCLean.Model

def assignGroupsPrefixProp : Prop :=
  assignGroups 10 3 = [GROUP_A, GROUP_A, GROUP_A, GROUP_B, GROUP_B, GROUP_B, GROUP_B, GROUP_B, GROUP_B, GROUP_B]

theorem assignGroupsPrefix_holds : assignGroupsPrefixProp := rfl

def assignGroupsSuffixProp : Prop :=
  (assignGroups 10 3).length = 10

theorem assignGroupsSuffix_holds : assignGroupsSuffixProp := rfl

end GameTCLean.Proofs