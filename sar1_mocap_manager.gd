extends Node
tool

const USER_PREFERENCES_SECTION_NAME = "mocap"

var set_settings_value: FuncRef = FuncRef.new()
var get_settings_value: FuncRef = FuncRef.new()
var save_settings: FuncRef = FuncRef.new()

const MOCAP_VERSION = 0
const MOCAP_DIR = "mocap"

var recording_enabled = false

# 
const MOCAP_EXT = ".mcp"
const HAND_EXT = ".hnd"
const EXP_EXT = ".exp"

const MAX_INCREMENTAL_FILES = 99999
const INCREMENTAL_DIGET_LENGTH = 5

# Comically simple interchange binary format for mocap data for recording
# IK. Will likely be made more flexible and efficent in future revisions

##########
# Header #
##########
# 4 Bytes - Ident (MCP0)
# 4 Bytes - Recording FPS

# The rest of the body is an array of frames

#########
# Frame #
#########
# Number of transforms in frame, followed by respective number of transforms
# Usually is: root transform, head, left hand, right hand, left foot, right foot, hips

#############
# Transform #
#############
# 8 Bytes - origin.x
# 8 Bytes - origin.y
# 8 Bytes - origin.z
# 8 Bytes - quat.x
# 8 Bytes - quat.y
# 8 Bytes - quat.z
# 8 Bytes - quat.w

static func _get_mocap_path_and_prefix(p_mocap_directory: String) -> String:
	return "%s/mocap_" % p_mocap_directory

static func _incremental_mocap_file_path(p_info: Dictionary) -> Dictionary:
	var file: File = File.new()
	var err: int = OK
	var path: String = ""
	
	var mocap_directory: String = p_info["mocap_directory"]
	
	var mocap_number: int = 0
	var mocap_path_and_prefix: String = _get_mocap_path_and_prefix(mocap_directory)
	while(file.open(mocap_path_and_prefix + str(mocap_number).pad_zeros(INCREMENTAL_DIGET_LENGTH) + MOCAP_EXT, File.READ) != ERR_FILE_NOT_FOUND):
		file.close()
		mocap_number += 1
	
	file.close()
	
	if(mocap_number <= MAX_INCREMENTAL_FILES):
		path = mocap_path_and_prefix + str(mocap_number).pad_zeros(INCREMENTAL_DIGET_LENGTH) + MOCAP_EXT
	else:
		err = FAILED
		
	return {"error":err, "path":path}

class MocapRecording extends Reference:
	const HEADER = "MCP"
	
	var file: File = null
	
	func _init():
		file = File.new()
		
	func open_file_write(p_path) -> int:
		var err: int = file.open(p_path, File.WRITE)
			
		return err
		
	func close_file() -> void:
		file.close()
		
	func write_mocap_header(p_version, p_fps) -> void:
		file.store_string(HEADER)
		file.store_8(p_version)
		file.store_32(p_fps)
		
	func write_transform(p_transform: Transform) -> void:
		var origin: Vector3 = p_transform.origin
		file.store_real(p_transform.origin.x)
		file.store_real(p_transform.origin.y)
		file.store_real(p_transform.origin.z)
		
		var quat: Quat = Quat(p_transform.basis)
		file.store_real(quat.x)
		file.store_real(quat.y)
		file.store_real(quat.z)
		file.store_real(quat.w)
		
	func write_transform_array(p_transform_array: Array) -> void:
		file.store_32(p_transform_array.size())
		for transform in p_transform_array:
			write_transform(transform)


func start_recording(p_fps: int) -> MocapRecording:
	var mocap_recording: MocapRecording = null
	var dict: Dictionary = _incremental_mocap_file_path({"mocap_directory":"user://" + MOCAP_DIR})
	if dict["error"] == OK:
		mocap_recording = MocapRecording.new()
		mocap_recording.open_file_write(dict["path"])
		mocap_recording.write_mocap_header(MOCAP_VERSION, p_fps)
	
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
