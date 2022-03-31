require TMX
require gameUtils
require GameObject
require daslib/media
require GameAudio

class ObjectMachineGun:GameObject

    timer:float
    flip_timer:float
    flip:bool
    fire_sound:PlayingSoundHandle
    recharge_sound:PlayingSoundHandle
    tmp_bounds:float4

    def override update(delta:float)
        if is_dead
            is_jump = false
            if jump.velocity < 0f
                color -= 0x04000000
                if color <= 0x10FFFFFF
                    color = 0x04FFFFFF
                    destroy_object = true
            return

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

        if timer <= 0f && animation_name == Animation _fire
            timer = float(rnd(15))
            animation_name = Animation _idle
        
        if timer <= 0f && animation_name == Animation _run
            stop_sound(recharge_sound)
            timer = 0.7f
            fire_sound = play_audio("machine_gun", volumeCenter(bounds[0],bounds[1]) * 0.7f)
            animation_name = Animation _fire

        if timer <= 0f && animation_name == Animation _idle
            timer = 2f
            recharge_sound = play_audio("recharge", volumeCenter(bounds[0],bounds[1]) * 0.5f)
            animation_name = Animation _run

        if timer > 0f && animation_name == Animation _idle
            if rnd(255) == 3
                flip_x = !flip_x

        timer -= delta

        if animation_name == Animation _fire
            flip_timer += delta
            if flip_timer >= 0.7f / 6f
                for b in bullets.machine_gun_bullets
                    if b[1] == 0f
                        b[0] = bounds[0]
                        b[1] = bounds[1] - 9f
                        b[2] = flip_x ? 1f : 0f
                        flip_timer = 0f
                        break
                if flip_timer != 0f
                    flip_timer = 0f
                    bullets.machine_gun_bullets |> push(float3(bounds[0],bounds[1] - 9f, flip_x ? 1f : 0f))
        GameObject`update(self,delta)
