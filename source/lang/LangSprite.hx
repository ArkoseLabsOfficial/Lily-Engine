package lang;

import flixel.FlxSprite;

/**
 * A class used for
**/
class LangSprite extends FlxSprite {
	private static var instances:Array<LangSprite> = [];

	private var imageKey:String;

	public function new(x:Float = 0, y:Float = 0, ?key:String) {
		super(x, y);
		instances.push(this);
		if (key != null && key.length > 0) {
			loadLocalizedGraphic(key);
		}
	}

	public function loadLocalizedGraphic(key:String):Void {
		imageKey = key;
		updateGraphic();
	}

	private function updateGraphic():Void {
		if (imageKey == null || imageKey.length == 0)
			return;

		var currentLang = Lang.getCurrentLanguage();
		@:privateAccess
		var localizedPath = '${Lang.languagePath}$currentLang/$imageKey';

		if (Assets.exists(localizedPath)) {
			loadGraphic(localizedPath);
		} else {
			loadGraphic(imageKey);
		}
	}

	public function refresh():Void {
		updateGraphic();
	}

	public static function refreshAll():Void {
		var i:Int = instances.length;
		while (i-- > 0) {
			var instance = instances[i];
			if (instance == null || !instance.exists) {
				instances.splice(i, 1);
			} else {
				instance.refresh();
			}
		}
	}

	override public function destroy():Void {
		instances.remove(this);
		super.destroy();
	}
}
