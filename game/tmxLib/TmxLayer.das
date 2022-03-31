require daslib/media
require TmxSprite
require TmxLayers
require TmxTileSets
require TmxAnimationSprite
require daslib/json
require daslib/json_boost
require TmxTextureRegion

class TmxLayer:TmxLayers

    width,height:int = 0
    data:array<int>
    tiles:array<TmxSprite?>
    tmx_cell_width, tmx_cell_height:float

    def parse(var obj:table<string;json::JsonValue?>; var tileSets:TmxTileSets?; cell_width:float; cell_height: float)
        tmx_layer_base_param(obj)
        tmx_cell_width = cell_width
        tmx_cell_height = cell_height
        width = tmx_int(obj["width"])
        height = tmx_int(obj["height"])
        data <- tmx_int_array(obj["data"])

        for index in range(length(data))
            if data[index] > 0
                var spr:TmxSprite? = tileSets -> getSprite(data[index], index, true)
                push(tiles, spr)
            else
                push(tiles, null)


    def override draw()
        for t in tiles
            if t != null && visible
                draw_image_region(t.texture, t.bounds.x, t.bounds.y, t.region)

    def override update(delta:float)
        for t in tiles
            if t != null && visible
                t -> update(delta)
