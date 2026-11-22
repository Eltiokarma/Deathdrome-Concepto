class_name InventoryComponent
extends Node
## PUR-040: slots de armas secundarias. Cada pickup llena un slot libre (se pueden repetir);
## con todos llenos no se recoge. Q/E ciclan el seleccionado. Se vacía al reaparecer.
## Disparar la secundaria corresponde a cada arma (PUR-042 en adelante).

var slots: Array[StringName] = []
var selected: int = 0
@onready var runner: Runner = get_parent() as Runner


func capacity() -> int:
	return Balance.get_i("inventory.secondary_slots")


func is_full() -> bool:
	return slots.size() >= capacity()


func add(weapon_id: StringName) -> bool:
	if is_full():
		return false
	if not Balance.get_b("inventory.allow_duplicates") and weapon_id in slots:
		return false
	slots.append(weapon_id)
	if slots.size() == 1:
		selected = 0
	EventBus.inventory_changed.emit(runner)
	return true


func selected_weapon() -> StringName:
	return slots[selected] if selected < slots.size() else &""


## Avanza (+1) o retrocede (-1) la selección, en ciclo sobre los slots ocupados.
func cycle(direction: int) -> void:
	if slots.size() < 2 or direction == 0:
		return
	selected = posmod(selected + signi(direction), slots.size())
	EventBus.inventory_changed.emit(runner)


## Saca el arma seleccionada (la usará el disparo de cada secundaria).
func take_selected() -> StringName:
	if slots.is_empty():
		return &""
	var weapon: StringName = slots[selected]
	slots.remove_at(selected)
	selected = clampi(selected, 0, maxi(0, slots.size() - 1))
	EventBus.inventory_changed.emit(runner)
	return weapon


func clear() -> void:
	var had_items: bool = not slots.is_empty()
	slots.clear()
	selected = 0
	if had_items:
		EventBus.inventory_changed.emit(runner)
