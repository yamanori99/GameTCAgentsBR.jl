import GameTCLean.Core

namespace GameTCLean.Model

open GameTCLean

def assignGroups (numAgents groupASize : Nat) : List I8 :=
  List.replicate groupASize GROUP_A ++ List.replicate (numAgents - groupASize) GROUP_B

end GameTCLean.Model