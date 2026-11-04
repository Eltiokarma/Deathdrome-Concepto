class_name BalanceCatalog
extends RefCounted
## Valida antes de publicar datos. Una carga fallida elimina el estado anterior.

const STAT_NAMES: Array[String] = ["speed", "armor", "handling", "weapons"]
const TYPE_NAMES: Dictionary = {
	"object": TYPE_DICTIONARY, "array": TYPE_ARRAY, "bool": TYPE_BOOL,
	"string": TYPE_STRING,
}

var errors: Array[String] = []
var _balance: Dictionary = {}
var _runners: Dictionary = {}


func load_files(directory: String = "res://data") -> bool:
	errors.clear()
	_balance.clear()
	_runners.clear()
	var schema: Dictionary = _read_json("res://core/balance_schema.json")
	var balance_data: Dictionary = _read_json(directory.path_join("balance.json"))
	var runner_data: Dictionary = _read_json(directory.path_join("runners.json"))
	if not errors.is_empty():
		return false
	return load_data(balance_data, runner_data, schema)


func load_data(balance_data: Dictionary, runner_data: Dictionary, schema: Dictionary) -> bool:
	errors.clear()
	_balance.clear()
	_runners.clear()
	for source: String in ["balance", "runners"]:
		if not schema.get(source) is Dictionary or schema[source].is_empty():
			errors.append("schema: falta el objeto " + source)
			return false
	_validate_schema(balance_data, schema["balance"], "balance.json")
	_validate_schema(runner_data, schema["runners"], "runners.json")
	if not errors.is_empty():
		return false
	if balance_data.round.hub_safe_mode not in ["always", "round_start", "off"]:
		errors.append("balance.json: round.hub_safe_mode inválido")
	var ids: Dictionary = {}
	for raw: Variant in runner_data.runners:
		_validate_runner(raw, ids)
	if runner_data.runners.size() != 8:
		errors.append("runners.json: runners debe contener 8 entradas")
	for key: String in runner_data.formulas:
		if not schema.runners.has("formulas." + key):
			errors.append("runners.json: fórmula desconocida: " + key)
			continue
		var formula: Dictionary = runner_data.formulas[key]
		if formula.stat not in STAT_NAMES:
			errors.append("runners.json: formulas.%s.stat inválido" % key)
	if not errors.is_empty():
		return false
	_balance = balance_data.duplicate(true)
	for raw: Dictionary in runner_data.runners:
		var stats := RunnerStats.new()
		stats.id = StringName(raw.id)
		stats.display_name = raw.name
		stats.color = Color(raw.color)
		for key: String in runner_data.formulas:
			var formula: Dictionary = runner_data.formulas[key]
			stats.set(key, float(formula.base) + float(formula.per_point) * raw[formula.stat])
		var missile: Dictionary = _balance.weapons.missile
		stats.missile_lock_time_s = missile.lock_time_s + (
			missile.lock_time_per_weapon_point_s * (raw.weapons - missile.lock_reference_weapons)
		)
		_runners[stats.id] = stats
	return true


func get_f(path: String) -> float:
	var value: Variant = _lookup(_balance, path)
	if not _is_number(value):
		push_error("Balance: valor numérico ausente o inválido: " + path)
		return 0.0
	return float(value)


func get_i(path: String) -> int:
	var value: float = get_f(path)
	if value != floor(value):
		push_error("Balance: se esperaba entero: " + path)
		return 0
	return int(value)


func get_b(path: String) -> bool:
	var value: Variant = _lookup(_balance, path)
	if not value is bool:
		push_error("Balance: se esperaba bool: " + path)
		return false
	return value


func get_s(path: String) -> String:
	var value: Variant = _lookup(_balance, path)
	if not value is String:
		push_error("Balance: se esperaba String: " + path)
		return ""
	return value


func runner(id: StringName) -> RunnerStats:
	if not _runners.has(id):
		push_error("Balance: Runner desconocido: " + str(id))
		return null
	# Resource.duplicate no copia propiedades sin @export; copiar explícitamente.
	var result := RunnerStats.new()
	for property: Dictionary in _runners[id].get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result.set(property.name, _runners[id].get(property.name))
	return result


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("No se pudo abrir %s; ejecutar python3 scripts/prepare_data.py" % path)
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		errors.append("%s:%d: %s" % [path, parser.get_error_line(), parser.get_error_message()])
		return {}
	if not parser.data is Dictionary:
		errors.append(path + ": la raíz debe ser un objeto")
		return {}
	return parser.data


func _validate_schema(data: Dictionary, schema: Dictionary, source: String) -> void:
	for path: String in schema:
		var value: Variant = _lookup(data, path)
		var expected: String = schema[path]
		var valid: bool = _is_number(value) if expected == "number" else (
			typeof(value) == TYPE_NAMES.get(expected, -1)
		)
		if not valid:
			errors.append("%s: falta o es inválida la clave '%s' (%s)" % [source, path, expected])


func _validate_runner(raw: Variant, ids: Dictionary) -> void:
	if not raw is Dictionary:
		errors.append("runners.json: entrada runners debe ser objeto")
		return
	var id: Variant = raw.get("id")
	if not id is String or id.is_empty() or ids.has(id):
		errors.append("runners.json: runners.id ausente, vacío o duplicado")
		return
	ids[id] = true
	var total: int = 0
	for key: String in STAT_NAMES:
		var value: Variant = raw.get(key)
		if not _is_number(value) or value != floor(value) or value < 1 or value > 5:
			errors.append("runners.json: runners.%s.%s debe ser entero 1..5" % [id, key])
		else:
			total += int(value)
	if total != 12:
		errors.append("runners.json: runners.%s stats deben sumar 12" % id)
	if not raw.get("name") is String or not raw.get("color") is String:
		errors.append("runners.json: runners.%s requiere name y color" % id)
	elif not Color.html_is_valid(raw.color):
		errors.append("runners.json: runners.%s.color inválido" % id)


func _lookup(data: Dictionary, path: String) -> Variant:
	var current: Variant = data
	for key: String in path.split("."):
		if not current is Dictionary or not current.has(key):
			return null
		current = current[key]
	return current


func _is_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))
