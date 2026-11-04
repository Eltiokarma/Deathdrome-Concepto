class_name DamageInfo
extends RefCounted
## Contrato de daño para PUR-020; todavía no aplica daño.

var amount: float = 0.0
var type: Enums.DamageType = Enums.DamageType.LASER
var source: Runner
var weapon_id: StringName
var direction: Vector3 = Vector3.ZERO
var position: Vector3 = Vector3.ZERO
