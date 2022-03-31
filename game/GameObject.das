require daslib/media
require tmxLib/TmxSprite
require daslib/math
require gameUtils
require daslib/sound
require GameAudio
// require rtti

enum public Animation
    _idle
    _run
    _jump
    _landing
    _aggressive
    _fire
    _froze

struct Jump
    accelerate:float = 384f
    velocity:float
    count:int

struct Fire
    agree:bool
    sword:bool

class public GameObject:TmxSprite

    // текстуры атласа и отдельные
    textures:table<Animation;array<ImageHandle>>    
    //  регионы текстур
    animations:table<Animation;array<float4>>
    //  длительность одного кадра анимации
    durations:table<Animation;array<int>>
    // текущая анимация
    private animation_name : Animation = Animation _idle
    // текущий кадр анимации
    private frame:int = 0
    // длительность текущего кадра 
    private dur:float = 0f

    color:uint = 0xFFFFFFFF
    size:float2
    angle:float
    tmpRegion:float4
    
    jump:Jump?
    // направление движения при зажатой клавише
    is_move_left:bool
    is_move_right:bool
    // прыжок при нажатии на клавишу
    is_jump:bool
    is_fire:bool
    is_aggressive:bool

    // время установленного движения
    movement_time:int
    // может повлять на объект
    can_forced:bool
    // принудительное движение. Другой объект воздействует на данный (обрабатывается в дочерних классах)
    forced_movement:float


    /*
        3 фазы эволюции
            1) объект не может сдвинуть ничего, его все пинают кроме фазы 1
            2) может влиять на объекты фазы 1
            3) влияет на все объекты кроме объектов фазы 3
    */
    evolution_phase:int

    def set_animation(var animationName:Animation)
        animation_name = animationName

    def override draw()
        check_frame()
        // draw_image_region(texture,bounds.x,bounds.y,tmpRegion)
        draw_image_transformed(
            texture,
            bounds.x,
            bounds.y - 7f,
            tmpRegion,
            color,
            size,
            angle
        )
        
        // rect(bounds[0], bounds[1],2f,2f, 0xFFFF0000)
        // TmxSprite`draw(self)
        // text_out(20,210,"{bounds}", 0xFF00FF00)
        // text_out(20,230,"is on floor: {is_on_floor}", 0xFF00FF00)
        // text_out(20,270,"is falling {is_falling}", 0xFF00FF00)

    def override update(delta:float)
        preBounds[0] = bounds[0]
        preBounds[1] = bounds[1]
        preBounds[2] = bounds[2]
        preBounds[3] = bounds[3]
       
        if is_move_left
            flip_x = true
        if is_move_right
            flip_x = false

    def upd2(delta:float)
        animation_process(delta)



//--------------------------------------------------------------
    def private animation_process(delta:float)
        check_frame()
        if animation_name == Animation _froze
            return
        dur += delta * 1000f
        if !empty(durations[animation_name]) && int(dur) >= durations[animation_name][frame]
            dur = 0f
            frame++
            check_frame()
            region.x = animations[animation_name][frame].x
            region.y = animations[animation_name][frame].y
            region.w = animations[animation_name][frame].w
            region.z = animations[animation_name][frame].z
            texture = textures[animation_name][frame]
            size.x = bounds.w
            size.y = bounds.z
        // flip texture region
        if flip_x
            tmpRegion.x = region.x + region[2]
            tmpRegion[2] = -region[2]
        else
            tmpRegion.x = region.x
            tmpRegion[2] = region[2]

        if flip_y
            tmpRegion.y = region.y + region[3]
            tmpRegion[3] = -region[3]
        else
            tmpRegion.y = region.y
            tmpRegion[3] = region[3]

    def private check_frame()
        if frame >= length(durations[animation_name]) 
            frame = 0

