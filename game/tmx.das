module TMX
require fio
require daslib/json public
require daslib/json_boost public
include tmxLib/TmxLayers.das
include tmxLib/TmxProperties.das
require tmxLib/TmxSprite public
require tmxLib/TmxAnimationSprite public
require tmxLib/TmxTextureRegion public
require tmxLib/TmxLayer public
require tmxLib/TmxTileSets public
require tmxLib/TmxObject public
require tmxLib/TmxTmpObject public
require tmxLib/TmxObjectLayer public

/*
    layers:
        Foreground2
        Foreground
        Collisions
        Objects
        Background
        
    map properties:
        max_robots_born                 // максимальное число рожденных роботов
        save_child_robots:int           // сколько мелких роботов нужно довести до выхода 
        save_robots:int                 // сколько роботов нужно довести до выхода 

*/

variant LayerType
    layer : TmxLayer?
    object_layer: TmxObjectLayer?



class Tmx

    tmxData:JsonValue?
    layers:array<LayerType>
    tileSets:TmxTileSets?

    tmx_cell_width:float
    tmx_cell_height:float
    tmx_map_width:int
    tmx_map_height:int
    level_task:table<string;int>

    def parse(fname:string)
        clear(layers)
        let f = fopen(fname,"rb")
        let jMap = fread(f)
        fclose(f)
        var error = ""
        tmxData = read_json(jMap,error)
        var obj: table<string;JsonValue?>
        if tmxData != null && tmxData is _object
            obj <- tmxData as _object

            // tmx_cell_width = tmx_float(obj["tilewidth"])
            tmx_cell_width = float(JV(obj["tilewidth"]) as _number)
            tmx_cell_height = tmx_float(obj["tileheight"])
            tmx_map_width = tmx_int(obj["width"])
            tmx_map_height = tmx_int(obj["height"])
            tileSets = new TmxTileSets(tmx_map_width, tmx_map_height, tmx_cell_width, tmx_cell_height)
            tileSets -> parse(obj["tilesets"])
            tmx_layers(obj["layers"])

            if obj |> key_exists("properties")
                for mp in obj["properties"] as _array
                    level_task[(mp as _object)["name"] as _string] = int((mp as _object)["value"] as _number)
        // unsafe
        //     delete j
        //     delete obj

    def private tmx_layers(value:JsonValue?)
        if value != null
            var layer := (value as _array)
            for params in layer
                var obj := params as _object
            // objects layer
                if obj |> key_exists("objects")
                    print("Object properties are not implemented.\n")
                    var ol = new TmxObjectLayer()
                    ol -> parse(obj, tileSets, tmx_cell_width, tmx_cell_height)
                    push(layers, [[LayerType object_layer = ol]])
                    continue
            // tiles layer
                if obj |> key_exists("data")
                    var tl = new TmxLayer()
                    tl -> parse(obj, tileSets, tmx_cell_width, tmx_cell_height)
                    push(layers,[[LayerType layer = tl]])
                    continue
            // unsafe
            //     delete layer

    // //-----------------------------------------------------------------------------------------
    def private tmx_int_array(value:JsonValue?):array<int>
        var int_array : array<int>
        if value is _array
            for i in (value as _array)
                push(int_array,int(i as _number))
        return <- int_array

    def private tmx_int(value:JsonValue?):int
        return int(value as _number)

    def private tmx_float(value:JsonValue?):float
        return float(value as _number)

    def private tmx_string(value:JsonValue?):string
        return value as _string

    //-----------------------------------------------------------------------------------------
    // def draw(debug:bool = false)
    //     enable_alpha_blend()
    //     for l in layers
    //         if l is layer
    //             (l as layer) -> draw()
            // if l is object_layer
            //     (l as object_layer) -> draw()

        // let t = tileSets -> getTextureData(801)
        // draw_image_region(t.texture,16f,16f,t.region)
        // disable_alpha_blend()
        // debugging on top 
        // if debug
        //     for l in layers
        //         if l is object_layer
        //             (l as object_layer) -> debug()

    def update(delta:float)
        for l in layers
            if l is layer
                (l as layer) -> update(delta)
            if l is object_layer
                (l as object_layer) -> update(delta)

    def dispose()
        unsafe
            delete tmxData
    //---------------------------------------------------------------------------------------------

