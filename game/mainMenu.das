require daslib/media
require gameUtils
require GameAudio
require Screen

struct private TextLine
    name : string
    point : float2
    color : uint

let info_text:string = "Esc - restart level\nCtrl+Q - main menu\nI - level task"
let completed_text:string = "Game Demo Completed..."
var select = 255

class MainMenu:Screen

    is_close:bool
    

    t_lines = [[TextLine
        [[TextLine name = "New Game", point = float2(100f,100f)]];
        [[TextLine name = "Continue", point = float2(100f,130f)]];
        [[TextLine name = "Reset", point = float2(100f,160f)]];
        [[TextLine name = "Exit", point = float2(100f,190f)]]
    ]]

    bg <- create_managed_image(
        "gfx/SBS - Seamless Space Backgrounds - Small 512x512/Small 512x512/Purple Nebula/Purple Nebula 7 - 512x512.png",
        true,true
        )
    bgRect:float4 = float4(0f,0f,512f,512f)
    angle : float2
    bound:float4

    def override update(delta:float)
        bgRect.x -= 0.39
        angle.x += delta/17f
        if is_close
            if foreground_process(delta, true)
                appScreen = AppScreen _prepare_game
                is_close = false
                set_font_name("gfx/Comfortaa/static/Comfortaa-light.ttf")
                set_font_size(24)
            return
        else
            foreground_process(delta)

        if get_key_down(VK_SPACE) || get_key_down(VK_RETURN)
            listener()
            return
        
        if get_mouse_button_down(MB_LEFT)
            for id in range(length(t_lines))
                bound = float4(t_lines[id].point.x - 20f, t_lines[id].point.y + 2f, 200f, 30f)
                if contains(get_mouse_position())
                    listener()
                    return


        // if appState == AppState enter_main_menu
        //     setup_2d_camera(float2(float(WIDTH / 2),float(HEIGHT / 2)),1f)
        //     if !fade_in(foregroundColor)
        //         appState = AppState wait
        // if appState == AppState exit_main_menu
        //     if !fade_out(foregroundColor)
        //         appState = AppState prepare_game
        //         appScreen = AppScreen _game

        // if appState == AppState wait || appState == AppState enter_main_menu
        if get_mouse_position_delta().x != 0f && get_mouse_position_delta().y != 0f
            select = 255
            mouse_motion()
        if get_key_down(VK_DOWN) || get_axis(AXIS_TRIGGERS) < 0f
            select = (select + 1) & 3
        if get_key_down(VK_UP)
            select = (select - 1) & 3


    def override draw()
        bg |> set_image_clamp(false)
        draw_image_transformed(bg,256f,192f,bgRect,0xFFFFFFFF,float2(640f,640f),angle.x)
        set_font_name("gfx/Comfortaa/static/Comfortaa-light.ttf")
        set_font_size(24)
        enable_alpha_blend()
        for id in range(length(t_lines))
            if select == id
                fill_rect(t_lines[id].point.x - 20f, t_lines[id].point.y + 2f,200f,30f, 0x33FFFFFF)
                rect(t_lines[id].point.x - 20f, t_lines[id].point.y + 2f,200f,30f, 0x1800FF66)
            text_out(t_lines[id].point.x, t_lines[id].point.y, t_lines[id].name, textColor)
        disable_alpha_blend()
        if is_demo_completed
            text_out(20f,float(HEIGHT) - 30f, completed_text, 0xFF00AA00)
        set_font_name("gfx/Scrum.ttf")
        set_font_size(16)
        text_out(20f,20f,info_text,0xFF627399)

    def private listener()
        if select == 0
            load()      // закоментить, тогда набранные скиллы для новой игры будут обнуляться.
            storage.level = 0
            is_close = true
        if select == 1
            if load()
                is_close = true
            else
                play_audio("error", 0.1f)
        if select == 2
            storage.level = 0
            storage.jump = 0
            storage.fire = false
            storage.yell = false
            play_audio("take", 0.1f)
            save()
        if select == 3
            is_shoot_down = true

    def private mouse_motion()
        for id in range(length(t_lines))
            bound = float4(t_lines[id].point.x - 20f, t_lines[id].point.y + 2f, 200f, 30f)
            if contains(get_mouse_position())
                select = id

    def private contains(point:float2)
        return bound.x <= point.x && bound.x + bound[2] >= point.x && bound.y <= point.y && bound.y + bound[3] >= point.y