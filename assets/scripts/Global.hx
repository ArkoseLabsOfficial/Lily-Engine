import engine.backend.Game;

/**
 * Class Not Important But Allows to Import. 
**/
class Global {
	public static var test:String = "hello";
	public static var curRoom:String = null;
	public static var targetSpawn:String = "";

	function gameResized(w, h) {}

	public static function openDialog(dialog, start, onComplete) {
		Game.instance.playDialogue(dialog, start, onComplete);
	}

	function onOptionLoaded(variable, value) {
		switch (variable) {
			case "framerate":
				FlxG.drawFramerate = value;
		}
	}
}
