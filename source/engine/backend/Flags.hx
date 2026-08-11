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
	public static var settingsFile:String = "data/settings.xml";
	public static var itemsFile:String = "data/items.xml";
	public static var ignoredModFolders:Array<String> = ["data", "font", "images", "images", "mobile", "scripts", "sounds"];

	// unused for now, will be implemented with new Assets class in the future.
	public static var selectedMod:String = "";
	public static var imageFolder:String = "images/";
	public static var soundFolder:String = "sounds/";
	public static var fontFolder:String = "fonts/";
	#if FEATURE_TOUCH_CONTROLS
	public static var mobileFolder:String = "mobile/";
	#end
	public static var scriptFolder:String = "scripts/";
}
