module Robots
require dasbox
require GameObject
require gameUtils
require dasbox/math
require daslib/sound
require dasbox_graphics_utils
require GameAudio
require ObjectHero


/*
    Робот универсальный.
        Имеет несколько фаз развития.
            1 - новорожденный (полностью беззащитен, глуп)
                движение:
                    двигается с переодическими остановками, осматривается на время, снова движется.
                    при столкновении с препядствем останавливается на время либо движется в противоположную сторону.
                    не прыгает, не отражает атаки, не атакует.
            2 - подросток (совершает более осознанные действия, может постоять за себя) пропустить реализацию !!!
            3 - взрослый (имеет цель, не стойте у него на пути)
*/
class ObjectUniversalRobot:GameObject

    drag_in:bool = false
    container_point:float2       // точка прибытия в апгрейд-ванную цеха
    tmp_bounds:float4
    containner_drag_sound:PlayingSoundHandle

    def override update(delta:float)
        if is_dead
            is_jump = false
            if jump.velocity < 0f
                color -= 0x04000000
                if color <= 0x10FFFFFF
                    color = 0x04FFFFFF
                    destroy_object = true
            return

        if evolution_phase == 0 && upgrade(delta)
            return
            
        is_jump = false
        change_movement()

        if evolution_phase > 0
            fire(delta)
        else
            tmp_bounds[0] = bounds[0] - 8f
            tmp_bounds[1] = bounds[1] - 16f
            tmp_bounds.zw = bounds.zw
            for b in bullets.machine_gun_bullets
                if b[1] != 0f
                    if containsF(tmp_bounds, b.xy)
                        is_robot_died = true
                        is_dead = true
                        is_jump = true
                        is_move_left = false
                        is_move_right = false
                        b[1] = 0f
                        return

        GameObject`update(self,delta)


    private timer:float
    private next_bullet_time:float = 2f
    def fire(delta:float)

        timer += delta
        if timer > next_bullet_time
            for b in bullets.allied_robot_bullets
                if b[1] == 0f
                    b[0] = bounds[0]
                    b[1] = bounds[1] - 9f
                    b[2] = flip_x ? 1f : 0f
                    timer = 0f
                    break
            if timer > 0f
                bullets.allied_robot_bullets |> push(float3(bounds[0],bounds[1] - 9f, flip_x ? 1f : 0f))
                timer = 0f
            next_bullet_time = float(rnd(1) + 1)
            play_audio("laser", volumeCenter(bounds[0],bounds[1]) * 0.7f)
            // print("barb: {length(bullets.allied_robot_bullets)}\n")



    def private upgrade(delta:float):bool
        if drag_in
            jump.velocity = 0f
            bounds[0] = move_to(bounds[0], container_point[0], delta * 8f, 8f)
            bounds[1] = move_to(bounds[1], container_point[1], delta * 8f, 2.05f)
            if int(bounds[1]) <= int(container_point[1])
                robot_evolution_complete()
                
            return true
  
        cell = get_cell_by_position(tmx_data, bounds[0], bounds[1])
        var continer = triggers_map[cell]
        if continer != null && evolution_phase == 0
            let b = continer.bounds
            if overlapsF(bounds, b)
                if continer.type_name == TriggerName _upgrade_container
                    continer.p1 = true
                    is_move_left = false
                    is_move_right = false
                    container_point[0] = b[0] + b[2] / 2f
                    container_point[1] = b[1] + bounds[3] - 16f
                    if on_screen(triggers_map[cell].bounds) && !is_playing(containner_drag_sound)
                        containner_drag_sound = play_audio("activate", volumeCenter(bounds[0],bounds[1]) * 0.8f)
                    drag_in = true
                    return true
        return false

    def robot_evolution_complete()
        set_animation(Animation _idle)
        evolution_phase++
        is_move_left = false
        is_move_right = false
        return


    private move_f:int
    private cell:int
    private rect:int4
    def change_movement()
        // принудительное движение отключается при столкновении
        // if forced_movement_left
        //     is_move_left = true
        //     return
        // if forced_movement_right
        //     is_move_right = true
        //     return
        if bounds[1] == preBounds[1] && movement_time < 0
            reset_forced_movement()
            move_f = rnd(3)
            is_move_left = move_f == 1
            is_move_right = move_f == 2
            if move_f == 3
                audio_robot_child(float2(bounds[0], bounds[1]))

            // if evolution_phase > 0 && is_move_left || evolution_phase > 0 && is_move_right
            //     if !is_jump && jump.count < 1 && rnd(7) == 3
            //         is_jump = true 

        movement_time--

        // улучшенный робот может перепрыгивать препядствия высотой до трех ячеек (48 пикселей)
        if evolution_phase > 0
            if !is_jump && jump.count < 1 && rnd(7) == 3
                cell = get_cell_by_position(tmx_data, bounds[0], bounds[1])
                if is_move_left
                    rect = collision_rects[cell - 1]
                    if rect[3] > 0 && int(bounds[1]) - rect[1]  <= 48
                        is_jump = true
            if !is_jump && jump.count < 1 && rnd(7) == 3
                if is_move_right
                    rect = collision_rects[cell + 1]
                    if rect[3] > 0 && int(bounds[1]) - rect[1] <= 48
                        is_jump = true

    
    def reset_forced_movement()
        forced_movement = 0f
        movement_time = rnd(63)


    // орем на роботов управляя их направлением движения.
var private u_robot_point:float2
def yell_at_robot(var hero:ObjectHero?; var robot:GameObject?)
    if hero != null
        u_robot_point[0] = robot.bounds[0]
        u_robot_point[1] = robot.bounds[1]
        if containsF(hero.aggressive_area, u_robot_point)
            if hero.aggressive_area[2] > 1f
                if hero.bounds[0] < u_robot_point[0] 
                    robot.is_move_right = true
                elif hero.bounds[0] > u_robot_point[0] 
                    robot.is_move_left = true



////////////////////////////////////// ENEMY ROBOT ////////////////////////////////////////////////

class ObjectEnemyRobot:GameObject

    drag_in:bool = false
    container_point:float2       // точка прибытия в апгрейд-ванную цеха
    tmp_bounds:float4
    containner_drag_sound:PlayingSoundHandle

    timer:float
    flip_timer:float
    flip:bool
    fire_sound:PlayingSoundHandle
    recharge_sound:PlayingSoundHandle

    def override update(delta:float)
        if is_dead
            is_jump = false
            if jump.velocity < 0f
                color -= 0x04000000
                if color <= 0x10FFFFFF
                    color = 0x04FFFFFF
                    destroy_object = true
            return
        change_movement()

        tmp_bounds[0] = bounds[0] - 8f
        tmp_bounds[1] = bounds[1] - 16f
        tmp_bounds.zw = bounds.zw
        for b in bullets.allied_robot_bullets
            if b[1] != 0f
                if containsF(tmp_bounds, b.xy)
                    is_dead = true
                    is_jump = true
                    is_move_left = false
                    is_move_right = false
                    b[1] = 0f
                    return


        fire(delta)
        GameObject`update(self,delta)


    private next_bullet_time:float = 2f
    def fire(delta:float)

        timer += delta
        if timer > next_bullet_time
            for b in bullets.machine_gun_bullets
                if b[1] == 0f
                    b[0] = bounds[0]
                    b[1] = bounds[1] - 9f
                    b[2] = flip_x ? 1f : 0f
                    timer = 0f
                    break
            if timer > 0f
                bullets.machine_gun_bullets |> push(float3(bounds[0],bounds[1] - 9f, flip_x ? 1f : 0f))
                timer = 0f
            next_bullet_time = float(rnd(3) + 1)
            play_audio("pistol", volumeCenter(bounds[0],bounds[1]) * 0.7f)
                
    private move_f:int
    private walking_distance:float2     // X - left point; Y - right point
    def change_movement()
        if walking_distance[1] == 0f
            // найти линию на которой стоит объект - это будет расстояние хождения данного объекта.
            for line in collision_lines
                if int(bounds[1]) + 1 == line[1] && int(bounds[0]) > line[0] && int(bounds[0]) < line[0] + line[2]
                    walking_distance[0] = float(line[0] + 8)
                    walking_distance[1] = float(line[0] + line[2] - 8)
                    // первое направление движения
                    if rnd(1) == 0
                        is_move_right = true
                    else
                        is_move_left = true
                    break
        else
            // FIXME на конце линии не должны быть ректанглы, иначе объект упрется в него и больше никуда не пойдет.
            if bounds[0] <= walking_distance[0]
                is_move_left = false
                is_move_right = true
            
            if bounds[0] >= walking_distance[1]
                is_move_left = true
                is_move_right = false