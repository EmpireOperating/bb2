extends "res://src/economy.gd"
# Only the escrow owner changes: a completed job is no longer an active threat.
# All stock conservation, treasury, freight and industry validators still run.
func restore(raw: Variant, data: Dictionary, world, catalog: Dictionary = {}) -> bool:
 var context: Dictionary = data
 if not data.get("contract_payment",{}).get("pending",{}).is_empty():
  context = data.duplicate(true)
  context.active = data.contract_payment.pending.job.duplicate(true)
 return super.restore(raw,context,world,catalog)
