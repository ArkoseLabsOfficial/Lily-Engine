package mobile;

import mobile.ControlsData;

class Config {
	public static var DPAD_PATH:String = 'assets/${Flags.mobileFolder}/DPad/images/';
	public static var BUTTON_PATH:String = 'assets/${Flags.mobileFolder}/Button/images/';
	public static var JOYSTICK_PATH:String = 'assets/${Flags.mobileFolder}/JoyStick/images/';

	public static var DPAD_JSON:String = 'assets/${Flags.mobileFolder}/DPad/';
	public static var BUTTON_JSON:String = 'assets/${Flags.mobileFolder}/Button/';
	public static var JOYSTICK_JSON:String = 'assets/${Flags.mobileFolder}/JoyStick/';
	public static var HITBOX_JSON:String = 'assets/${Flags.mobileFolder}/Hitbox/';

	public static var MODDED_DPAD_PATH:String = "";
	public static var MODDED_BUTTON_PATH:String = "";
	public static var MODDED_JOYSTICK_PATH:String = "";

	public static var MODDED_DPAD_JSON:String = "";
	public static var MODDED_BUTTON_JSON:String = "";
	public static var MODDED_JOYSTICK_JSON:String = "";
	public static var MODDED_HITBOX_JSON:String = "";

	public static var Buttons:Map<String, ControlsJsonDef> = new Map();
	public static var DPads:Map<String, ControlsJsonDef> = new Map();
	public static var JoySticks:Map<String, ControlsJsonDef> = new Map();
	public static var Hitboxes:Map<String, ControlsJsonDef> = new Map();

	public static function init() {
		Buttons.clear();
		DPads.clear();
		JoySticks.clear();
		Hitboxes.clear();

		loadIntoMap(BUTTON_JSON, Buttons);
		loadIntoMap(MODDED_BUTTON_JSON, Buttons);

		loadIntoMap(DPAD_JSON, DPads);
		loadIntoMap(MODDED_DPAD_JSON, DPads);

		loadIntoMap(JOYSTICK_JSON, JoySticks);
		loadIntoMap(MODDED_JOYSTICK_JSON, JoySticks);

		loadIntoMap(HITBOX_JSON, Hitboxes);
		loadIntoMap(MODDED_HITBOX_JSON, Hitboxes);
	}

	private static function loadIntoMap(path:String, map:Map<String, ControlsJsonDef>) {
		if (path != null && path != "" && FileSystem.exists(path) && FileSystem.isDirectory(path)) {
			var files = FileSystem.readDirectory(path);
			trace(files);
			for (i in 0...files.length) {
				var file = files[i];
				if (file.length > 5 && file.substr(-5) == ".json") {
					var name = file.substr(0, file.length - 5);
					var content = File.getContent(path + file);
					if (content != null) {
						try {
							var parsed:ControlsJsonDef = Json.parse(content);
							map.set(name, parsed);
						} catch (e:Dynamic) {
							trace(e);
						}
					}
				}
			}
		}
	}
}
