package lang;

import haxe.Json;
import haxe.ds.StringMap;

/**
 * Main language/translation system
 */
class Lang {
	private static var currentLanguage:String = "en";
	private static var defaultLanguage:String = "en";
	private static var translations:StringMap<Dynamic> = new StringMap<Dynamic>();
	private static var languagePath:String = "data/language/";
	private static var initialized:Bool = false;

	/**
	 * Initialize the language system
	 * @param defLang Default language code
	 * @param path Path to language files (optional)
	 */
	public static function init(defLang:String = "en", ?path:String):Void {
		defaultLanguage = defLang;
		currentLanguage = defLang;

		if (path != null) {
			languagePath = path;
			if (!languagePath.endsWith("/")) {
				languagePath += "/";
			}
		}

		loadLanguage(defaultLanguage);
		initialized = true;
	}

	/**
	 * Set/change current language
	 * @param lang Language code to switch to
	 * @return True if successful, false if language not found
	 */
	public static function setLanguage(lang:String):Bool {
		if (lang == currentLanguage) {
			return true;
		}

		if (loadLanguage(lang)) {
			currentLanguage = lang;
			return true;
		}

		return false;
	}

	/**
	 * Get a translated string
	 * @param key Translation key (supports dot notation: "category.subcategory.key")
	 * @param vars Optional variables for interpolation
	 * @return Translated string or key if not found
	 */
	public static function get(key:String, ?vars:Array<Dynamic>):String {
		if (!initialized) {
			trace("Lang system not initialized! Call Lang.init() first.");
			return key;
		}

		var result:String = getFromPath(key);

		if (vars != null && vars.length > 0) {
			for (i in 0...vars.length) {
				result = StringTools.replace(result, '{$i}', Std.string(vars[i]));
			}
		}

		return result;
	}

	/**
	 * Check if a translation key exists
	 * @param key Translation key to check
	 * @return True if exists
	 */
	public static function exists(key:String):Bool {
		for (lang in [currentLanguage, defaultLanguage]) {
			var current:Dynamic = translations.get(lang);
			if (current == null)
				continue;

			if (Reflect.hasField(current, key)) {
				return true;
			}

			var parts:Array<String> = key.split(".");
			for (i in 1...parts.length) {
				var rootKey = parts.slice(0, i).join(".");
				var subKey = parts.slice(i).join(".");

				if (Reflect.hasField(current, rootKey)) {
					var subObj = Reflect.field(current, rootKey);
					if (subObj != null && (Std.isOfType(subObj, String) == false)) {
						if (Reflect.hasField(subObj, subKey)) {
							return true;
						}
					}
				}
			}

			var temp:Dynamic = current;
			var found:Bool = true;
			for (part in parts) {
				if (Reflect.hasField(temp, part)) {
					temp = Reflect.field(temp, part);
				} else {
					found = false;
					break;
				}
			}
			if (found)
				return true;
		}

		return false;
	}

	/**
	 * Get current language code
	 * @return Current language code
	 */
	public static function getCurrentLanguage():String {
		return currentLanguage;
	}

	/**
	 * Get default language code
	 * @return Default language code
	 */
	public static function getDefaultLanguage():String {
		return defaultLanguage;
	}

	/**
	 * Get list of available languages
	 * @return Array of language codes
	 */
	public static function getAvailableLanguages():Array<String> {
		var languages:Array<String> = [];

		trace(languagePath);
		if (Assets.exists(languagePath) && Assets.isDirectory(languagePath)) {
			trace(languagePath);
			for (file in Assets.readDirectory(languagePath)) {
				trace(file);
				if (file.endsWith(".json")) {
					languages.push(file.substring(0, file.length - 5));
				}
			}
		}

		return languages;
	}

	/**
	 * Reload all language files (useful for development)
	 */
	public static function reload():Void {
		translations.clear();
		loadLanguage(currentLanguage);
	}

	// Private methods
	private static function loadLanguage(lang:String):Bool {
		var filePath:String = languagePath + lang + ".json";

		try {
			var content:String = null;

			if (Assets.exists(filePath)) {
				content = Assets.getText(filePath);
			}

			if (content != null) {
				var data:Dynamic = Json.parse(content);
				translations.set(lang, data);
				return true;
			}
		} catch (e:Dynamic) {
			trace('Error loading language file: $filePath - $e');
		}

		return false;
	}

	private static function getFromPath(key:String):String {
		for (lang in [currentLanguage, defaultLanguage]) {
			var current:Dynamic = translations.get(lang);
			if (current == null)
				continue;

			if (Reflect.hasField(current, key)) {
				var val = Reflect.field(current, key);
				if (Std.isOfType(val, String)) {
					return cast val;
				}
			}

			var parts:Array<String> = key.split(".");

			for (i in 1...parts.length) {
				var rootKey = parts.slice(0, i).join(".");
				var subKey = parts.slice(i).join(".");

				if (Reflect.hasField(current, rootKey)) {
					var subObj = Reflect.field(current, rootKey);
					if (subObj != null && !Std.isOfType(subObj, String)) {
						if (Reflect.hasField(subObj, subKey)) {
							var val = Reflect.field(subObj, subKey);
							if (Std.isOfType(val, String)) {
								return cast val;
							}
						}
					}
				}
			}

			var temp:Dynamic = current;
			var found:Bool = true;
			for (part in parts) {
				if (Reflect.hasField(temp, part)) {
					temp = Reflect.field(temp, part);
				} else {
					found = false;
					break;
				}
			}

			if (found && Std.isOfType(temp, String)) {
				return cast temp;
			}
		}

		trace('Translation not found: $key');
		return key;
	}
}
