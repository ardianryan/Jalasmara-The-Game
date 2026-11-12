extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    await process_frame
    var audio = root.get_node("AudioManager")
    for music in audio._bgm_players:
        if music.playback_type != AudioServer.PLAYBACK_TYPE_DEFAULT:
            push_error("BGM must use platform playback: native stream, Web sample")
            quit(1)
    if audio.ambience_player.playback_type != AudioServer.PLAYBACK_TYPE_DEFAULT or audio.victory_player.playback_type != AudioServer.PLAYBACK_TYPE_DEFAULT:
        push_error("Long ambience and victory audio must use platform playback")
        quit(1)
    var state = root.get_node("GameState")
    var env = root.get_node("EnvironmentState")
    for key in ["title_theme", "mangrove_forest", "coastal_dusk", "village_hall", "underwater_cave_deep"]:
        if not audio.bgm_streams.has(key):
            push_error("Missing BGM: " + key)
            quit(1)
            return
    if not audio.sfx_streams.has("jingle_victory_fanfare"):
        push_error("Missing victory stream")
        quit(1)
        return
    if audio.victory_player.stream is AudioStreamMP3 and audio.victory_player.stream.loop:
        push_error("Victory stream must finish naturally to restore music volume")
        quit(1)
        return
    audio.set_process(false)
    audio.unlock_audio()
    audio._refresh_context()
    if audio.current_bgm_track != "title_theme":
        push_error("Title selection failed: " + audio.current_bgm_track)
        quit(1)
        return
    state.player = {"id":"audio-fixture", "progress":{"stage":"dive"}}
    state.world = {"homestead":{"permitBoard":{"x":940,"y":310}}}
    state.surface = {"area":"forest","x":100,"y":100}
    audio._refresh_context()
    if audio.current_bgm_track != "mangrove_forest":
        push_error("Forest selection failed: " + audio.current_bgm_track)
        quit(1)
        return
    state.surface = {"area":"hub","x":940,"y":310}
    audio._refresh_context()
    if audio.current_bgm_track != "village_hall":
        push_error("Hall selection failed: " + audio.current_bgm_track)
        quit(1)
        return
    state.surface = {"area":"hub","x":300,"y":900}
    env.visual_minutes = 1050.0
    env._night = false
    audio._refresh_context()
    if audio.current_bgm_track != "coastal_dusk":
        push_error("Dusk selection failed: " + audio.current_bgm_track)
        quit(1)
        return
    state.dive = {"id":"dive-fixture","depth":75.0,"mode":"dive"}
    audio._refresh_context()
    if audio.current_bgm_track != "underwater_cave_deep":
        push_error("Cave selection failed: " + audio.current_bgm_track)
        quit(1)
        return
    state.dive.mode = "boss"
    audio._refresh_context()
    if audio.current_bgm_track != "boss_gajah_mina":
        push_error("Boss selection failed: " + audio.current_bgm_track)
        quit(1)
        return
    state.dive = {}
    state.player.progress.stage = "night"
    audio._refresh_context()
    if audio.current_bgm_track != "kedai_waras_night":
        push_error("Night selection failed: " + audio.current_bgm_track)
        quit(1)
        return
    audio.play_victory_jingle()
    if audio._last_sfx != "jingle_victory_fanfare":
        push_error("Victory jingle did not start")
        quit(1)
        return
    var music_bus := AudioServer.get_bus_index(audio.BGM_BUS)
    await create_timer(0.25).timeout
    if AudioServer.get_bus_volume_db(music_bus) > -12.0:
        push_error("Victory jingle did not duck BGM")
        quit(1)
        return
    audio.victory_player.stop()
    audio._restore_bgm_after_jingle()
    await create_timer(0.75).timeout
    if absf(AudioServer.get_bus_volume_db(music_bus)) > 0.5:
        push_error("BGM volume did not recover after victory jingle")
        quit(1)
        return
    audio.set_process_input(false)
    audio.set_process_unhandled_input(false)
    audio.process_mode = Node.PROCESS_MODE_DISABLED
    audio.audio_unlocked = false
    audio.muted = true
    audio.stop_bgm(0.0)
    for sound in audio.get_children():
        if sound is AudioStreamPlayer:
            sound.stop()
            sound.stream = null
    audio.bgm_streams.clear()
    audio.sfx_streams.clear()
    for bus_name in [audio.ENVIRONMENT_BUS, audio.UI_BUS]:
        var bus := AudioServer.get_bus_index(bus_name)
        if bus < 0: continue
        for effect in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
            AudioServer.remove_bus_effect(bus, effect)
    audio._filter = null
    audio.queue_free()
    await process_frame
    await process_frame
    await create_timer(0.35).timeout
    print("AUDIO_CONTEXT_SMOKE_PASS")
    quit()
