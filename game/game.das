require daslib/media
require gameUtils
require CORE
require Screen
require TMX
require ObjectHero
require GameAudio


let level_paths = [[string
    // "map/level_04.json";
    "map/level_01.json";
    "map/level_02.json";
    "map/level_03_2.json";
    "map/level_04.json"
]]


class Game:Screen

    show_info_message:string

    robot_died_time:int     // когда созданный робот умер - идет отсчет времени до рестарта уровня.
    robot_died_message:string = "The robot died, sorry."
    hero_died_message:string = "Your hero is dead."
    fine_message:string = "Manufacture completed"
    fine_message_color:uint = 0x00FFFFFF

    save_child_robots:int
    save_robots:int
    is_level_completed:bool = false

    core:Core?
    is_debug:bool = false
    to_main_menu:bool
    is_open:bool

    message_position:float2
    messages = [[string
    "Can Jump now";
    "Double Jump activate !!!";
    "Try Attacked";
    "Can YELL !!!"
    ]]

    task_time:int
    task_color:uint
    task_message_create:string = "create: "
    task_message_elevator:string = "to elevator: "
    task_message_die:string = "can die: "

    def override update(delta:float)
        if to_main_menu
            if foreground_process(delta, true)
                to_main_menu = false
                appScreen = AppScreen _main_menu
                camera_bounds[0] = 0f
                camera_bounds[1] = 0f
                setup_2d_camera(float2(float(WIDTH / 2),float(HEIGHT / 2)),1f)
                return

        if appScreen == AppScreen _prepare_game
            if is_open
                if foreground_process(delta)
                    is_open = false
                    task_time = 300
                    task_color = 0x73677EFF
                    appScreen = AppScreen _game
            else
                prepare()
                return
        if is_level_completed
            fine_message_color = clamp(fine_message_color + 0x01000000, 0x0 , 0xFDFFFFFF)
            if fine_message_color >0xFD000000
                if foreground_process(delta, true)
                    is_level_completed = false
                    fine_message_color = 0x00FFFFFF
                    camera_bounds[0] = 0f
                    camera_bounds[1] = 0f
                    setup_2d_camera(float2(float(WIDTH / 2),float(HEIGHT / 2)),1f)
                    storage.level++
                    if storage.level == length(level_paths)
                        storage.level--
                        is_demo_completed = true
                        appScreen = AppScreen _main_menu
                    else
                        appScreen = AppScreen _prepare_game
                    if hero != null
                        storage.jump = hero.jump_count
                        storage.fire = hero.can_fire
                        storage.yell = hero.can_yell
                    show_info_message = ""
                    save()
                    return

        if get_key_down(VK_ESCAPE)
            appScreen = AppScreen _prepare_game

        if is_robot_died || is_hero_died
            robot_died_time++
            if robot_died_time > 200
                appScreen = AppScreen _prepare_game

        if get_key_down(VK_I)
            if task_time == 0
                task_time = 300
                task_color = 0x73677EFF

        if get_key(VK_LCONTROL) && get_key_down(VK_Q)
            to_main_menu = true

        if get_key_down(VK_F1)
            if !local_storage_has_key("screenshots")
                local_storage_set("screenshots","0")
            else
                let ss_id = int(local_storage_get("screenshots"))
                schedule_screenshot("gfx/screenshots/scr_{ss_id}.png")
                local_storage_set("screenshots","{ss_id + 1}")

        if get_key_down(VK_F8)
            is_debug = !is_debug
        updateTriggers(delta)
        updateInfo(delta)
        key_listener()

        if tmx_data != null
            tmx_data -> update(delta)
        if core != null
            core -> update(delta)


    def override draw
        fill_rect(camera_position[0] - float(WIDTH) / 2f, camera_position[1] - float(HEIGHT) / 2f, float(WIDTH), float(HEIGHT), backgroundColor)
        if tmx_data != null
            enable_alpha_blend()
            for l in tmx_data.layers
                if l is layer
                    (l as layer) -> draw()
                else
                    if core != null
                        core -> draw()    
            drawTriggers()
            if is_level_completed
                set_font_name("gfx/Comfortaa/static/Comfortaa-light.ttf")
                set_font_size(24)
                text_out(camera_position[0] - get_text_size(fine_message)[0] / 2f,
                camera_position[1] - get_text_size(fine_message)[1] / 2f,fine_message,fine_message_color) 
            if is_robot_died
                set_font_name("gfx/Comfortaa/static/Comfortaa-light.ttf")
                set_font_size(24)
                text_out(
                    camera_position[0] - get_text_size(robot_died_message)[0] / 2f,
                    camera_position[1] - get_text_size(robot_died_message)[1] / 2f,
                    robot_died_message,0xFFFF0000) 
            elif is_hero_died
                set_font_name("gfx/Comfortaa/static/Comfortaa-light.ttf")
                set_font_size(24)
                text_out(
                    camera_position[0] - get_text_size(robot_died_message)[0] / 2f,
                    camera_position[1] - get_text_size(robot_died_message)[1] / 2f,
                    hero_died_message,0xFFFF0000)  


            drawInfo()
            disable_alpha_blend()


            if is_debug
                // debug grid 16x16
                for y in range(tmx_data.tmx_map_height)
                    for x in range(tmx_data.tmx_map_width)
                        rect(x * 16, y * 16, 17, 17, 0xff775577)

                // debug collisions
                for l in tmx_data.layers
                    if !l is layer
                        if core != null
                            for line in collision_lines
                                rect(line[0],line[1],line[2],1,0xFFFF0000)
                            for rect in collision_rects
                                rect(rect[0],rect[1],rect[2],rect[3],0xFFFF0000)
                            for o_t in values(objects)
                                for o in o_t
                                    // rect(o.bounds[0],o.bounds[1],o.bounds[2],o.bounds[3],0xFFFF0000)
                                    if o != null
                                        rect(o.bounds[0] - o.bounds[2] / 2f,(o.bounds[1] - o.bounds[3] / 2f) - core.inv_obj_point_y_offset,o.bounds[2],o.bounds[3],0xFFFF0000)
                            if hero != null
                                rect(hero.aggressive_area[0],hero.aggressive_area[1],hero.aggressive_area[2],hero.aggressive_area[3], 0xFF00FFFF)
                                rect(hero.bounds[0],hero.bounds[1],2f,1f,0xFF00FFFF)
                // var b_count = 0
                // for b in bullets.machine_gun_bullets
                //     if b[1] != 0f
                //         b_count++
                // text_out(20f,170f,"max bullets: {length(bullets.machine_gun_bullets)} | visible bullets: {b_count}",0xFF141292)
                for trigger in triggers
                    if trigger.visible
                        rect(trigger.bounds[0],trigger.bounds[1],trigger.bounds[2],trigger.bounds[3],0xFF00FF00)
                rect(camera_bounds[0],camera_bounds[1],camera_bounds[2],camera_bounds[3],0xFFFF00C8)


        // hero`draw_aggressive_area_img()
    def private prepare()
        is_robot_died = false
        is_hero_died = false
        robot_died_time = 0
        if tmx_data == null
            tmx_data = new Tmx()
        if core == null
            core = new Core()
        // create new level
        tmx_data -> parse(level_paths[storage.level])
        // create game objects
        core -> install()
        is_open = true


