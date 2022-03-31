module CORE
require TMX
require graphics
require Screen
require gameUtils public
require dasbox
require daslib/json
require daslib/json_boost
require TmxSprite
require ObjectHero
require Robots
// require ObjectWeapon
require Arsenal
require ObjectMovableBox
require ObjectMachineGun
require ObjectWeapon
require Arsenal
require GameObject
require math
require GameAudio

var hero:ObjectHero::ObjectHero?
var objects:table<ObjectType;array<GameObject?>>

class public Core:Screen

    /*
        все взаимодействия с объектами обрабатываются в Core.
        ---------------------------------------------------------------
        подготовка уровня, объектов.
        ---------------------------------------------------------------
            создание карты коллизий
                    коллизии примитивные: прямоугольники и линии.
                    коллизии храняться в отдельных масивах ячеек карты.
                    array<int4>
                    если размер ячейки 16х16 пикселей, то прямогульник такого-же размера занимает 1 ячейку
                    если к примеру размер прямоугольника 32х64, то во всех ячейках которые охватывает этот прямоугольник
                        хранится одно и то-же значение этого прямоугольника -> int4(X,Y,32,64)
                    с линиями все то-же самое.
                        проверка определения объекта коллизии (примоугольник, линия) происходит автоматически
                        перед самой проверкой коллизии

            информация о слоях уровня (слои должны отображаться и инт массиве как изначально в tmx формате)
        ---------------------------------------------------------------
        части слоев карты могут меняться в процессе игры как самостоятельно так и при воздействии на них.
            при таком изменении нужно учитвать изменение на карте коллизий
        ---------------------------------------------------------------
        объекты:
            у каждого типа объекта ObjectType имеется свое поведение определенное после создания всех объектов json
    */

    // collision_lines:array<int4>  // как объявить НЕ динамический массив известного размера ????????
    // collision_rects:array<int4>
    // intersect_objects:array<GameObject?>

    obj_point_y_offset:float        // смещение от центра высоты ячейки + 1
    inv_obj_point_y_offset:float    // высота ячейки - obj_point_y_offset

    private tmpPoint:int2
    private tmpPointF:float2
    private tmpRect:int4
    private cell:int
    private line:int4
    private rect:int4
    private rect_f:float4

    tmp_robot:TmxTmpObject


    def object_above(var r:int4; var obj:GameObject?)
        // если объект находится на прямоугольнике
        if r[2] > 0 && r[3] > 0
            if int(obj.bounds[1]) + 1 < r[1] + r[3] / 2
                if contains(r, int2(int(obj.bounds[0]), int(obj.bounds[1]) + 1)) 
                    obj.bounds[1] = float( r[1] - 1)
                    obj.jump.velocity = 0f
                    obj.jump.count = 0
                    if obj.bounds[1] != obj.preBounds[1]
                        play_audio("landing", volumeCenter(obj.bounds[0],obj.bounds[1]) * 0.5f)
                    // obj.pinned[3]++  // > 0 = движение в данную сторону запрещено.
      
    def map_collision_detection(delta:float; var obj:GameObject?)
        if obj.is_jump
            obj.jump.velocity = 256f
            obj.jump.count++

        obj.jump.velocity = clamp(obj.jump.velocity - obj.jump.accelerate * delta, -384f, 182f)
        obj.bounds[1] = obj.bounds[1] - obj.jump.velocity * delta

        if obj.is_dead  // мертвый объект может только падать до конца карты (низ карты определяет сам объект)
            return

        // let max_jump_y:int = obj.jump.velocity <= 0f ? int(obj.bounds[1]) : INT_MAX 

        cell = get_cell_by_position(tmx_data, obj.bounds[0], obj.bounds[1])
        triggerDetection(triggers_map[cell], obj)

        cell = get_cell_by_position(tmx_data, obj.bounds[0], obj.bounds[1] + 1f)
        line = collision_lines[cell]        // line (only horizontal. Vertical not supported ) 
        // проверка объекта на нахождении на линии
        if line[2] > 0 && line[3] == 0
            if obj.bounds[1] + 1f > float(line[1]) && obj.preBounds[1] < float(line[1])
                if int(obj.bounds[1]) + 1 >= line[1] 
                    obj.jump.velocity = 0f
                    obj.bounds[1] = float( line[1] - 1)
                    obj.jump.count = 0
                    if obj.bounds[1] != obj.preBounds[1]
                        play_audio("landing", volumeCenter(obj.bounds[0],obj.bounds[1]) * 0.5f)
                    // obj.pinned.rect_bottom = line
                    // obj.pinned[3]++  // > 0 = движение в данную сторону запрещено.
            
        if obj.is_jump
            obj.jump.velocity = 256f

        rect = collision_rects[cell]
        object_above(rect, obj)
        
        // гaлaвой ап пaтaлок
        if obj.bounds[1] - obj.preBounds[1] < 0f
            cell = get_cell_by_position(tmx_data, obj.bounds[0], obj.bounds[1] - obj_point_y_offset)
            rect = collision_rects[cell]
            tmpPoint[0] = int(obj.bounds[0])
            tmpPoint[1] = int(obj.bounds[1] - obj_point_y_offset)
            if contains(rect, tmpPoint)
                obj.bounds[1] = float(rect[1] + rect[3]) + obj_point_y_offset
                obj.jump.velocity = 0f
                // obj.pinned.rect_top = rect
                // obj.pinned[2]++  // > 0 = движение в данную сторону запрещено.


        if obj.is_move_left
            cell = get_cell_by_position(tmx_data, obj.bounds[0] - 1f, obj.bounds[1])
            rect = collision_rects[cell]
            // if rect[2] > 0 && rect[3] > 0
            tmpPoint[0] = int(obj.bounds[0]) - 1
            tmpPoint[1] = int(obj.bounds[1])
            if contains(rect, tmpPoint)
                obj.bounds[0] = float(rect[0] + rect[2])
                // obj.pinned[0]++  // > 0 = движение в данную сторону запрещено.
                // отключить принудительное движение для требуемых объектов
                // obj -> reset_forced_movement()
                // obj.pinned.rect_left = rect
            else
                obj.bounds[0]--

        if obj.is_move_right
            cell = get_cell_by_position(tmx_data, obj.bounds[0] + 1f, obj.bounds[1])
            rect = collision_rects[cell]
            // if rect[2] > 0 && rect[3] > 0
            tmpPoint[0] = int(obj.bounds[0]) + 1
            tmpPoint[1] = int(obj.bounds[1])
            if contains(rect, tmpPoint)
                obj.bounds[0] = float(rect[0] - 1)
                // obj.pinned[1]++  // > 0 = движение в данную сторону запрещено.
                // отключить принудительное движение для требуемых объектов
                // obj -> reset_forced_movement()
                // obj.pinned.rect_right = rect
            else
                obj.bounds[0]++


    def object_collision_detection(delta:float; var obj:GameObject?)
        // if obj.o_type == ObjectType _hero
        //     print("{obj.pinned}\n")

        for k,v in keys(objects), values(objects)
            if k == ObjectType _hero
                k
            if k == ObjectType _movable_box
                k
            if k == ObjectType _universal_robot_1
                k

            if k != obj.o_type
                for target in v
                    if target != obj && overlapsF(obj.bounds, target.bounds)
                
                        if obj.is_move_left
                            obj
                        //     if target.pinned[0] == 0
                        //         target.force_x = -(target.bounds[0] + target.bounds[2] - obj.bounds[0])
                        //     else
                        //         obj.force_x = target.bounds[0] + target.bounds[2] - obj.bounds[0]
                                
                        // else
                        //     if target.pinned[1] == 0
                        //         target.force_x = obj.bounds[0] + obj.bounds[2] - target.bounds[0]
                        //     else
                        //         obj.force_x =  -(obj.bounds[0] + obj.bounds[2] - target.bounds[0])

                        // if obj.bounds[1] - obj.preBounds[1] > 0f
                        //     target.force_y = -(obj.bounds[1] - target.bounds[1])
                        // else
                        //     target.force_y = obj.bounds[1] +obj.bounds[3] - target.bounds[1]

                        // if !intersect_objects |> has_value(obj)
                        //     intersect_objects |> push(obj)
                        // unsafe
                        //     if !intersect_objects |> has_value(upcast<GameObject?> (target))
                        //         intersect_objects |> push(upcast<GameObject?> (target))
                            //  узнать: силу, зажатость, направления объектов
                            //  установить смещение:
                            //      не зажатому
                            //      слабому
                            //      текущему, если вторичный зажат(двже если слабее), или сильнее.
                            //      если второй не добавлен, проверить нахождение в хранилище и добавить если отсутствует.
                            // 

        // for t in intersect_objects
        //     t.bounds[0] += t.force_x
        //     t.bounds[1] += t.force_y
        // while length(intersect_objects) > 0
        //     var gsdg = pop(intersect_objects)

    // def object_collision_handling(var first:GameObject?; var second:GameObject?)
    //     print("first: {first.bounds}\n")
    //     print("second: {second.bounds}\n")
    //     print("-----------------------\n")
    //     second.force_x = first.bounds[0] - second.bounds[0]
    //     second.force_y = first.bounds[1] - second.bounds[1]
    // if !intersect_objects |> has_value(first)
    //     intersect_objects |> push(first)
    // for o in intersect_objects
    

    def override draw
        for o in values(objects)
            for s in o
                if s != null
                    s -> draw()
        bulletsDraw()

    private destroy_object:GameObject?
    def override update(delta:float)
        // turrelAction(delta, hero)
        // clear(intersect_objects)
        // if get_key_down(VK_F12)
        //     add_object_robot(208f,100f)
        // if get_key_down(VK_F11)
        //     pop(intersect_objects)
        destroy_object = null
        for o in values(objects)
            for s in o
                if s != null
                    s -> update(delta)
                    if hero == null && s.o_type == ObjectType _hero
                        // once
                        hero = unsafe(upcast<ObjectHero::ObjectHero?> s)
                        hero.jump_count = storage.jump
                        hero.can_fire = storage.fire
                        hero.can_yell = storage.yell
                    if s.o_type == ObjectType _universal_robot_1     
                        Robots::yell_at_robot(hero, s)
                    map_collision_detection(delta, s)
                    s -> upd2(delta)
                    if s.destroy_object
                        destroy_object <- s
        bulletsUpdate(delta)
        unsafe
            delete(destroy_object)

        var o1_id:int
        // шоб роботы упирались в коробки
        while o1_id < length(objects[ObjectType _universal_robot_1])
            rectCollBack(objects[ObjectType _universal_robot_1][o1_id], ObjectType _movable_box)
            o1_id++
        o1_id = 0
        // что бы коробки упирались в коробки (короба пока нельзя двигать, но они могут падать на другие коробки)
        while o1_id < length(objects[ObjectType _movable_box])
            rectCollBack(objects[ObjectType _movable_box][o1_id], ObjectType _movable_box)
            o1_id++

        // процесс героя с коробами
        if hero != null
            pointIn(hero, ObjectType _movable_box)

        lerp_camera_to_object(objects[ObjectType _hero][0], delta * 4f)


    def pushBox(var f_1:GameObject?; o_type:ObjectType)
        // толкать прямоугольник
        var id:int = 0
        var f_2:GameObject?
        var tmp_point:float2
        while id < length(objects[o_type])
            f_2 = objects[o_type][id]
            tmp_point[0] = f_2.bounds[0] + 8f
            tmp_point[1] = f_2.bounds[1]
            if f_1.bounds[1] > f_1.preBounds[1]
                f_1.bounds[1] = f_2.bounds[1] - f_1.bounds[3]
                f_1.jump.velocity = 0f
                f_1.jump.count = 0
                if f_1.bounds[1] != f_1.preBounds[1]
                    play_audio("landing", volumeCenter(f_1.bounds[0],f_1.bounds[1]) * 0.5f)
            else
                if f_1.is_move_left
                    f_2.bounds[0] = f_1.bounds[0] - f_1.bounds[2] 
                if f_1.is_move_right
                    f_2.bounds[0] = f_1.bounds[0] + f_1.bounds[2]

            // if f_1.bounds[1] < f_1.preBounds[1]
            //     f_1.bounds[1] = f_2.bounds[1] + f_2.bounds[3]
            //     f_1.jump.velocity = 0f
            //     f_1.jump.count = 0
            id++

    def pointIn(var f_1:GameObject?; o_type:ObjectType)
    // точка в прямоугольнике с откатом
    // наезд снизу не реализован
    // http://noregret.org/tutor/n/collision/
    // https://www.gamedev.net/tutorials/_/technical/game-programming/swept-aabb-collision-detection-and-response-r3084/
        var o2_id:int = 0
        var f_2:GameObject?
        var tmp_point:float2
        while o2_id < length(objects[o_type])
            f_2 = objects[o_type][o2_id]
            tmp_point[0] = f_2.bounds[0] + 8f
            tmp_point[1] = f_2.bounds[1]
            if containsF(f_1.bounds, tmp_point)
                if f_1.preBounds[1] >= f_2.bounds[1] && f_1.preBounds[1] <= f_2.bounds[1] + f_2.bounds[3]
                    if f_1.preBounds[0] <= f_1.bounds[0]
                        f_1.bounds[0] = f_2.bounds[0] - f_1.bounds[2] + 8f
                    else 
                        f_1.bounds[0] = f_2.bounds[0] + f_2.bounds[2] - 7f
            if containsF(f_1.bounds, tmp_point)
                if f_1.preBounds[1] < f_1.bounds[1]
                    f_1.bounds[1] = f_2.bounds[1] - f_1.bounds[3]
                    f_1.jump.velocity = 0f
                    f_1.jump.count = 0
            // tmp_point[1] = f_2.bounds[1] + 16f
            o2_id++

    def rectCollBack(var f_1:GameObject?; o_type:ObjectType)
        //  определения пересечения 2х прямоугольников с откатом
        //
        var o2_id:int = 0
        var f_2:GameObject?
        while o2_id < length(objects[o_type])
            f_2 = objects[o_type][o2_id]
            if f_1 != f_2 && overlapsF(f_1.bounds, f_2.bounds)
                if f_1.bounds[1] > f_1.preBounds[1]
                    f_1.bounds[1] = f_2.bounds[1] - f_1.bounds[3]
                    f_1.jump.velocity = 0f
                    f_1.jump.count = 0
                    if f_1.bounds[1] != f_1.preBounds[1]
                        play_audio("landing", volumeCenter(f_1.bounds[0],f_1.bounds[1]) * 0.5f)
                else
                    if f_1.is_move_left
                        f_1.bounds[0] = f_2.bounds[0] + f_2.bounds[2] 
                    if f_1.is_move_right
                        f_1.bounds[0] = f_2.bounds[0] - f_1.bounds[2]

                if f_1.bounds[1] < f_1.preBounds[1]
                    f_1.bounds[1] = f_2.bounds[1] + f_2.bounds[3]
                    f_1.jump.velocity = 0f
                    f_1.jump.count = 0
                // else
                //     if f_1.is_move_left
                //         f_1.bounds[0] = f_2.bounds[0] + f_2.bounds[2] 
                //     if f_1.is_move_right
                //         f_1.bounds[0] = f_2.bounds[0] - f_1.bounds[2]
            o2_id++


    def install()
        level_task[LevelTask _max_born] = tmx_data.level_task["max_robots_born"]
        level_task[LevelTask _save_child_robots] = tmx_data.level_task["save_child_robots"]
        level_task[LevelTask _save_robots] = tmx_data.level_task["save_robots"]

        obj_point_y_offset = tmx_data.tmx_cell_height / 2f + 1f
        inv_obj_point_y_offset = tmx_data.tmx_cell_height - obj_point_y_offset

        clear(bullets.machine_gun_bullets)
        clear(bullets.allied_robot_bullets)
        clear(triggers)
        clear(objects)
        
        clear(collision_lines)
        resize(collision_lines, tmx_data.tmx_map_width * tmx_data.tmx_map_height)
        clear(collision_rects)
        resize(collision_rects, tmx_data.tmx_map_width * tmx_data.tmx_map_height)
        clear(triggers_map)
        resize(triggers_map, tmx_data.tmx_map_width * tmx_data.tmx_map_height)
        for layer in tmx_data.layers
            if layer is object_layer
                for obj in (layer as object_layer).objectsTmp
                    serialize_object(obj, (layer as object_layer).objectsData)


        for tr in triggers
            print("{tr.type_name}\n")
        print("triggers count: {length(triggers)}\n")
        print("map width: {tmx_data.tmx_map_width}\n")
        print("map height: {tmx_data.tmx_map_height}\n")
        hero = null

        
                   
    // serialize objects
    def serialize_object(var objectTmp:TmxTmpObject;var js:array<json::JsonValue?>)
        // objects
        if objectTmp.object_type == "ObjectHero"
            add_object_hero(objectTmp)
        if objectTmp.object_type == "ObjectCreatorPhase1"
            tmp_robot <- objectTmp
        if objectTmp.object_type == "ObjectEnemyRobot1Prepare"
            add_object_enemy_robot(objectTmp)
        if objectTmp.object_type == "MovableBox"
            add_object_movable_box(objectTmp)
        if objectTmp.object_type == "MachineGun"
            add_object_machine_gun(objectTmp)
        if objectTmp.object_type == "WeaponWhip"
            add_weapon_whip(objectTmp)
        // triggers
        if objectTmp.object_type == "DeliveryContainer"
            add_trigger_delivery_container(objectTmp)
        if objectTmp.object_type == "UpgradeContainer"
            add_trigger_upgrade_container(objectTmp)
        if objectTmp.object_type == "ButtonBottom"
            add_trigger_button(objectTmp)
        if objectTmp.object_type == "Exit"
            add_trigger_exit(objectTmp)
        // trigger skill
        add_trigger_skill(objectTmp, objectTmp.object_type)

        // map collisions
        cell = get_cell_by_position(tmx_data, objectTmp.bounds.x, objectTmp.bounds.y)
        var col:int4 = int4(int(objectTmp.bounds[0]),int(objectTmp.bounds[1]),int(objectTmp.bounds[2]),int(objectTmp.bounds[3]))
        if objectTmp.object_type == "PlatformLine"
            for c in range(objectTmp.bounds[2] / tmx_data.tmx_cell_width)
                collision_lines[cell + c] = col
        if objectTmp.object_type == "Rectangle"
            var rows = 0
            // когда рект находится на координатах не кратных 16, в карте коллизий он должен занимать на 1 ячейку больше.
            let r = objectTmp.bounds[1] % tmx_data.tmx_cell_height == 0f ? col[3] / int(tmx_data.tmx_cell_height) : col[3] / int(tmx_data.tmx_cell_height) + 1
            while rows < r
                let row = tmx_data.tmx_map_width * rows++
                let columns = objectTmp.bounds[0] % tmx_data.tmx_cell_width == 0f ? int(objectTmp.bounds[2] / tmx_data.tmx_cell_width) : int(objectTmp.bounds[2] / tmx_data.tmx_cell_width) + 1
                for c in range(columns)
                    collision_rects[cell + row + c] = col
            //         print("{c} | {columns} | {col}\n")
            //     print("row\n")
            // print("----------\n")

    def private copyTmp(var user_obj:TmxSprite?; var tmp:TmxTmpObject)
        user_obj.tile_id := tmp.tile_id
        user_obj.id := tmp.id
        user_obj.object_type := tmp.object_type
        user_obj.name := tmp.name
        user_obj.rotation := tmp.rotation
        user_obj.bounds := tmp.bounds
        user_obj.visible := tmp.visible


    def add_animation(var animationName:Animation; tile_id:int; var obj:GameObject?&; var tileSets:TmxTileSets?)
        var index = 0
        while (index < length(tileSets.animationTiles[tile_id]))
            obj.textures[animationName] |> push(tileSets.textures[tileSets.animationTiles[tile_id][index]].texture_data.texture)
            obj.animations[animationName] |> push(tileSets.textures[tileSets.animationTiles[tile_id][index++]].texture_data.region)
            obj.durations[animationName] |> push(tileSets.animationTiles[tile_id][index++])


    def add_weapon_whip(var tmp_object:TmxTmpObject)
        var w1 = new ObjectWeapon()
        var w2 = new ArsenalWhip()
        print("{w1}\n")

    def add_object_machine_gun(var tmp_object:TmxTmpObject)
        var obj = new ObjectMachineGun()
        copyTmp(obj, tmp_object)
        obj.jump = new Jump()
        var prop <- tmx_data.tileSets.animationProperties[obj.tile_id]
        add_animation(Animation _fire, 705, obj, tmx_data.tileSets)
        add_animation(Animation _run, 709, obj, tmx_data.tileSets) // анимация подготвки к стрельбе
        add_animation(Animation _idle, 7016, obj, tmx_data.tileSets)
        obj -> set_animation(Animation _idle)
        obj.o_type = ObjectType _machine_gun
        objects[obj.o_type] |> push(obj)


    def add_object_movable_box(var tmp_object:TmxTmpObject)
        var obj = new ObjectMovableBox()
        copyTmp(obj, tmp_object)
        obj.jump = new Jump()
        var prop <- tmx_data.tileSets.animationProperties[obj.tile_id]
        add_animation(Animation _idle, 261, obj, tmx_data.tileSets)
        obj -> set_animation(Animation _idle)
        obj.o_type = ObjectType _movable_box
        print("{obj.o_type}\n")
        objects[obj.o_type] |> push(obj)


    def add_object_enemy_robot(var tmp_object:TmxTmpObject)
        var obj = new ObjectEnemyRobot()
        copyTmp(obj, tmp_object)
        obj.jump = new Jump()
        var prop <- tmx_data.tileSets.animationProperties[obj.tile_id]
        add_animation(Animation _run, 744, obj, tmx_data.tileSets)
        add_animation(Animation _idle, 737, obj, tmx_data.tileSets)
        obj -> set_animation(Animation _run)
        obj.o_type = ObjectType _enemy_robot_1
        objects[obj.o_type] |> push(obj)

    def add_object_robot(born_on_x:float;born_on_y:float)
    // объект должен быть на карте при инициализации для получения его шаблонных данных, либо вводим вручную в коде.
        var obj = new ObjectUniversalRobot()
        // copyTmp(obj, tmp_robot)
        obj.jump = new Jump()
        obj.bounds[0] = born_on_x
        obj.bounds[1] = born_on_y
        obj.bounds[2] = 16f
        obj.bounds[3] = 16f
        obj.tile_id = 0
        obj.id = 0
        obj.rotation = 0f
        obj.visible = true
        var prop <- tmx_data.tileSets.animationProperties[obj.tile_id]
        add_animation(Animation _run, 865, obj, tmx_data.tileSets)
        add_animation(Animation _idle, 801, obj, tmx_data.tileSets)
        obj -> set_animation(Animation _run)
        obj.o_type = ObjectType _universal_robot_1
        objects[obj.o_type] |> push(obj)

    def add_object_hero(var tmp_object:TmxTmpObject)
        var obj = new ObjectHero()
        copyTmp(obj, tmp_object)
        obj.jump = new Jump()
        var prop <- tmx_data.tileSets.animationProperties[obj.tile_id]
        add_animation(Animation _idle, obj.tile_id, obj, tmx_data.tileSets)
        add_animation(Animation _run, 545, obj, tmx_data.tileSets)
        add_animation(Animation _landing, 515, obj, tmx_data.tileSets)
        add_animation(Animation _aggressive, 577, obj, tmx_data.tileSets)
        add_animation(Animation _fire, 609, obj, tmx_data.tileSets)
        obj -> set_animation(Animation _idle)
        obj.o_type = ObjectType _hero
        // obj.can_forced = true
        objects[obj.o_type] |> push(obj)
        
