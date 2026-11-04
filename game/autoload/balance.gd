extends Node
## Fachada única de gameplay sobre el catálogo validado.

var _catalog := BalanceCatalog.new()


func _ready() -> void:
	if not _catalog.load_files():
		for message: String in _catalog.errors:
			push_error(message)
		get_tree().quit(1)


func get_f(path: String) -> float:
	return _catalog.get_f(path)


func get_i(path: String) -> int:
	return _catalog.get_i(path)


func get_b(path: String) -> bool:
	return _catalog.get_b(path)


func get_s(path: String) -> String:
	return _catalog.get_s(path)


func runner(id: StringName) -> RunnerStats:
	return _catalog.runner(id)
