import godot.nodes.CollisionShape2D;
import lime.math.Vector2;
import flixel.util.FlxColor;

public static function MakeCollisionRect(size:Vector2, offset:Vector2) {
    var shape = new CollisionShape2D();
    shape.nodeName = "CollisionShape";
    shape.shapeType = "RectangleShape2D";
    shape.extents = new Vector2(size.x / 2.0, size.y / 2.0);
    shape.width = size.x;
    shape.height = size.y;
    shape.offset.set(offset.x, offset.y);
    return shape;
}

function MakeCollisionCircle(radius:Float, offset:Vector2) {
    var shape = new CollisionShape2D();
    shape.nodeName = "CollisionShape";
    shape.shapeType = "CircleShape2D";
    shape.radius = radius;
    shape.width = radius * 2.0;
    shape.height = radius * 2.0;
    shape.offset.set(offset.x, offset.y);
    return shape;
}

function MakeCollisionCapsule(size:Vector2, offset:Vector2) {
    var shape = new CollisionShape2D();
    shape.nodeName = "CollisionShape";
    shape.shapeType = "CapsuleShape2D";

    if (size.x > size.y) {
        shape.shapeHeight = (size.x / 2.0 - size.y / 2.0) * 2.0;
        shape.radius = size.y / 2.0;
        shape.angle = 90;
    } else {
        shape.shapeHeight = (size.y / 2.0 - size.x / 2.0) * 2.0;
        shape.radius = size.x / 2.0;
        shape.angle = 0;
    }

    shape.offset.set(offset.x, offset.y);
    return shape;
}

function StringToColor(colorStr:String) {
    if (colorStr == null || colorStr == "") return FlxColor.WHITE;
    if (StringTools.startsWith(colorStr, "#")) return FlxColor.fromString(colorStr);
    if (colorStr.indexOf(",") == -1) return FlxColor.fromString(colorStr);

    var parts = colorStr.split(",");
    var r = Std.int(Std.parseFloat(StringTools.trim(parts[0])) * 255);
    var g = Std.int(Std.parseFloat(StringTools.trim(parts[1])) * 255);
    var b = Std.int(Std.parseFloat(StringTools.trim(parts[2])) * 255);
    var a = parts.length >= 4 ? Std.int(Std.parseFloat(StringTools.trim(parts[3])) * 255) : 255;

    return FlxColor.fromRGB(r, g, b, a);
}

function StringToVector2(str:String) {
    if (str == null || str == "") return new Vector2(0, 0);

    var parts = str.split(",");
    if (parts.length < 2) parts = str.split("x");
    if (parts.length < 2) parts = str.split(" ");

    if (parts.length >= 2)
        return new Vector2(Std.parseFloat(StringTools.trim(parts[0])), Std.parseFloat(StringTools.trim(parts[1])));

    return new Vector2(0, 0);
}