//----------------------------------TRIGGERS-----------------------------------------------------------------
    
    def triggerDetection(var t:Trigger?; var obj:GameObject?)
        tmpPointF[0] = obj.bounds[0]
        tmpPointF[1] = obj.bounds[1]
        if t == null || t.powered
            return
        if t.type_name == TriggerName _button
            if containsF(t.bounds, tmpPointF) 
                t.powered = true
                if t.target == null
                    for tt in triggers
                        if tt.id == t.target_id
                            tt.powered = true
                            t.target = tt
                            t.activator = obj
                            break
                else
                    t.target.powered = true
            
        if t.type_name == TriggerName _exit && obj.o_type == ObjectType _universal_robot_1
            if containsF(t.bounds, tmpPointF) && !obj.is_mission_completed
                if obj.evolution_phase == 0
                    t.powered = true
                    obj.is_mission_completed = true
        if t.type_name == TriggerName _skill_jump || t.type_name == TriggerName _skill_sword || t.type_name == TriggerName _skill_yell
            if containsF(t.bounds, tmpPointF)
                play_audio("take", 0.7f)
                t.powered = true
        

    def add_trigger_skill(var tmp_object:TmxTmpObject; skill_name:string)
        var skill:TriggerName
        var skill_id:int
        if skill_name == "skill_jump"
            skill = TriggerName _skill_jump
            skill_id = 1029
            // не отображает скилл на карте если у перса предел скилов (перенести туда где hero != null, так кака при загрузке приложения и CONTINUE hero == null, но скилы могут быть сохранены и максимальны. В итоге скилл отобразится на карте)
            // if hero != null && hero.jump_count > 1 
            //     return
        elif skill_name == "skill_sword"
            skill_id = 1030
            skill = TriggerName _skill_sword
        elif skill_name == "skill_yell"
            skill_id = 1031
            skill = TriggerName _skill_yell
        else 
            return
        let trig <- fillCells(tmp_object.bounds)
        var t:Trigger? = null
        if length(trig) > 0
            t = new Trigger
            t.type_name = skill
            t.id = tmp_object.id
            t.target_name = tmp_object.name
            t.visible = true
            t.cell = -1
            t.powered = false
            // t.counter = level_task.max_born
        push(t.textures, tmx_data.tileSets.textures[skill_id].texture_data.texture)
        push(t.regions, tmx_data.tileSets.textures[skill_id].texture_data.region)
        push(t.position, float2(tmp_object.bounds[0] - 8f, tmp_object.bounds[1] - 8f))
        push(t.colors, 0xFFFFFFFF)
        t.bounds = float4(tmp_object.bounds[0] - 8f, tmp_object.bounds[1] - 8f, tmp_object.bounds[2], tmp_object.bounds[3])
        push(triggers, t)
        addToTrigMap(t, trig)

    def add_trigger_exit(var tmp_object:TmxTmpObject)
        let trig <- fillCells(tmp_object.bounds)
        var t:Trigger? = null
        if length(trig) > 0
            t = new Trigger
            t.type_name = TriggerName _exit
            t.id = tmp_object.id
            t.target_name = tmp_object.name
            t.visible = true
            t.cell = -1
            t.powered = false
            // t.counter = level_task.save_child
        t.bounds = float4(tmp_object.bounds[0] , tmp_object.bounds[1] , tmp_object.bounds[2], tmp_object.bounds[3])
        push(triggers, t)
        addToTrigMap(t, trig)


    def add_trigger_button(var tmp_object:TmxTmpObject)
        let trig <- fillCells(tmp_object.bounds)
        var t:Trigger? = null
        if length(trig) > 0
            t = new Trigger
            t.id = tmp_object.id
            t.type_name = TriggerName _button
            t.target_name = tmp_object.name
            t.visible = true
            t.cell = -1
            t.powered = false
            // t.timer = 0.5f
        push(t.textures, tmx_data.tileSets.textures[357].texture_data.texture)
        push(t.regions, tmx_data.tileSets.textures[357].texture_data.region)
        push(t.textures, tmx_data.tileSets.textures[358].texture_data.texture)
        push(t.regions, tmx_data.tileSets.textures[358].texture_data.region)
        push(t.colors, 0xFFFFFFFF)
        push(t.position, float2(tmp_object.bounds[0] - 8f, tmp_object.bounds[1] - 8f))
        t.bounds = float4(tmp_object.bounds[0] - 8f, tmp_object.bounds[1] + 4f, tmp_object.bounds[2], tmp_object.bounds[3] - 12f)
        if tmp_object.properties != null
            for props in tmp_object.properties.prop as _array
                var val <-  props as _object
                let name = val["name"] as _string
                if name == "target"
                    t.target_id = int(val["value"] as _number)

        push(triggers, t)
        addToTrigMap(t, trig)

    def add_trigger_delivery_container(var tmp_object:TmxTmpObject)
        let trig <- fillCells(tmp_object.bounds)
        var t:Trigger? = null
        if length(trig) > 0
            t = new Trigger
            t.type_name = TriggerName _delivery_container
            t.id = tmp_object.id
            t.target_name = tmp_object.name
            t.visible = true
            t.cell = -1
            t.powered = false
            // t.counter = level_task.max_born
        push(t.textures, tmx_data.tileSets.textures[1026].texture_data.texture)
        push(t.regions, tmx_data.tileSets.textures[1026].texture_data.region)
        push(t.position, float2(tmp_object.bounds[0] - 8f , tmp_object.bounds[1] + 16f))
        push(t.colors, 0x20FFFFFF)
        push(t.textures, tmx_data.tileSets.textures[1027].texture_data.texture)
        push(t.regions, tmx_data.tileSets.textures[1027].texture_data.region)
        push(t.position, float2(tmp_object.bounds[0] + 8f , tmp_object.bounds[1] ))
        push(t.colors, 0x20FFE030)
        t.bounds = float4(tmp_object.bounds[0] , tmp_object.bounds[1] , tmp_object.bounds[2], tmp_object.bounds[3])
        push(triggers, t)
        addToTrigMap(t, trig)

    //  energy field id = 1026
    //  rhombus id = 1027
    def add_trigger_upgrade_container(var tmp_object:TmxTmpObject)
        let trig <- fillCells(tmp_object.bounds)
        var t:Trigger? = null
        if length(trig) > 0
            t = new Trigger
            t.type_name = TriggerName _upgrade_container
            t.id = tmp_object.id
            t.target_name = tmp_object.name
            t.visible = true
            t.cell = -1
            t.powered = true
            t.counter = -1
        push(t.textures, tmx_data.tileSets.textures[1026].texture_data.texture)
        push(t.regions, tmx_data.tileSets.textures[1026].texture_data.region)
        push(t.position, float2(tmp_object.bounds[0] - 8f , tmp_object.bounds[1] + 16f))
        push(t.colors, 0xFFFFFFFF)
        push(t.textures, tmx_data.tileSets.textures[1027].texture_data.texture)
        push(t.regions, tmx_data.tileSets.textures[1027].texture_data.region)
        push(t.position, float2(tmp_object.bounds[0] + 8f , tmp_object.bounds[1] ))
        push(t.colors, 0xFF30FF30)
        t.bounds = float4(tmp_object.bounds[0] , tmp_object.bounds[1] , tmp_object.bounds[2], tmp_object.bounds[3])
        push(triggers, t)
        addToTrigMap(t, trig)

    def addToTrigMap(var t:Trigger?; triggs:table<int;float4>)
        // ячейки занимающие площадь триггера заполняются структурой триггера с требуемыми данными, либо null
        for k, v in keys(triggs),values(triggs)
            if t.cell < 0
                t.cell = k
            triggers_map[k] = t

    def private fillCells(b:float4):table<int;float4>
        var boundies:table<int;float4>
        cell = get_cell_by_position(tmx_data, b[0], b[1])
        var rows = 0
        // когда рект находится на координатах не кратных 16, в карте коллизий он должен занимать на 1 ячейку больше.
        let r = b[1] % tmx_data.tmx_cell_height == 0f ? b[3] / tmx_data.tmx_cell_height : b[3] / tmx_data.tmx_cell_height + 1f
        while float(rows) < r
            let row = tmx_data.tmx_map_width * rows++
            let columns = b[0] % tmx_data.tmx_cell_width == 0f ? int(b[2] / tmx_data.tmx_cell_width) : int(b[2] / tmx_data.tmx_cell_width) + 1
            for c in range(columns)
                boundies[cell + row + c] = b
        return <- boundies
