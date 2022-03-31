require daslib/media
require daslib/math
require gameUtils


var private audioNames:table<string;string>
var private music:table<string; SoundHandle>
var sound:table<string; SoundHandle>


def init_audio()
    audioNames["error"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/UIGlitch_Error Tone_03.wav"
    audioNames["activate"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/SCIEnrg_Shield Activate Deactivate_02.wav"
    audioNames["robo_beep"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/UIBeep_Lock On_05.wav"
    audioNames["beep_targetting"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/BEEP_Targeting Loop_06.wav"
    audioNames["machine_gun"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/LASRGun_Ion Pistol C Burst_02.wav"
    audioNames["energy_orb"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/SCIEnrg_Energy Orb_05.wav"
    audioNames["reload_alien"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/SCIMisc_Reload Alien Tech_02.wav"
    audioNames["take"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/BLLTShel_Shell Eject_02.wav"
    audioNames["pistol"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/GUNPis_Pistol Fire Longer Tail_05.wav"
    audioNames["laser"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Sci Fi Weapons Cyberpunk Arsenal Preview/AUDIO/LASRGun_Classic Blaster A Fire_03.wav"
    
    audioNames["shoot_cinematic"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Dystopia Ambience and Drone Preview/AUDIO/ONE_SHOT_CINEMATIC_EFFECT_10.wav"
    audioNames["yell"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Dystopia Ambience and Drone Preview/AUDIO/AMBIENCE_SIGNAL_LOOP.wav"
    
    audioNames["jump"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Hit and Punch Preview/AUDIO/WHOOSH_ARM_SWING_01.wav"
    audioNames["landing"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Hit and Punch Preview/AUDIO/PUNCH_CLEAN_HEAVY_10.wav"
    
    audioNames["recharge"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Cassette Preview/AUDIO/LOOP_01.wav"
    audioNames["fire_stop"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Cassette Preview/AUDIO/TAPE STOP_15.wav"

    audioNames["delivery_activate"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Arcane Activations Preview/AUDIO/Glyph Activation Warm Aura.wav"
    audioNames["stone_pillar"] = "Audio/Sfx/Shapeforms Audio Free Sound Effects/Arcane Activations Preview/AUDIO/Raise Stone Pillar Long.wav"

    audioNames["game"] = "Audio/Virtual World - AShamaluevMusic.mp3"



var audio_handle:table<string; PlayingSoundHandle>

def play_audio_once(name:string; volume:float = 1f; loop:bool = false)
    if !audio_handle |> key_exists(name)
        audio_handle[name] = play_audio(name,volume,loop)
    elif !is_playing(audio_handle[name])
        play_audio(name,volume,loop)

def play_audio(name:string; volume:float = 1f; loop:bool = false):PlayingSoundHandle
    if !sound |> key_exists(name)
        sound[name] = move_to_managed_storage(create_sound(audioNames[name]))

    if loop
        return sound[name] |> play_sound_loop(main_volume * volume)
    else
        return sound[name] |> play_sound(main_volume * volume)

def stop_audio(name:string)
    if audio_handle |> key_exists(name) && is_playing(audio_handle[name])
        stop_sound(audio_handle[name])

// ------------------------------озвучка рожденных роботов------------------------------
var private prcs_handle: PlayingSoundHandle
let private play_robot_child_sounds = [[string "robo_beep";"beep_targetting"]]
def audio_robot_child(position:float2)
    for sound_name in  play_robot_child_sounds
        if is_playing(prcs_handle)
            return
    let v =  volumeCenter(position.x,position.y)
    if v > 0f
        prcs_handle = play_audio(play_robot_child_sounds[rnd(511) & 1], v)

def public volumeCenter(obj_pos_x:float; obj_pos_y:float):float
            // 448 среднее занчение между шириной и высотой экрана. TODO (заменить с расчетами ширины и высоты экраны)
    return 1f - distance(float3(camera_position[0],camera_position[1],0f), float3(obj_pos_x,obj_pos_y,0f)) / float(448/2)