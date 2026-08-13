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

	public static var items(get, never):Items;
	public static var objectives(get, never):Objectives;
	public static var language:Lang;
	public static var save(get, never):SaveManager;
	public static var room(get, never):Room;
	public static var baseRoom(get, never):BaseRoom;
	public static var party(get, set):Array<Character>;

	static inline function get_items()
		return instance._items;

	static inline function get_objectives()
		return instance._objectives;

	static inline function get_save()
		return instance._save;

	static inline function get_room()
		return Room.instance;

	static inline function get_baseRoom()
		return BaseRoom.instance;

	static inline function get_party()
		return baseRoom.party;

	static inline function set_party(value:Array<Character>):Array<Character>
		return baseRoom.party = value;

	public var _paused:Bool = false;
	public var _items:Items;
	public var _objectives:Objectives;
	public var _save:SaveManager;

	#if FEATURE_TOUCH_CONTROLS
	public static var mobileC(get, never):MobileControls;

	public static function get_mobileC()
		return Main.mobileControls;
	#end

	public function init() {
		_items = new Items();
		_objectives = new Objectives();
		_save = new SaveManager();
		_items.load();
	}

	public function new() {
		instance = this;
	}
}
