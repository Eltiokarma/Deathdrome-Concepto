extends GutTest

var catalog: BalanceCatalog
var balance_data: Dictionary
var runner_data: Dictionary
var schema: Dictionary


func before_each() -> void:
	catalog = BalanceCatalog.new()
	balance_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	runner_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/runners.json"))
	schema = JSON.parse_string(FileAccess.get_file_as_string("res://core/balance_schema.json"))


func test_autoload_and_typed_access() -> void:
	assert_eq(Balance.get_f("weapons.laser.damage_per_shot"), 1.5)
	assert_eq(Balance.get_i("round.quota_base"), 2)
	assert_true(Balance.get_b("purge.lethal"))
	assert_eq(Balance.get_s("round.hub_safe_mode"), "always")
	assert_eq(Balance.runner(&"amaru").max_integrity, 100.0)


func test_all_eight_runners_match_documented_values() -> void:
	assert_true(catalog.load_files())
	# Velocidad, aceleración, PI, masa, giro, agarre, láser, barrera, fijación.
	var expected: Dictionary = {
		"puma": [26.0, 1.8, 85.0, 1.0, 150.0, 0.94, 0.95, 100.0, 0.65],
		"kuntur": [28.5, 1.6, 85.0, 1.0, 130.0, 0.88, 0.95, 100.0, 0.65],
		"chikchi": [21.0, 2.2, 115.0, 1.2, 110.0, 0.82, 1.05, 120.0, 0.55],
		"lloqlla": [21.0, 2.2, 130.0, 1.3, 110.0, 0.82, 1.0, 110.0, 0.6],
		"illapa": [23.5, 2.0, 85.0, 1.0, 130.0, 0.88, 1.05, 120.0, 0.55],
		"wikuna": [23.5, 2.0, 100.0, 1.1, 170.0, 1.0, 0.9, 90.0, 0.7],
		"supay": [26.0, 1.8, 100.0, 1.1, 110.0, 0.82, 1.0, 110.0, 0.6],
		"amaru": [23.5, 2.0, 100.0, 1.1, 130.0, 0.88, 1.0, 110.0, 0.6],
	}
	var fields: Array[String] = [
		"max_speed_mps", "accel_time_s", "max_integrity", "mass", "turn_rate_deg_s",
		"lateral_grip", "laser_mult", "barrier_energy", "missile_lock_time_s",
	]
	for id: String in expected:
		var stats: RunnerStats = catalog.runner(StringName(id))
		for i: int in fields.size():
			assert_almost_eq(stats.get(fields[i]), expected[id][i], 0.00001, id + ": " + fields[i])


func test_missing_key_reports_full_path() -> void:
	balance_data.weapons.laser.erase("damage_per_shot")
	assert_false(catalog.load_data(balance_data, runner_data, schema))
	assert_string_contains("\n".join(catalog.errors), "weapons.laser.damage_per_shot")


func test_invalid_numeric_type_rejected() -> void:
	balance_data.weapons.laser.damage_per_shot = true
	assert_false(catalog.load_data(balance_data, runner_data, schema))


func test_nonfinite_numeric_rejected() -> void:
	balance_data.weapons.laser.damage_per_shot = INF
	assert_false(catalog.load_data(balance_data, runner_data, schema))


func test_duplicate_runner_rejected() -> void:
	runner_data.runners[1].id = "puma"
	assert_false(catalog.load_data(balance_data, runner_data, schema))


func test_wrong_stats_and_fractional_stats_rejected() -> void:
	runner_data.runners[0].speed = 5
	assert_false(catalog.load_data(balance_data, runner_data, schema))
	runner_data.runners[0].speed = 4.5
	assert_false(catalog.load_data(balance_data, runner_data, schema))


func test_missing_formula_rejected() -> void:
	runner_data.formulas.erase("mass")
	assert_false(catalog.load_data(balance_data, runner_data, schema))
	assert_string_contains("\n".join(catalog.errors), "formulas.mass")


func test_returned_stats_cannot_mutate_catalog() -> void:
	assert_true(catalog.load_files())
	catalog.runner(&"amaru").max_integrity = 1
	assert_eq(catalog.runner(&"amaru").max_integrity, 100.0)


func test_input_mutation_cannot_mutate_catalog() -> void:
	assert_true(catalog.load_data(balance_data, runner_data, schema))
	balance_data.weapons.laser.damage_per_shot = 99
	assert_eq(catalog.get_f("weapons.laser.damage_per_shot"), 1.5)


func test_missing_files_fail_clearly() -> void:
	assert_false(catalog.load_files("user://nonexistent-purga-data"))
	assert_string_contains("\n".join(catalog.errors), "balance.json")


func test_malformed_json_and_wrong_root_fail_clearly() -> void:
	DirAccess.make_dir_recursive_absolute("user://invalid-data")
	var file := FileAccess.open("user://invalid-data/balance.json", FileAccess.WRITE)
	file.store_string("{")
	file.close()
	file = FileAccess.open("user://invalid-data/runners.json", FileAccess.WRITE)
	file.store_string("[]")
	file.close()
	assert_false(catalog.load_files("user://invalid-data"))
	assert_eq(catalog.errors.size(), 2)


func test_failed_reload_discards_previous_state() -> void:
	assert_true(catalog.load_files())
	balance_data.erase("weapons")
	assert_false(catalog.load_data(balance_data, runner_data, schema))
	assert_true(catalog.get("_balance").is_empty())
	assert_true(catalog.get("_runners").is_empty())


func test_unknown_formula_rejected_without_runtime_error() -> void:
	runner_data.formulas["unexpected"] = 42
	assert_false(catalog.load_data(balance_data, runner_data, schema))
	assert_string_contains("\n".join(catalog.errors), "unexpected")
