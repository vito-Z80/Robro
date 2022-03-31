require daslib/media
require daslib/json
require daslib/json_boost
require dasbox_graphics_utils
require TmxAnimationSprite
require TmxSprite
require TmxObject
require TmxProperties


/*
    Требования:
        получить текстуру/регион по индексу с карты
        определять по индексу анимированные тайлы + получать все индексы анимации тайла



*/

// variant TileType
//     _sprite : TmxSprite?
//     _animation_sprite : TmxAnimationSprite?
//     _object_sprite : TmxObject?

struct TmxTileSetData
    firstGid, tileCount, columns:int
    imageWidth, imageHeight, margin, spacing, tileWidth, tileHeight:float
    imagePath, name:string

struct TmxTextureData
    texture_data:tuple<texture:ImageHandle; region:float4>
    tile_set_data:TmxTileSetData


class TmxTileSets

    map_width, map_height: int 
    map_cell_width, map_cell_height: float
    textures:table<int;TmxTextureData>
    animationTiles:table<int;array<int>>
    animationProperties:table<int;TmxProperties?>

    def TmxTileSets(MAP_WIDTH:int; MAP_HEIGHT:int; MAP_CELL_WIDTH:float; MAP_CELL_HEIGHT:float)
        map_width = MAP_WIDTH
        map_height = MAP_HEIGHT
        map_cell_width = MAP_CELL_WIDTH
        map_cell_height = MAP_CELL_WIDTH

    def getTextureData(id:int)//:table<int;TmxTextureData>
        return textures[id].texture_data

    def getSprite(id, cell_id:int; animation_if_possible:bool):TmxSprite?
        if animation_if_possible && animationTiles |> key_exists(id)
            var a_spr = new TmxAnimationSprite()
            var r = textures[id]
            a_spr.texture = r.texture_data.texture
            a_spr.region = r.texture_data.region
            let s_y = float(cell_id / map_width) * map_cell_height - r.texture_data.region[3] + map_cell_height
            let s_x = float(cell_id % map_height) * map_cell_width
            a_spr.bounds = float4(s_x, s_y, r.texture_data.region[2], r.texture_data.region[3])
            var index = 0
            while (index < length(animationTiles[id]))
                push(a_spr.textures, textures[animationTiles[id][index]].texture_data.texture)
                push(a_spr.regions, textures[animationTiles[id][index++]].texture_data.region)
                push(a_spr.durations, animationTiles[id][index++])
            return a_spr
        if textures |> key_exists(id)
            var r = textures[id]
            // let s_y = float(cell_id / map_width) * map_cell_height - r.texture_data.region.z + map_cell_height
            let s_y = float(cell_id / map_width) * map_cell_height - r.texture_data.region[3] + map_cell_height
            let s_x = float(cell_id % map_height) * map_cell_width
            var s = new TmxSprite()
            s.region = r.texture_data.region
            s.texture = r.texture_data.texture
            s.bounds = float4(s_x, s_y, r.texture_data.region[2], r.texture_data.region[3])
            return s
        return null


    // def getObject(id : int; animation_if_possible:bool)
    //     var obj = new TmxObject()
    //     var r = textures[id]
    //     if animation_if_possible && animationTiles |> key_exists(id)
    //         print("{id}\n")
    //         var index = 0
    //         while (index < length(animationTiles[id]))
    //             push(obj.textures, textures[animationTiles[id][index]].texture_data.texture)
    //             push(obj.regions, textures[animationTiles[id][index++]].texture_data.region)
    //             push(obj.durations, animationTiles[id][index++])
    //         // for o in obj.textures
    //         //     print("{o}\n")
    //         // print("-----------\n")
    //     if textures |> key_exists(id)
    //         obj.region = r.texture_data.region
    //         obj.texture = r.texture_data.texture
    //     return obj
            
    //---------------------------------------------------------------------------------
    def parse(value:JsonValue?)
        if value != null
            let image_path = "gfx/"     // TODO need file normalize
            var res := (value as _array)
            for i in res
                if i is _object
                    var obj := i as _object
                    var tile_set_data = set_data(obj)                    
                    if !obj |> key_exists("image")
                        individual(obj, tile_set_data, image_path)
                        continue
                    else
                        atlas(obj, tile_set_data, image_path)
                        continue


        // print("{length(animationTiles)}\n")
        // for k, v in keys(animationTiles),values(animationTiles)
        //     print("{k} : {v}\n------------------------------\n")

    def individual(var obj:table<string;json::JsonValue?>; var d:TmxTileSetData; image_path:string)
        if obj["tiles"] is _array
            var o <- obj["tiles"] as _array
            for t in o
                if t is _object
                    var tile <- t as _object
                    let tile_id = int(tile["id"] as _number) + d.firstGid
                    d.imageWidth = float(tile["imagewidth"] as _number)
                    d.imageHeight = float(tile["imageheight"] as _number)
                    let i_name <- split(tile["image"].value as _string, "/") |> back() |> split(".")
                    let indi_texture <- create_managed_image("{image_path}{i_name[0]}.{i_name[1]}")
                    var td:tuple<texture:ImageHandle; region:float4>
                    td.texture = indi_texture
                    td.region = float4(0f, 0f, d.imageWidth, d.imageHeight)
                    textures[tile_id] = [[TmxTextureData
                        texture_data = td,
                        tile_set_data = d
                    ]]
                    // индексы анимированных тайлов текстур
                    if tile |> key_exists("animation")
                        for a_t in tile["animation"] as _array
                            let tileId = int((a_t as _object)["tileid"] as _number)
                            let duration = int((a_t as _object)["duration"] as _number)
                            push(animationTiles[tile_id], tileId + d.firstGid)
                            push(animationTiles[tile_id], duration)
            

    def private atlas(var obj:table<string;json::JsonValue?>; var d:TmxTileSetData; var image_path:string)
        d.imageWidth = float(obj["imagewidth"].value as _number)    
        d.imageHeight = float(obj["imageheight"].value as _number)
        let t_width = d.tileWidth
        let t_height = d.tileHeight
        let width = d.imageWidth / t_width
        let height = d.imageHeight / t_height
        let extension <- split((obj["image"].value as _string),".")
        let exe = extension[extension |> length - 1]
        let t <- create_managed_image("{image_path}{(obj["name"].value as _string)}.{exe}")   // TODO путь нужно брать из JSON файла
        // считывание всех регионов с текстурного атласа (даже пустых и повторяющихся) 
        var count = 0
        for row in range(height)
            for column in range(width)
                let reg = float4(float(column) * t_width,float(row) * t_height,t_width,t_height)
                var td:tuple<texture:ImageHandle; region:float4>
                td.texture = t
                td.region = reg
                textures[count + d.firstGid] = [[TmxTextureData
                    texture_data = td,
                    tile_set_data = d
                ]]
                count++
        // индексы всех анимированных тайлов текущего текстурного атласа
        if obj |> key_exists("tiles")
            for tile in obj["tiles"] as _array
                if tile as _object |> key_exists("animation")
                    var tile_id = int(tile as _object["id"] as _number) + d.firstGid
                    for anim_tiles in (tile as _object)["animation"] as _array
                        let tileId = int((anim_tiles as _object)["tileid"] as _number)
                        let duration = int((anim_tiles as _object)["duration"] as _number)
                        push(animationTiles[tile_id], tileId + d.firstGid)
                        push(animationTiles[tile_id], duration)

                    // хар-ки пока не доступны (некогда)
                    var p:TmxProperties? = null
                    if tile as _object |> key_exists("properties")
                        p = new TmxProperties
                        p.prop = (tile as _object)["properties"]
                    animationProperties[tile_id] <- p

    def private set_data(var obj:table<string;json::JsonValue?>&)
        return [[TmxTileSetData
            tileWidth = float(obj["tilewidth"].value as _number),
            tileHeight = float(obj["tileheight"].value as _number),
            margin = float(obj["margin"].value as _number),
            spacing = float(obj["spacing"].value as _number),
            firstGid = int(obj["firstgid"].value as _number),
            tileCount = int(obj["tilecount"].value as _number),
            columns = int(obj["columns"].value as _number),
            name = (obj["name"].value as _string)
        ]]
