require gameUtils
require game
require daslib/media
require mainMenu
require daslib/sound
require GameAudio
// require daslib/graphics
// options debugger            // uncomment for debug in VS Code
// require daslib/debug        // uncomment for debug in VS Code
var mainMenu = new MainMenu()
var game:Game? = null
// var gm:PcmSound

[export]
def initialize
/*
    https://spiiin.github.io/blog/2371214813/

*/
    
    set_window_title("game")
    set_resolution(WIDTH, HEIGHT)
    set_vsync_enabled(true)
    // set_font_name("gfx/Comfortaa/static/Comfortaa-Bold.ttf")
    // set_font_name("gfx/PT_Mono/PTMono-Regular.ttf")
    // set_font_name("gfx/Scrum.ttf")  // 16
    set_font_name("gfx/Comfortaa/static/Comfortaa-light.ttf")
    set_font_size(24)
    // tmx.RND = random_seed(int(hash(get_clock())))[1]
    // tmx -> parse("map/map.json")  
    // gm <- create_sound("Audio/01. Space - AShamaluev Music.mp3")
    init_audio()
    play_audio("game", 0.5f, true)


[export]
def act(dt: float)


    if appScreen == AppScreen _main_menu
        mainMenu -> update(dt)

    if appScreen == AppScreen _prepare_game || appScreen == AppScreen _game
        if game == null
            game = new Game()
        game -> update(dt)

    if is_shoot_down
        print("EXIT\n")
        unsafe
            delete mainMenu
            delete game
        schedule_quit_game()

[export]
def draw

    if appScreen == AppScreen _main_menu
        mainMenu -> draw()

    if appScreen == AppScreen _prepare_game || appScreen == AppScreen _game
        game -> draw()

    draw_foreground()