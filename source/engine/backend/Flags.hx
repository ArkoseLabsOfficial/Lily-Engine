package engine.backend;

/**
 * Simple Class for keeping some basic path flags.
 * Not recommended to change with HScript, use Source Code instead.
**/
class Flags {
	public static var languageFolder:String = "data/languages/";
	public static var characterFolder:String = "data/characters/";
	public static var dialogFolder:String = "data/dialogues/";
	public static var objectiveFolder:String = "data/objectives/";
	public static var roomFolder:String = "data/rooms/";
	public static var imageFolder:String = "images/";
	public static var fontFolder:String = "fonts/";
	#if FEATURE_TOUCH_CONTROLS
	public static var mobileFolder:String = "mobile";
	#end
	public static var scriptFolder:String = "scripts/";
	public static var ignoredModFolders:Array<String> = ["data", "font", "images", "images", "mobile", "scripts", "sounds"];
	public static var soundFolder:String = "sounds/";

	public static var CANCEL:String = soundFolder + "sfx/ui_navigation2.ogg";
	public static var CONFIRM:String = soundFolder + "sfx/ui_start.ogg";
	public static var NAVIGATE:String = soundFolder + "sfx/ui_navigation.ogg";
	public static var ERROR:String = soundFolder + "sfx/ui_bad.ogg";

	public static var settingsFile:String = "data/settings.xml";
	public static var itemsFile:String = "data/items.xml";
}
