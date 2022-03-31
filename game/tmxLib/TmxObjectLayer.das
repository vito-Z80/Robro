require TmxLayers
require TmxObject
require TmxTmpObject
require daslib/json
require daslib/json_boost
require daslib/media
require TmxProperties
require TmxTileSets

class TmxObjectLayer:TmxLayers

/*


*/
    debug_color:uint = 0xffff0000
    debug_collision_size : float2
    draworder : string
    id_debug:bool = false
    objects:array<TmxObject?>
    objectsTmp:array<TmxTmpObject>
    // objectIndices:array<int>
    objectsData:array<json::JsonValue?>
    tmx_cell_width, tmx_cell_height:float

    def parse(var obj:table<string;json::JsonValue?>; var tileSets:TmxTileSets?; cell_width:float; cell_height: float)
        tmx_cell_width = cell_width
        tmx_cell_height = cell_height
        tmx_layer_base_param(obj)
        objectsData <- obj["objects"] as _array
        for o in objectsData
            var o_data <- o as _object
            let GID = o_data |> key_exists("gid") ? int(o_data["gid"] as _number) : -1
            let o_x = float(o_data["x"] as _number)
            let o_w = float(o_data["width"] as _number)
            let o_z = float(o_data["height"] as _number)
            let o_y = float(o_data["y"] as _number)
            var prop:TmxProperties? = null
            if o_data |> key_exists("properties")
                prop = new TmxProperties
                prop.prop = o_data["properties"]
            push(objectsTmp, [[TmxTmpObject
                tile_id = GID,
                name = o_data["name"] as _string,
                object_type = tmx_string(o_data["type"]),
                id = int(o_data["id"] as _number),
                visible = o_data["visible"] as _bool,
                // смещение X,Y для отрисовки через трансформ (для игровых объектов), для коллизий горизонтальных линий без смещения
                // коллизии прямоугольники под вопросом.
                bounds = GID >= 0 ? float4(o_x + o_w / 2f, o_y - o_z / 2f ,o_w, o_z) : float4(o_x, o_y ,o_w, o_z),
                properties = prop
            ]])
            // print("{GID}| oY: {float(o_data["y"] as _number)} oZ: {o_z} oX: {o_x}\n")
        // for i in objectsTmp
        //     print("Properpties: {i.properties   }\n")


            // var gid = o_data |> key_exists("gid") ? tmx_int(o_data["gid"]) : -1
            // var user_obj = tileSets -> getObject(gid, true)
            // push(objectIndices, gid)
            // user_obj.gid = gid
            // user_obj.tile_id = gid
            // user_obj.name = o_data["name"] as _string
            // user_obj.object_type = tmx_string(o_data["type"])
            // user_obj.id = tmx_int(o_data["id"])
            // user_obj.visible = o_data["visible"] as _bool
            // user_obj.point = o_data |> key_exists("point") ? 1 : -1
            // user_obj.bounds.x = tmx_float(o_data["x"])
            // user_obj.bounds.w = tmx_float(o_data["width"])
            // user_obj.bounds.z = tmx_float(o_data["height"])
            // if gid >= 0
            //     user_obj.bounds.y = tmx_float(o_data["y"]) - user_obj.bounds.z
            // else
            //     user_obj.bounds.y = tmx_float(o_data["y"])

            // user_obj.properties = o_data |> key_exists("properties") ? new TmxProperties(o_data["properties"] as _array) : null

            // push(objects, user_obj)

//------------------------------------------------------------------------------------------------
    def override draw():void
        return
        for t in objects
            if t != null && visible
                draw_image_region(t.texture, t.bounds.x, t.bounds.y, t.region)


    def override debug()
        return
        for t in objects
            if t != null && visible
                if t.bounds.w == 0f || t.bounds.z == 0f
                //  x 16, y 208, w 96, z 0
                //  x 16, y 208, w 112, z 208
                    debug_collision_size.y = t.bounds.z == 0f ? t.bounds.y : t.bounds.y + t.bounds.z
                    debug_collision_size.x = t.bounds.w == 0f ? t.bounds.x : t.bounds.x + t.bounds.w
                    line(t.bounds.x, t.bounds.y, debug_collision_size.x, debug_collision_size.y, debug_color)
                else
                    rect(t.bounds.x, t.bounds.y, t.bounds.w, t.bounds.z, debug_color)


    def override update(delta:float)
        for o in objects
            if o != null && visible
                o -> update(delta) 