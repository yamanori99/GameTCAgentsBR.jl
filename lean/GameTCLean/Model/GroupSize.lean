import GameTCLean.Core

namespace GameTCLean.Model

open GameTCLean

/-- `group_a_ratio = k/1000`, matching documented scan grid (see `lean/repro/group-a-size-scan.jl`). -/
def groupASizeMilli (numAgents k : Nat) : Nat :=
  let scaled := numAgents * k
  let raw := (scaled + 500) / 1000
  let half := numAgents / 2
  min raw half

/-- Package `SimConfig` derived field (same expression on `group_a_ratio * 1000`). -/
def simConfigGroupASizeMilli (numAgents k : Nat) : Nat :=
  groupASizeMilli numAgents k

/-- Float path used in exploratory models (`src/model.jl:64-65`). -/
def groupASize (numAgents : Nat) (ratio : Float) : Nat :=
  let raw := roundInt_nonneg (ratio * numAgents.toFloat)
  let half := numAgents / 2
  min raw.natAbs half

def simConfigGroupASize (numAgents : Nat) (groupARatio : Float) : Nat :=
  groupASize numAgents groupARatio

end GameTCLean.Model