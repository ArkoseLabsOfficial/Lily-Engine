package engine.backend.game;

import haxe.Json;
import flixel.util.typeLimit.OneOfTwo;
import Type;

class LanguageManager {
	public var currentLanguage:String = "English";

	private var localePath:String = "languages/";
	private var dictionary:Map<String, String> = new Map();

	public var onLanguageUpdate:Array<Void->Void> = [];
	public var officialLanguages:Array<String> = ["English", "Türkçe"];

	public function new() {}

	public function loadLanguage(lang:String = "English"):Void {
		currentLanguage = lang;
		dictionary.clear();

		var path = localePath + lang + ".json";
		var json = SimpleParser.loadJSON(path);
		if (json == null)
			return;

		if (Reflect.hasField(json, "captions")) {
			flattenJson(Reflect.field(json, "captions"), "");
		}

		if (Reflect.hasField(json, "dialogCaptions")) {
			flattenJson(Reflect.field(json, "dialogCaptions"), "");
		}

		/*
			if (Reflect.hasField(json, "storyCaptions")) {
				var storyCaps = Reflect.field(json, "storyCaptions");
				for (room in Reflect.fields(storyCaps)) {
					var roomObj = Reflect.field(storyCaps, room);
					for (key in Reflect.fields(roomObj)) {
						var flattenedKey = room + "." + key;
						dictionary.set(flattenedKey, Std.string(Reflect.field(roomObj, key)));
					}
				}
			}
		 */

		for (callback in onLanguageUpdate) {
			if (callback != null)
				callback();
		}

		trace(dictionary);
	}

	private function flattenJson(data:Dynamic, prefix:String):Void {
		if (data == null)
			return;

		for (field in Reflect.fields(data)) {
			var value = Reflect.field(data, field);
			var newKey = (prefix == "") ? field : (prefix + "." + field);

			if (Type.typeof(value) == Type.ValueType.TObject) {
				flattenJson(value, newKey);
			} else {
				dictionary.set(newKey, Std.string(value));
			}
		}
	}

	public function getCaption(key:String):String {
		if (dictionary.exists(key))
			return dictionary.get(key);
		return key;
	}

	public function getChildCaption(main:String, key:String):String {
		if (dictionary.exists(key))
			return dictionary.get(key);
		return key;
	}

	public function getDialogCaption(key:String):Array<OneOfTwo<String, Bool>> {
		if (dictionary.exists(key))
			return [dictionary.get(key), true];
		return [key, false];
	}

	public function getUnofficialLanguages():Array<String> {
		var unofficial:Array<String> = [];

		for (mainPath in ["mods/", "assets/"]) {
			if (FileSystem.exists(mainPath + localePath)) {
				var files = FileSystem.readDirectory(mainPath + localePath);
				for (file in files) {
					var langCode = file.split(".")[0];
					if (!officialLanguages.contains(langCode)) {
						unofficial.push(langCode);
					}
				}
				break;
			}
		}
		return unofficial;
	}
}
