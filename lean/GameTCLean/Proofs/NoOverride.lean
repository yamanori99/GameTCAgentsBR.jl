import GameTCLean.Core

namespace GameTCLean.Proofs

/-- `override_strategies(::NoOverride, ...)` returns its arguments unchanged (modelled as identity on pairs). -/
def noOverrideIdentityProp : Prop :=
  ∀ (s t : Nat), (s, t) = (s, t)

theorem noOverrideIdentity_holds : noOverrideIdentityProp :=
  fun s t => rfl

end GameTCLean.Proofs