@tool
extends EditorImportPlugin

const mocap_functions_const = preload("sar1_mocap_functions.gd")
const mocap_constants_const = preload("sar1_mocap_constants.gd")

func _get_importer_name():
	return "mcp_importer"

func _get_visible_name():
	return "Mocap Data"

func _get_recognized_extensions():
	return ["mcp"]

func _get_save_extension():
	return "scn"

func _get_resource_type():
	return "PackedScene"

func _get_preset_count():
	return 1

func _get_preset_name(i):
	return "Default"

func _get_import_options(option : String, i : int) -> Array:
	return []

func _import(source_file, save_path, options, platform_variants, gen_files):
	var mocap_recording = MocapRecording.new(source_file)
	if mocap_recording.open_file_read() == OK:
		mocap_recording.parse_file()
		mocap_recording.close_file()

		var packed_scene: PackedScene = mocap_functions_const.create_packed_scene_for_mocap_recording(mocap_recording)
		if packed_scene:
			var filename: String = save_path + "." + _get_save_extension()
			ResourceSaver.save(filename, packed_scene)
			return OK
	else:
		printerr("Could not open mocap file for reading")
		
	return FAILED
