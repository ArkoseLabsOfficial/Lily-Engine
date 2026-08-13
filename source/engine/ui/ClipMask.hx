package engine.ui;

class ClipMask {
	public var clipX:Float = 0;
	public var clipY:Float = 0;
	public var clipWidth:Float = 0;
	public var clipHeight:Float = 0;

	public function new(x:Float, y:Float, w:Float, h:Float) {
		this.clipX = x;
		this.clipY = y;
		this.clipWidth = w;
		this.clipHeight = h;
	}

	public function apply(group:flixel.group.FlxSpriteGroup):Void {
		if (group == null)
			return;

		var localX = clipX - group.x;
		var localY = clipY - group.y;

		if (group.clipRect == null) {
			group.clipRect = flixel.math.FlxRect.get(localX, localY, clipWidth, clipHeight);
		} else {
			group.clipRect.set(localX, localY, clipWidth, clipHeight);
			group.clipRect = group.clipRect;
		}
	}
}