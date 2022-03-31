module gameUtils
require daslib/media public
require dasbox/math public
require TMX public

let WIDTH = 512
let HEIGHT = 192 * 2

var is_demo_completed:bool
var is_robot_died:bool
var is_hero_died:bool

enum public LevelTask
    _max_born
    _save_child_robots
    _save_robots
    
var level_task:table<LevelTask;int>

enum AppScreen
    _main_menu
    _prepare_game
    _game
    _exit
    _about
    _options

var camera_position:float2
var camera_bounds:float4

var main_volume:float = 0.7f

var is_shoot_down:bool = false

var appScreen:AppScreen = AppScreen _main_menu
// var appState:AppState = AppState enter_main_menu

var backgroundColor = 0xFF1d212d
var foregroundColor = 0x00000000
var textColor = 0xFFFFFFFF

var RND:int

var K_PRESSED : array<int>
var K_DOWN : array<int>


var tmx_data:Tmx?
var foreground_bounds:float4= float4(0f,0f,float(WIDTH),0f)

struct SkillName
    jump:string = "skill_jump"
    fire:string = "skill_sword"
    yell:string = "skill_yell"

//      BULLETS
struct Bullets
    machine_gun_bullets:array<float3>      // x, y, flip (0=false;!0=true)
    // enemy_bullets:array<float3>
    allied_robot_bullets:array<float3>
    machine_gun_bullet_width:float

var bullets <- [[Bullets
    machine_gun_bullet_width = 8f
]]

//      TRIGGER
struct Trigger
/*
    триггер должен:
        менять состояние, иметь таймеры для каждого состояния, менться визуально при разных состояниях. 
*/
    type_name:TriggerName           // свой тип
    target_name:string              // имя цели
    target:Trigger?                 // цель
    activator: TmxSprite?           // кто акривировал данный триггер
    counter, target_id, id:int      // счетчик возможных использований, индекс цели и свой
    textures:array<ImageHandle>
    regions:array<float4>
    colors:array<uint>
    position:array<float2>              // позиции спрайтов тригерра
    bounds:float4                       // коллизия
    powered, visible:bool
    phase, cell, target_cell:int
    timer:float
    angle:float
    p1,p2,p3,p4,p5,p6,p7,p8,p9,p0:bool
    destroy_trigger:bool = false

enum TriggerName
    _empty
    _delivery_container
    _upgrade_container
    _button
    _exit
    _skill_jump
    _skill_sword
    _skill_yell

var triggers_map:array<Trigger?>    // карта ячеек триггеров
var triggers:array<Trigger?>         // все триггеры
var buttons:array<Trigger?>

var collision_lines:array<int4>  // как объявить НЕ динамический массив известного размера ????????
var collision_rects:array<int4>


def key_listener()
    clear(K_PRESSED)
    clear(K_DOWN)
    push(K_PRESSED, get_pressed_key_index())
    push(K_DOWN, get_pressed_key_index())
    

def fade_in(var color:uint&)
    color -= 0x04000000
    return (int(color) >> 24 & 255) == 0 ? false : true
def fade_out(var color:uint&)
    color += 0x04000000
    return (int(color) >> 24 & 255) == 252 ? false : true
//----------------------------------CAMERA----------------------------------------------------
def camera_to_object(obj:TmxSprite?)
    camera_position[0] = obj.bounds[0] + obj.bounds[2] / 2f
    camera_position[1] = obj.bounds[1] + obj.bounds[3] / 2f
    camera_bounds[2] = float(WIDTH)
    camera_bounds[3] = float(HEIGHT)
    camera_bounds[0] = camera_position[0] - camera_bounds[2] / 2f
    camera_bounds[1] = camera_position[1] - camera_bounds[3] / 2f
    setup_2d_camera(camera_position)
def lerp_camera_to_object(obj:TmxSprite?; delta:float)
    camera_position[0] = lerp(camera_position[0], obj.bounds[0] + obj.bounds[2] / 2f, delta)
    camera_position[1] = lerp(camera_position[1], obj.bounds[1] + obj.bounds[3] / 2f, delta)
    camera_bounds[2] = float(WIDTH)
    camera_bounds[3] = float(HEIGHT)
    camera_bounds[0] = camera_position[0] - camera_bounds[2] / 2f
    camera_bounds[1] = camera_position[1] - camera_bounds[3] / 2f
    setup_2d_camera(camera_position)
//--------------------------------------------------------------------------------------
var private tmpRect:float4

def contains(bounds:int4; point:int2)
    return bounds[0] <= point[0] && bounds[0] + bounds[2] >= point[0] && bounds[1] <= point[1] && bounds[1] + bounds[3] >= point[1]

def containsF(bounds:float4; point:float2)
    return bounds[0] <= point[0] && bounds[0] + bounds[2] >= point[0] && bounds[1] <= point[1] && bounds[1] + bounds[3] >= point[1]

def overlaps(r1:int4; r2:int4)
    return r1[0] < r2[0] + r2[2] && r1[0] + r1[2] > r2[0] && r1[1] < r2[1] + r2[3] && r1[1] + r1[3] > r2[1]

def overlapsF(r1:float4; r2:float4)
    return r1[0] < r2[0] + r2[2] && r1[0] + r1[2] > r2[0] && r1[1] < r2[1] + r2[3] && r1[1] + r1[3] > r2[1]

def on_screen(rect:float4):bool
    print("cam_b: {camera_bounds}\n")
    return overlapsF(rect, camera_bounds)


def get_cell_by_position(tmx:Tmx?; x:float; y:float)
    return int(y / tmx.tmx_cell_height) * tmx.tmx_map_width + int(x / tmx.tmx_cell_width)

var seed = 437
var r_seed = random_seed(seed)
def rnd(mask:int = INT_MAX):int
    RND = random_int(r_seed)
    r_seed = random_seed(seed + RND ^ r_seed[0])
    return RND & mask


def foreground_process(delta:float; curtain:bool = false; duration:float = 8f):bool
    if curtain
        foreground_bounds[3] = clamp(foreground_bounds[3] + (delta * 60f * duration), 0f, float(HEIGHT))
        if foreground_bounds[3] >= (float(HEIGHT) - duration)
            foreground_bounds[3] = float(HEIGHT)
        return foreground_bounds[3] >= (float(HEIGHT) - duration)
    else
        foreground_bounds[3] = clamp(foreground_bounds[3] - (delta * 60f * duration), 0f, float(HEIGHT))
        if foreground_bounds[3] <= duration
            foreground_bounds[3] = 0f
        return foreground_bounds[3] <= duration

def draw_foreground()
    foreground_bounds[0] = camera_bounds[0]
    foreground_bounds[1] = camera_bounds[1]
    foreground_bounds[2] = float(WIDTH)
    fill_rect(foreground_bounds[0],foreground_bounds[1],foreground_bounds[2],foreground_bounds[3], 0xFF000000)

    ///////////////////////////////////// save/load /////////////////////////////////////
struct Storage
    level:int
    jump:int
    fire:bool
    yell:bool

var storage:Storage
var tmp_storage:Storage
let private stor_name = "storage"
var private error = ""
def load():bool
    if local_storage_has_key(stor_name)
        storage <- from_JV(read_json(local_storage_get(stor_name), error), type<Storage>)
        return true
    return false

def save()
    local_storage_set(stor_name, write_json(JV(storage)))
    print("SAVE: {storage}\n")