//-----------------------------------------------------------------------------------------------------------
    def bulletsUpdate(delta:float)
        for b in bullets.machine_gun_bullets
            if b[1] != 0f   // пуля не может находиться на Y = 0 (пуля не существует если Y = 0)
                if b[2] == 0f
                    b[0] += delta * 200f
                else
                    b[0] -= delta * 200f
                tmpRect[0] = int(b[2] == 0f ? b[0] : b[0] - bullets.machine_gun_bullet_width)
                tmpRect[1] = int(b[1])
                tmpRect[2] = int(bullets.machine_gun_bullet_width)
                tmpRect[3] = 1
                if overlaps(collision_rects[get_cell_by_position(tmx_data, b[0], b[1])], tmpRect)
                    b[1] = 0f
        for b in bullets.allied_robot_bullets
            if b[1] != 0f   // пуля не может находиться на Y = 0 (пуля не существует если Y = 0)
                if b[2] == 0f
                    b[0] += delta * 200f
                else
                    b[0] -= delta * 200f
                tmpRect[0] = int(b[2] == 0f ? b[0] : b[0] - bullets.machine_gun_bullet_width)
                tmpRect[1] = int(b[1])
                tmpRect[2] = int(bullets.machine_gun_bullet_width)
                tmpRect[3] = 1
                if overlaps(collision_rects[get_cell_by_position(tmx_data, b[0], b[1])], tmpRect)
                    b[1] = 0f

    def bulletsDraw()
        for b in bullets.machine_gun_bullets
            if b[1] != 0f
                rect(b[2] == 0f ? b[0] : b[0] - bullets.machine_gun_bullet_width,b[1],bullets.machine_gun_bullet_width,1f,0xFFFF0000)
        for b in bullets.allied_robot_bullets
            if b[1] != 0f
                rect(b[2] == 0f ? b[0] : b[0] - bullets.machine_gun_bullet_width,b[1],bullets.machine_gun_bullet_width,1f,0xFFA3B12B)


// TODO вылетают с карты. Скорее всего при падении с большой высоты с задержкой дельты.
