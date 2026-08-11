package engine.ui;

import lang.LangText;

class MenuVisualEntry extends FlxSpriteGroup {
	public var bg:FlxSprite;
	public var label:LangText;

	private static inline var SELECT_COLOR:FlxColor = 0x33EDDEDE;

	public function new(X:Float, Y:Float, textKey:String, width:Float, height:Float, fontSize:Int = 48, align:FlxTextAlign = CENTER) {
		super(X, Y);

		bg = new FlxSprite(0, 0);
		bg.makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT);
		add(bg);

		label = new LangText(0, 0, width, textKey, null, fontSize);
		label.alignment = align;
		add(label);

		label.y = this.y + (height - label.height) / 2;
	}

	public function setHighlight(isActive:Bool):Void {
		bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), isActive ? SELECT_COLOR : FlxColor.TRANSPARENT);
	}
}