//          TRIGGERS PROCESS
    private trig_size:float2
    def drawTriggers()
        for t in triggers
            if t.visible
                for c in range(length(t.position))
                    trig_size[0] = t.regions[c][2]
                    trig_size[1] = t.regions[c][3]
                    if c == 0
                        // {}
                        draw_image_region(t.textures[c], t.position[c][0],t.position[c][1],t.regions[c], t.colors[c])
                    else            
                        draw_image_transformed(t.textures[c],t.position[c][0],t.position[c][1],t.regions[c],t.colors[c],trig_size,t.angle)


    private stone_pillar_handle:PlayingSoundHandle
    private remove_trigger:int
    def updateTriggers(delta:float)
        remove_trigger = -1
        for t in triggers
            if t.visible
                if t.type_name == TriggerName _button
                    triggerButton(delta, t)
                if t.type_name == TriggerName _delivery_container
                    if t.powered && level_task[LevelTask _max_born] > 0
                        if t.timer == 0f
                            play_audio("delivery_activate", volumeCenter(camera_position[0],camera_position[1]) * 0.7f)
                            t.p1 = true
                        t.timer+=delta
                        // усиление цвета ромба
                        if t.p1
                            t.colors[1] += 0x01000000
                            if t.colors[1] > 0xF0000000
                                t.p2 = true
                                t.p1 = false
                        // вращение ромба
                        if t.p2
                            if t.angle == 0f
                                stone_pillar_handle = play_audio("stone_pillar", volumeCenter(camera_position[0],camera_position[1]) * 0.7f)
                            t.angle = clamp(t.angle + delta * 2f,0f,1.6f)
                            if t.angle >= 1.6f
                                t.angle = 1.6f
                                t.p3 = true
                                t.p2 = false
                                // FIXME после второго раза не работает выключение звука !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                                stop_sound(stone_pillar_handle)
                        // усиление цвета энергетического поля, рождение робота
                        if t.p3
                            t.colors[0] += 0x01000000
                            if t.colors[0] > 0xF0000000
                                t.p4 = true
                                t.p3 = false
                                t.timer = 0.01f
                                core -> add_object_robot(t.bounds[0] + 8f, t.bounds[1])
                                play_audio("reload_alien", volumeCenter(camera_position[0],camera_position[1]) * 0.7f)
                        // wait
                        if t.p4
                            if t.timer >= 1f
                                t.p5 = true
                                t.p6 = true
                                t.p4 = false
                                stone_pillar_handle = play_audio("stone_pillar", volumeCenter(camera_position[0],camera_position[1]) * 0.7f)
                        // отключение оборудования (уменьшение цвета, вращение ромба)
                        if t.p5
                            t.colors[0] -= 0x01800000
                            t.colors[1] -= 0x01800000
                            t.angle = clamp(t.angle - delta * 2f,0f,1.6f)
                            // вращение ромба на прежнее место закончено
                            if t.angle <= 0f
                                t.angle = 0f
                                stop_sound(stone_pillar_handle)
                                if t.p6
                                    t.p6 = false
                                    play_audio("energy_orb", volumeCenter(camera_position[0],camera_position[1]) * 0.7f)
                                
                            if t.colors[0] <= 0x20000000
                                t.colors[0] ^= 0x02000000
                                t.colors[1] ^= 0x02000000
                                t.p5 = false
                                t.powered = false
                                t.timer = 0f
                                level_task[LevelTask _max_born]--
                                if level_task[LevelTask _max_born] == 0
                                    t.colors[0] = 0x00000000
                                    t.colors[1] = 0xFF811919
                                    t.activator = null
                                    t.target = null
                                    t.target_id = -1
                if t.type_name == TriggerName _upgrade_container
                    if t.p1
                        // print("upgrade process\n")
                        t.p1 = false
                // level completed
                if t.type_name == TriggerName _exit && t.powered
                    level_task[LevelTask _save_child_robots]--
                    // level_task[LevelTask _save_robots]--
                    t.powered = false
                    is_level_completed = level_task[LevelTask _save_child_robots] <= 0 // && level_task[LevelTask _save_robots] <= 0
                // skills
                if t.type_name == TriggerName _skill_jump && t.powered
                    show_info_message = messages[hero.jump_count]
                    hero.jump_count = clamp(hero.jump_count + 1, 0, 2)  // MAX double jumps
                    t.powered = false
                    t.visible = false
                if t.type_name == TriggerName _skill_sword && t.powered
                    hero.can_fire = true
                    t.powered = false
                    t.visible = false
                    show_info_message = messages[2]
                if t.type_name == TriggerName _skill_yell && t.powered
                    hero.can_yell = true
                    t.powered = false
                    t.visible = false
                    show_info_message = messages[3]



    private activator_point:float2
    def private triggerButton(delta:float; var t:Trigger?)
        if t.powered
            // кнопка активирована: установить изображение нажатой кнопки
            if t.regions[0] == tmx_data.tileSets.textures[357].texture_data.region
                t.regions[0] = tmx_data.tileSets.textures[358].texture_data.region
                // if t.target_id < 0
                //     play_audio("error")
                return
            // позиция нажимающего
            activator_point[0] = t.activator != null ? t.activator.bounds[0] : 0f
            activator_point[1] = t.activator != null ? t.activator.bounds[1] : 0f
            // если нажимающий вне кнопки = вернуть изображение отжатой кнопки, отключить кнопку до следующего нажатия.
            if !containsF(t.bounds, activator_point)
                t.powered = false
                t.regions[0] = tmx_data.tileSets.textures[357].texture_data.region


    ///////////////////////////////////// information messages /////////////////////////////////////
    def private drawInfo()
        if message_position[1] > camera_position[0] - float(HEIGHT)
            set_font_name("gfx/Comfortaa/static/Comfortaa-light.ttf")
            set_font_size(24)
            text_out(message_position[0], message_position[1], show_info_message, 0xFF00FF15)
            // print("JC: {messages}\n")


        if task_time > 0
            task_time--
            if task_time < 100
                task_color -= 0x01000000
            set_font_name("gfx/Scrum.ttf")
            set_font_size(16)
            text_out(camera_position[0] - float(WIDTH / 2) + 4f, camera_position[1] - float(HEIGHT / 2), 
            "{task_message_create}{level_task[LevelTask _max_born]}\n{task_message_elevator}{level_task[LevelTask _save_child_robots]}", 
            task_color)

    private message_show_time:float
    def private updateInfo(delta:float)
        if !empty(show_info_message)
            let t_size = get_text_size(show_info_message)
            message_position[0] = camera_position[0] - t_size[0] / 2f
            message_position[1] = camera_position[1] - t_size[1] / 2f
            message_show_time += delta
            if message_show_time >= 4f
                show_info_message = ""
                message_show_time = 0f
                message_position[1] = -1000f

