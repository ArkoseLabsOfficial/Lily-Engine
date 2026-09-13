/**
 * Class Not Important But Allows to Import. 
**/
import openfl.Lib;
class Global {
	function gameResized(w, h) {}

	function onOptionLoaded(variable, value) {
		switch (variable) {
			case "framerate":
				FlxG.drawFramerate = value;
				FlxG.updateFramerate = value >= 60 ? value : 60;
		}
	}
}