extends SceneTree
## Native Image decode/composite only; not GUI or production resolver acceptance.
func _initialize() -> void:
    call_deferred("_run")

func _load(path: String) -> Image:
    var image := Image.new()
    assert(image.load(path) == OK, path)
    assert(image.get_size() == Vector2i(1024,1536), path)
    image.convert(Image.FORMAT_RGBA8)
    return image

func _run() -> void:
    var root := OS.get_environment("OUTFIT_QA_ROOT")
    var output := OS.get_environment("OUTFIT_QA_OUTPUT")
    var base := _load(root+"/sprite_study/assets/characters/foundation.png")
    var mask := _load(root+"/company_loop/outfits/characters/foundation_keep_mask.png")
    var kept := base.duplicate() as Image
    for y in range(1536):
        for x in range(1024):
            var color := kept.get_pixel(x,y)
            color.a *= mask.get_pixel(x,y).a
            kept.set_pixel(x,y,color)
    for family in ["quilt","mail","brigandine"]:
        var outfit := _load(root+"/company_loop/outfits/characters/outfit_"+family+".png")
        var upper := _load(root+"/sprite_study/assets/characters/body_"+family+".png")
        assert(outfit.get_region(Rect2i(0,0,1024,700)).get_data() == upper.get_region(Rect2i(0,0,1024,700)).get_data())
        var image := kept.duplicate() as Image
        image.blend_rect(outfit,Rect2i(0,0,1024,1536),Vector2i.ZERO)
        assert(image.save_png(output+"/native-"+family+".png") == OK)
        print("NATIVE_OUTFIT_IMAGE_OK ",family," 1024x1536; upper exact; common alpha mask applied")
    print("OUTFIT_NATIVE_IMAGE_PASS: source image math only; no GUI/resolver/GPU claim")
    quit(0)
