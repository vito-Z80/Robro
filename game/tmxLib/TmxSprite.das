require daslib/media
require TmxProperties

enum public ObjectType
    _hero
    _enemy_robot_1
    _enemy_robot_2
    _universal_robot_1
    _universal_robot_2
    _universal_robot_3
    _movable_box
    _machine_gun

struct Sides
    rect_left:int4
    rect_right:int4
    rect_top:int4
    rect_bottom:int4

class public TmxSprite

    texture:ImageHandle
    region:float4
    preBounds:float4
    bounds:float4
    tile_id,id:int = -1
    scale:float = 1f
    rotation:float = 0f
    is_dead, destroy_object, visible:bool
    name,object_type:string
    properties : TmxProperties?
    flip_x:bool
    flip_y:bool

    force_x:float
    force_y:float
    pinned = new Sides  // 4 стороны определяющие в какую сторону движение запрещено

    o_type:ObjectType   // тип объекта для коллизий

    is_mission_completed:bool

    def public update(delta:float){}
    def public draw(){}

