import flixel.FlxG;
import openfl.utils.Assets;
import engine.backend.ui.StateBackend;

importScript("scripts/ScriptA.hx");
class ScriptB extends ScriptA {
	public var test:Int = 1;
	public function run() {
		trace(test);
		ScriptA.helo = "balo";
		trace(ScriptA.helo);
		return malo;
	}
	public function new() {
		trace("a");
	}
}