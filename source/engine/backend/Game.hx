package engine.backend;

#if FEATURE_TOUCH_CONTROLS
import mobile.openfl.controls.MobileControls;
#end

class Game {
	public static var instance:Game;
	public static var paused(get, default):Bool = false;

	static inline function get_paused() {
		return instance._paused;
	}

	public static var items(get, never):ItemManager;
	public static var objectives(get, never):ObjectiveManager;
	public static var language:Lang;
	public static var save(get, never):SaveManager;
	public static var room(get, never):RoomManager;
	public static var player(get, never):Player;

	static inline function get_items()
		return instance._items;

	static inline function get_objectives()
		return instance._objectives;

	static inline function get_save()
		return instance._save;

	static inline function get_room()
		return RoomManager.instance;

	static inline function get_player()
		return room != null ? room.player : null;

	public var _paused:Bool = false;
	public var _items:ItemManager;
	public var _objectives:ObjectiveManager;
	public var _save:SaveManager;

	#if FEATURE_TOUCH_CONTROLS
	public static var mobileC(get, never):MobileControls;

	public static function get_mobileC()
		return Main.mobileControls;
	#end

	public function init() {
		_items = new ItemManager();
		_objectives = new ObjectiveManager();
		_save = new SaveManager();
		_items.load();
	}

	public function new() {
		instance = this;
	}

	public static function playDialogue(jsonPath:String, startId:String, ?onComplete:Void->Void):Void {
		var dialogue = new DialogueManager(jsonPath, startId, onComplete);
		FlxG.state.openSubState(dialogue);
	}

	public function bindToScript(script:Dynamic):Void {
		if (script == null)
			return;

		script.set("setCameraTarget", function(id:String) {
			if (room == null)
				return;
			var target:FlxObject = null;
			if (id == "player")
				target = player;
			else if (room.currentScene != null) {
				var node:Dynamic = room.currentScene.getNode(id);
				if (Std.isOfType(node, FlxObject))
					target = cast node;
			}
			if (target != null)
				BaseRoom.instance.followTheObject(target, "NO_DEAD_ZONE", 1);
		});
	}

	public static function resetState():Void {
		instance = new Game();
	}
}
