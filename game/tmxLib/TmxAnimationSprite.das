require dasbox
require daslib/media
require TmxSprite

class TmxAnimationSprite:TmxSprite
    textures:array<ImageHandle>
    regions:array<float4>
    durations:array<int>
    private frame:int = 0
    private dur:float = 0f

    def override update(delta:float):void
        dur += delta * 1000f
        if !empty(durations) && int(dur) >= durations[frame]
            dur = 0f
            frame++
            if frame >= length(durations) 
                frame = 0
            region.x = regions[frame].x
            region.y = regions[frame].y
            region.w = regions[frame].w
            region.z = regions[frame].z
            texture = textures[frame]

    def override draw()
        return


    def set_start_frame(frame_id:int):void
        frame = frame_id