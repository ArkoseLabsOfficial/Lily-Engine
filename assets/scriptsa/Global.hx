import engine.backend.Game;

/**
 * Class Not Important But Allows to Import. 
**/
class Global {
	function gameResized(w, h) {}

	function onOptionLoaded(variable, value) {
		switch (variable) {
			case "framerate":
				FlxG.drawFramerate = value;
				FlxG.updateFramerate = value;
		}
	}
}
