import GameTCLean.Model.RememberedPayoffs

namespace GameTCLean.Proofs

open GameTCLean GameTCLean.Model

def rememberedInvalidIndexProp : Prop :=
  addRememberedPayoffs ⟨0, by omega⟩ 3 = .error .argumentError

theorem rememberedInvalidIndex_holds : rememberedInvalidIndexProp := rfl

end GameTCLean.Proofs