tool

const mocap_constants_const = preload("sar1_mocap_constants.gd")

static func _get_mocap_path_and_prefix(p_mocap_directory: String) -> String:
	return "%s/mocap_" % p_mocap_directory

static func _incremental_mocap_file_path(p_info: Dictionary) -> Dictionary:
	var file: File = File.new()
	var err: int = OK
	var path: String = ""
	
	var mocap_directory: String = p_info["mocap_directory"]
	
	var mocap_number: int = 0
	var mocap_path_and_prefix: String = _get_mocap_path_and_prefix(mocap_directory)
	while(file.open(mocap_path_and_prefix + str(mocap_number).pad_zeros(mocap_constants_const.INCREMENTAL_DIGET_LENGTH) + mocap_constants_const.MOCAP_EXT, File.READ) != ERR_FILE_NOT_FOUND):
		file.close()
		mocap_number += 1
	
	file.close()
	
	if(mocap_number <= mocap_constants_const.MAX_INCREMENTAL_FILES):
		path = mocap_path_and_prefix + str(mocap_number).pad_zeros(mocap_constants_const.INCREMENTAL_DIGET_LENGTH) + mocap_constants_const.MOCAP_EXT
	else:
		err = FAILED
		
	return {"error":err, "path":path}

static func create_scene_for_mocap_recording(p_mocap_recording: MocapRecording) -> Spatial:
	var mocap_scene: Spatial = Spatial.new()
	mocap_scene.set_name("MocapScene")
	
	# Setup animation player
	var animation_player: AnimationPlayer = AnimationPlayer.new()
	animation_player.set_name("AnimationPlayer")
	mocap_scene.add_child(animation_player)
	animation_player.set_owner(mocap_scene)
	
	# Setup animation root
	var root: Spatial = Spatial.new()
	root.set_name("Root")
	mocap_scene.add_child(root)
	root.set_owner(mocap_scene)
	
	animation_player.root_node = animation_player.get_path_to(root)
	
	# Setup animation
	var current_idx: int = 0
	var animation: Animation = Animation.new()
	
	animation_player.add_animation("MocapAnimation", animation)
	
	animation.set_name("MocapAnimation")
	animation.add_track(Animation.TYPE_TRANSFORM)
	animation.track_set_path(current_idx, root.get_path_to(root))
	
	# Add tracks for tracker data
	for tracker_point_name in mocap_constants_const.TRACKER_POINT_NAMES:
		current_idx += 1
		var tracker: Position3D = Position3D.new()
		tracker.set_name(tracker_point_name)
		root.add_child(tracker)
		tracker.set_owner(mocap_scene)
		
		animation.add_track(Animation.TYPE_TRANSFORM)
		animation.track_set_path(current_idx, root.get_path_to(tracker))
	
	# Setup timestep based on mocap data's FPS
	var timestep: float = 1.0 / p_mocap_recording.fps
	var current_time: float = 0.0
	
	animation.step = timestep
	
	# Write the mocap data to the animation file
	for frame in p_mocap_recording.frames:
		current_idx = 0
		
		for transform in frame:
			if current_idx < animation.get_track_count():
				animation.transform_track_insert_key(current_idx, current_time, transform.origin, transform.basis, Vector3(1.0, 1.0, 1.0))
			else:
				printerr("Animation mocap data track mismatch")
			current_idx += 1
		
		current_time += timestep
		
	animation.length = current_time
	
	return mocap_scene
	
static func create_packed_scene_for_mocap_recording(p_mocap_recording: MocapRecording) -> PackedScene:
	var mocap_scene: Spatial = create_scene_for_mocap_recording(p_mocap_recording)
	if mocap_scene:
		var packed_scene: PackedScene = PackedScene.new()
		var result: int = packed_scene.pack(mocap_scene)
		if result == OK:
			return packed_scene
	
	return null
	
static func save_packed_scene_for_mocap_recording_at_path(p_save_path: String, p_mocap_recording: MocapRecording) -> int:
	var packed_scene: PackedScene = create_packed_scene_for_mocap_recording(p_mocap_recording)
	if packed_scene:
		var err: int = ResourceSaver.save(p_save_path, packed_scene)
		return err
	
	return FAILED
