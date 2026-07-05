package engine.backend;

import mobile.openfl.controls.MobileControls;

class Game {
	public static var instance:Game;

	public var items:ItemManager;
	public var objectives:ObjectiveManager;
	public var language:LanguageManager;
	public var save:SaveManager;

	public static var itemsData(get, never):ItemManager;

	static inline function get_itemsData()
		return instance.items;

	public static var objectivesData(get, never):ObjectiveManager;

	static inline function get_objectivesData()
		return instance.objectives;

	public static var languageData(get, never):LanguageManager;

	static inline function get_languageData()
		return instance.language;

	public static var saveData(get, never):SaveManager;

	static inline function get_saveData()
		return instance.save;

	public static var mobileC(get, never):MobileControls;

	public static function get_mobileC()
		return Main.mobileControls;

	public function new() {
		instance = this;
		language = new LanguageManager();
		items = new ItemManager();
		objectives = new ObjectiveManager();
		save = new SaveManager();

		trace("items loading");
		items.load();
	}

	public function playDialogue(xmlPath:String, startId:String, ?onComplete:Void->Void):Void {
		var dialogue = new DialogueManager(xmlPath, startId, onComplete);
		FlxG.state.openSubState(dialogue);
	}

	public function bindToScript(script:Script):Void {
		script.set("Game", this);
		script.set("Items", this.items);
		script.set("Objectives", this.objectives);
		script.set("Language", this.language);
		script.set("Save", this.save);
		script.set("playDialogue", playDialogue);
	}

	public static function resetState():Void {
		instance = new Game();
	}
}
