import Lean.Meta
import GameTCLean.Registry

open Lean Meta

def standardAxioms : List Name := [``propext, ``Classical.choice, ``Quot.sound]

def axiomAllowed (env : Environment) (ax : Name) : Bool :=
  standardAxioms.contains ax

#eval show MetaM Unit from do
  let env ← getEnv
  let entries := GameTCLean.Registry.all
  let mut failures : Array String := #[]
  let mut seen : Std.HashSet String := {}
  let mut counts : Std.HashMap String Nat := {}
  for e in entries do
    let statusName := toString (repr e.status)
    counts := counts.insert statusName (counts.getD statusName 0 + 1)
    if seen.contains e.id then
      failures := failures.push s!"{e.id}: duplicate id"
    seen := seen.insert e.id
    match e.status with
    | .todo =>
      IO.println s!"TODO {e.id}: {e.statement}"
      continue
    | .proven | .refuted => pure ()
    let some propInfo := env.find? e.property
      | failures := failures.push s!"{e.id}: prop {e.property} not found"; continue
    unless propInfo.levelParams.isEmpty do
      failures := failures.push s!"{e.id}: prop has universe params"; continue
    let propExpr := mkConst e.property
    unless ← isProp propExpr do
      failures := failures.push s!"{e.id}: not a Prop"; continue
    let some thm := e.theoremName
      | failures := failures.push s!"{e.id}: missing theorem"; continue
    let some (.thmInfo thmInfo) := env.find? thm
      | failures := failures.push s!"{e.id}: theorem missing"; continue
    let expected := if e.status == .proven then propExpr else mkNot propExpr
    unless ← isDefEq thmInfo.type expected do
      failures := failures.push s!"{e.id}: theorem type mismatch"
    let axioms ← collectAxioms thm
    for ax in axioms do
      unless axiomAllowed env ax do
        failures := failures.push s!"{e.id}: disallowed axiom {ax}"
    if e.status == .refuted then
      IO.println s!"REFUTED {e.id}"
  for (k, v) in counts.toList do
    IO.println s!"STATUS {k} {v}"
  IO.println s!"ENTRIES {entries.length}"
  unless failures.isEmpty do
    for f in failures do
      IO.println s!"FAIL {f}"
    throwError m!"audit failed with {failures.size} problem(s)"
  IO.println "AUDIT OK"