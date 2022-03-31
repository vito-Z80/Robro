require daslib/json
require daslib/json_boost
class TmxLayers

    x, y:float
    name, layer_type:string
    visible:bool
    id,opacity:int
    is_object_layer:bool = false

    def draw():void
        return

    def update(delta:float):void
        return

    def debug():void
        return


    // def private setRegion(cell:int; texture_size:int2; tile_size:int2;var bounds:float4&)
    //     bounds.y = float(cell / texture_size.x * tile_size.y)
    //     bounds.x = float((cell - cell / texture_size.x * texture_size.x)*tile_size.x) 
    //     bounds.w = float(tile_size.x)
    //     bounds.z = float(tile_size.y)

    def tmx_layer_base_param(var obj:table<string;json::JsonValue?>):void
        x = tmx_float(obj["x"])
        y = tmx_float(obj["y"])
        id = tmx_int(obj["id"])
        opacity = tmx_int(obj["opacity"])
        name = tmx_string(obj["name"])
        visible = obj["visible"] as _bool
        layer_type = tmx_string(obj["type"])


    def tmx_int_array(value:JsonValue?):array<int>
        var int_array : array<int>
        if value is _array
            for i in (value as _array)
                push(int_array,int(i as _number))
        return <- int_array

    def tmx_int(value:JsonValue?):int
        return int(value as _number)

    def tmx_float(value:JsonValue?):float
        return float(value as _number)

    def tmx_string(value:JsonValue?):string
        return value as _string