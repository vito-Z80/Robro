require TMX
require GameObject
require gameUtils
require daslib/media
require GameAudio


class ObjectHero:GameObject
    

    aggressive_area_color = 0x32FFFFFF
    aggressive_area_img:ImageHandle = create_managed_image("gfx/sound.png",true,true)    //  TODO НУЖНО загрузить позже !!!
    aggressive_area_img_rect = float4(0,0,128,64)
    aggressive_area:float4 = float4(0,0,0,64)
    aggressive_volume:float = 0f
    aggressive_sound_playing:PlayingSoundHandle = play_audio("yell",0.3f,true)

    _test:GameObject
    tmp_bounds:float4
    can_fire:bool
    can_yell:bool
    jump_count:int

    def override draw()
        draw_aggressive_area_img()
        GameObject`draw(self)

    def override update(delta:float)

        set_animation(Animation _idle)

        if is_dead
            is_jump = false
            if jump.velocity < 0f
                color -= 0x04000000
                if color <= 0x10FFFFFF
                    color = 0x04FFFFFF
                    // destroy_object = true
            return


        tmp_bounds[0] = bounds[0] - 8f
        tmp_bounds[1] = bounds[1] - 16f
        tmp_bounds.zw = bounds.zw
        for b in bullets.machine_gun_bullets
            if b[1] != 0f
                if containsF(tmp_bounds, b.xy)
                    is_hero_died = true
                    is_dead = true
                    is_jump = true
                    is_move_left = false
                    is_move_right = false
                    b[1] = 0f
                    return


        is_move_left = get_key(VK_LEFT) || get_key(VK_O) || get_axis(AXIS_PRIMARY_X) < 0f
        is_move_right = get_key(VK_RIGHT) || get_key(VK_P) || get_axis(AXIS_PRIMARY_X) > 0f
        is_jump = jump_count != 0 && get_key_down(VK_SPACE) && jump.count < jump_count || jump_count != 0 && get_key_down(GP_X) && jump.count < jump_count
        is_fire = can_fire && get_key(GP_Y) || can_fire && get_key(VK_LCONTROL)
        is_aggressive =  can_yell && get_key(GP_A) || can_yell && get_key(VK_LALT)
        GameObject`update(self,delta)
        if is_move_left || is_move_right
            set_animation(Animation _run)
        if is_fire
            set_animation(Animation _fire)
        elif is_aggressive
            set_animation(Animation _aggressive)
        
        if is_jump
            play_audio("jump",0.1f)

        transform_aggressive_area(delta)
    
    def transform_aggressive_area(delta:float)
        if animation_name == Animation _aggressive
            aggressive_area_img |> set_image_clamp(false)
            aggressive_area_img |> set_image_smooth(true)
            if !flip_x
                aggressive_area_img_rect[0] -= 3.33f
                aggressive_area[2] += 2f
                aggressive_area[0] = bounds[0]
                aggressive_area[1] = bounds[1] - aggressive_area[3] / 2f
            else
                aggressive_area_img_rect[0] += 3.33f
                aggressive_area[2] += 2f
                aggressive_area[0] = bounds[0] - aggressive_area[2]     
                aggressive_area[1] = bounds[1] - aggressive_area[3] / 2f   
            // if aggressive_area[2] == 2f
            //     aggressive_sound_playing = play_audio("yell",0.3f,true)
        else 
            aggressive_area[2] = 0f
        aggressive_area[2] = clamp(aggressive_area[2] , 0f, 128f)
        if aggressive_area[2] > 0f
            aggressive_volume += delta
        else
            aggressive_volume -= delta
        aggressive_volume = clamp(aggressive_volume, 0f, 0.3f)
        set_sound_volume(aggressive_sound_playing, aggressive_volume)

    def draw_aggressive_area_img()
        if aggressive_area[2] > 0f
            aggressive_area_img_rect[2] = aggressive_area[2]
            draw_image_region(aggressive_area_img,aggressive_area[0],aggressive_area[1],aggressive_area_img_rect,aggressive_area_color)

 
