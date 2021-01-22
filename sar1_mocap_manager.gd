tool
extends Node

const mocap_functions_const = preload("sar1_mocap_functions.gd")
const mocap_constants_const = preload("sar1_mocap_constants.gd")

const USER_PREFERENCES_SECTION_NAME = "mocap"

var set_settings_value: FuncRef = FuncRef.new()
var get_settings_value: FuncRef = FuncRef.new()
var save_settings: FuncRef = FuncRef.new()

var recording_enabled = false

# 

func start_recording(p_fps: int) -> MocapRecording:
	var mocap_recording: MocapRecording = null
	var dict: Dictionary = mocap_functions_const._incremental_mocap_file_path({"mocap_directory":"user://" + mocap_constants_const.MOCAP_DIR})
	if dict["error"] == OK:
		mocap_recording = MocapRecording.new(dict["path"])
		mocap_recording.open_file_write()
		mocap_recording.set_version(mocap_constants_const.MOCAP_VERSION)
		mocap_recording.set_fps(p_fps)
		mocap_recording.write_mocap_header()
	
	return mocap_recording
		
func set_settings_value(p_key: String, p_value) -> void:
	if set_settings_value.is_valid():
		set_settings_value.call_func(USER_PREFERENCES_SECTION_NAME, p_key, p_value)
	
func set_settings_values():
	set_settings_value("recording_enabled", recording_enabled)
	
func get_settings_value(p_key: String, p_type: int, p_default):
	if get_settings_value.is_valid():
		return get_settings_value.call_func(USER_PREFERENCES_SECTION_NAME, p_key, p_type, p_default)
	else:
		return p_default
	
func is_quitting() -> void:
	set_settings_values()
	
func get_settings_values() -> void:
	recording_enabled = get_settings_value("recording_enabled", TYPE_BOOL, recording_enabled)
	
func assign_set_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	set_settings_value.set_instance(p_instance)
	set_settings_value.set_function(p_function)
	
func assign_get_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	get_settings_value.set_instance(p_instance)
	get_settings_value.set_function(p_function)
	
func assign_save_settings_funcref(p_instance: Object, p_function: String) -> void:
	save_settings.set_instance(p_instance)
	save_settings.set_function(p_function)
	
func _ready():
	Directory.new().make_dir("user://mocap")
