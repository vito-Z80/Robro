require TmxProperties

struct TmxTmpObject
    bounds:float4
    tile_id, id:int
    object_type, name:string
    rotation:float
    visible:bool
    properties:TmxProperties? = null
