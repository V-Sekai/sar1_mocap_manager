tool
extends EditorImportPlugin

const mocap_functions_const = preload("sar1_mocap_functions.gd")
const mocap_constants_const = preload("sar1_mocap_constants.gd")

func get_importer_name():
    return "mcp_importer"

func get_visible_name():
    return "Mocap Data"

func get_recognized_extensions():
    return ["mcp"]

func get_save_extension():
    return "scn"

func get_resource_type():
    return "PackedScene"

func get_preset_count():
    return 1

func get_preset_name(i):
    return "Default"

func get_import_options(i):
    return []

func import(source_file, save_path, options, platform_variants, gen_files):
	var mocap_recording = MocapRecording.new(source_file)
	mocap_recording.open_file_read()
	mocap_recording.parse_file()
	mocap_recording.close_file()

	var packed_scene: PackedScene = mocap_functions_const.create_packed_scene_for_mocap_recording(mocap_recording)
	if packed_scene:
		var filename: String = save_path + "." + get_save_extension()
		ResourceSaver.save(filename, packed_scene)
		return OK
		
	return FAILED
