package engine.scripting;

#if FEATURE_HSCRIPT
import haxe.io.Path;
import openfl.utils.Assets;
import flixel.FlxG;
import flixel.FlxBasic;
import hscript.Expr.Error;
import hscript.SScript;
import hscript.Interp;
import hscript.Expr;
import hscript.CustomClass;
import hscript.CustomClassHandler;
import lime.app.Application;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxStringUtil;
import engine.scripting.events.CancellableEvent;
import hscript.IHScriptCustomAccessBehaviour;
import debug.DebugMenu;

using StringTools;

/**
 * HScript implementation using class-oriented syntax mapping.
 */
class HScript extends Script {
	public var sscript:SScript;
	public var code:String = null;
	public var baseName:String;
	public var instance(get, set):Dynamic;

	private function get_instance():Dynamic {
		return sscript.instance;
	}

	private function set_instance(value:SScript):Dynamic {
		sscript.instance = value;
		return value;
	}

	public override function onCreate(path:String) {
		super.onCreate(path);

		sscript = new SScript("", true, false);
		sscript.parser.allowJSON = true;
		sscript.parser.preprocessorValues = Script.getDefaultPreprocessors();

		if (path != null) {
			try {
				if (Assets.exists(rawPath))
					code = Assets.getText(rawPath);
			} catch (e) {
				FlxG.stage.window.alert('Error while reading $path: ${Std.string(e)}', "HScript");
			}
		}

		sscript.interp.errorHandler = _errorHandler;
		sscript.interp.warnHandler = _warnHandler;

		/* get name from File. */
		var cleaned = sourcePath.replace('${Flags.scriptFolder}/', '').split('/').pop();
		var lastDot = cleaned.lastIndexOf(".");
		baseName = lastDot != -1 ? cleaned.substring(0, lastDot) : cleaned;
		// sscript.baseName = baseName;

		var statics:Map<String, Dynamic> = HScript.classStatics.get(baseName);
		if (statics == null) {
			statics = [];
			HScript.classStatics.set(baseName, statics);
		}

		sscript.interp.staticVariables = statics;
		sscript.interp.publicVariables = [];
		sscript.interp.allowStaticVariables = true;
		sscript.interp.allowPublicVariables = true;

		sscript.interp.variables.set("importScript", function(path:String) {
			var importedScript:Script = Script.create('scripts/$path.hx');
			if (importedScript != null && !(importedScript is DummyScript)) {
				var hscriptInstance:HScript = Std.isOfType(importedScript, HScript) ? cast importedScript : null;
				if (hscriptInstance != null && hscriptInstance.sscript != null && hscriptInstance.sscript.interp != null) {
					if (hscriptInstance.code != null && hscriptInstance.code.trim() != "") {
						hscriptInstance.sscript.parser.allowJSON = true;
						hscriptInstance.sscript.parser.preprocessorValues = Script.getDefaultPreprocessors();

						for (k => e in Script.getDefaultVariables(hscriptInstance)) {
							hscriptInstance.sscript.set(k, e);
						}

						var expr = hscriptInstance.sscript.parser.parseString(hscriptInstance.code, hscriptInstance.fileName);
						hscriptInstance.sscript.interp.execute(expr);
						HScript.syncCustomClassStatics(hscriptInstance.sscript.interp);
					}

					for (k => v in hscriptInstance.sscript.interp.customClasses) {
						for (varKey => varVal in sscript.interp.variables) {
							try {
								@:privateAccess {
									if (v.__interp != null && v.__interp.variables != null) {
										v.__interp.variables.set(varKey, varVal);
									}
								}
							} catch (e:Dynamic) {}
						}

						sscript.interp.customClasses.set(k, v);
					}
					for (k => v in hscriptInstance.sscript.interp.variables) {
						if (!sscript.interp.variables.exists(k)) {
							sscript.interp.variables.set(k, v);
						}
					}
				}
			} else {
				_trace("WARN: importScript failed to find or load: " + 'scripts/$path.hx');
			}
		});

		#if GLOBAL_SCRIPT
		engine.scripting.GlobalScript.call("onScriptCreated", [this, "hscript"]);
		#end

		loadFromString(code);
	}

	public override function loadFromString(code:String) {
		this.code = code;
		return this;
	}

	private function _formatError(error:Error):String {
		var fileName = error.origin;
		if (remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);

		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		var oldfn = '${error.origin}:${error.line}: ';

		while (err.startsWith(oldfn) || err.startsWith(fn)) {
			if (err.startsWith(oldfn))
				err = err.substr(oldfn.length);
			if (err.startsWith(fn))
				err = err.substr(fn.length);
		}
		return fn + err;
	}

	private function _errorHandler(error:Error) {
		DebugMenu.addTextToDebug("ERROR:" + _formatError(error), FlxColor.RED);
		_trace("ERROR Caused in " + _formatError(error));
	}

	private function _warnHandler(error:Error) {
		DebugMenu.addTextToDebug("WARN:" + _formatError(error), FlxColor.ORANGE);
		_trace("WARN Caused in " + _formatError(error));
	}

	public override function setParent(parent:Dynamic) {
		if (sscript != null) {
			var hasCustomClassInstance = false;
			if (sscript.instance != null && sscript.instance != {}) {
				if (Std.isOfType(sscript.instance, CustomClass)) {
					hasCustomClassInstance = true;
					try {
						var cc = cast(sscript.instance, CustomClass);
						@:privateAccess
						if (cc.__superClass == null) {
							hasCustomClassInstance = false;
						}
					} catch (e:Dynamic) {}
				}
			}

			if (!hasCustomClassInstance) {
				sscript.interp.scriptObject = parent;

				if (sscript.instance != null && sscript.instance != {}) {
					if (Std.isOfType(sscript.instance, CustomClass)) {
						try {
							cast(sscript.instance, CustomClass).__interp.scriptObject = parent;
						} catch (e:Dynamic) {}
					}
				}
			}
		}
	}

	public override function onLoad() {
		if (code != null && code.trim() != "") {
			sscript.doString(code, fileName);

			if (sscript.parsingException != null) {
				DebugMenu.addTextToDebug("Failed to execute script: " + sscript.parsingException.toString(), FlxColor.RED);
				_trace("Failed to execute script: " + sscript.parsingException.toString());
				return;
			}
		}

		if (sscript != null && sscript.interp != null) {
			HScript.syncCustomClassStatics(sscript.interp);

			if (sscript.interp.scriptObject != null) {
				setParent(sscript.interp.scriptObject);
			}
		}

		#if GLOBAL_SCRIPT
		GlobalScript.call("onScriptSetup", [this, "hscript"]);
		#end
	}

	public override function reload() {
		if (sscript != null) {
			sscript.interp.scriptObject = null;
			sscript.interp.allowStaticVariables = false;
			sscript.interp.allowPublicVariables = false;
		}

		var savedVariables:Map<String, Dynamic> = [];
		if (sscript != null && sscript.interp != null) {
			for (k => e in sscript.interp.variables) {
				if (!Reflect.isFunction(e))
					savedVariables[k] = e;
			}
		}

		var oldParent = sscript != null ? sscript.interp.scriptObject : null;

		onCreate(path);

		for (k => e in Script.getDefaultVariables(this))
			set(k, e);

		load();
		if (oldParent != null)
			setParent(oldParent);

		for (k => e in savedVariables) {
			if (sscript.interp.publicVariables != null && sscript.interp.publicVariables.exists(k))
				continue;
			if (sscript.interp.staticVariables != null && sscript.interp.staticVariables.exists(k))
				continue;
			sscript.interp.variables.set(k, e);
		}

		sscript.interp.allowStaticVariables = true;
		sscript.interp.allowPublicVariables = true;
	}

	private override function onCall(funcName:String, parameters:Array<Dynamic>):Dynamic {
		if (sscript == null)
			return null;
		if (parameters == null)
			parameters = [];
		var res = sscript.call(funcName, parameters);
		return res.returnValue;
	}

	public override function get(val:String):Dynamic {
		return sscript.get(val);
	}

	public override function set(val:String, value:Dynamic) {
		sscript.set(val, value);
	}

	override public function destroy() {
		if (sscript != null) {
			sscript.interp.scriptObject = null;
			sscript.destroy();
			sscript = null;
		}
		super.destroy();
	}

	private function importScriptFile(path:String):Dynamic {
		if (path == null || path.trim() == "")
			return null;

		var seperatedPath = path.split('.');
		var script:Script = Script.create('${Flags.scriptFolder}/' + seperatedPath[0] + '.hx');
		script.active = false;

		if (script is DummyScript) {
			DebugMenu.addTextToDebug("WARN: Script at '" + path + "' does not exist.", FlxColor.ORANGE);
			_trace("WARN: Script at '" + path + "' does not exist.");
			return null;
		}

		if (ownerPack != null && !ownerPack.contains(script.path))
			ownerPack.add(script);

		script.load();
		return null;
	}

	public static var classStatics:Map<String, Map<String, Dynamic>> = [];
	public static var globalCustomClassStatics:Map<String, Map<String, Dynamic>> = [];

	public static function syncCustomClassStatics(interp:hscript.Interp) {
		if (interp == null || interp.customClasses == null)
			return;

		for (className => classHandler in interp.customClasses) {
			try {
				@:privateAccess {
					if (classHandler.__interp != null) {
						if (!globalCustomClassStatics.exists(className)) {
							globalCustomClassStatics.set(className, classHandler.__interp.variables);
						} else {
							var globalVars = globalCustomClassStatics.get(className);
							for (key => val in classHandler.__interp.variables) {
								if (Reflect.isFunction(val)) {
									globalVars.set(key, val);
								} else if (!globalVars.exists(key)) {
									globalVars.set(key, val);
								}
							}
							classHandler.__interp.variables = globalVars;
						}
					}
				}
			} catch (e:Dynamic) {}
		}
	}
}

class Script extends FlxBasic implements IFlxDestroyable {
	public var sourcePath:String;
	public var ownerPack:ScriptPack;

	public function setPublicMap(map:Map<String, Dynamic>) {}

	public function setStaticMap(map:Map<String, Dynamic>) {}

	public function getScriptHandle():Dynamic
		return null;

	public static var staticVariables:Map<String, Dynamic> = [];

	public function event<T:CancellableEvent>(func:String, event:T):T {
		call(func, [event]);
		return event;
	}

	public static function getDefaultVariables(?script:Script):Map<String, Dynamic> {
		return [
			"Items" => Items,
			"Objectives" => Objectives,
			"Room" => Room,
			"GamePrefs" => GamePrefs,
			"StateBackend" => StateBackend,
			"SubStateBackend" => SubStateBackend,
			"Controls" => Controls,
			#if FEATURE_DISCORD_RPC
			"Discord" => Discord,
			#end
			"Flags" => Flags,
			"Game" => Game,
			"Objective" => Objective,
			"Character" => Character,
			"ObjectivePopUp" => ObjectivePopUp,
			"Player" => Player,
			"ScriptedSprite" => ScriptedSprite,
			"ScriptedSpriteGroup" => ScriptedSpriteGroup,
			"ScriptedState" => ScriptedState,
			"ScriptedSubState" => ScriptedSubState,
			"BaseRoom" => BaseRoom,
			"MainState" => MainState,
			"TitleMenu" => TitleMenu,
			"InventoryMenu" => InventoryMenu,
			"LanguageMenu" => LanguageMenu,
			"ModSelectorMenu" => ModSelectorMenu,
			"ObjectivesMenu" => ObjectivesMenu,
			"PauseMenu" => PauseMenu,
			"SaveLoadMenu" => SaveLoadMenu,
			"SettingsMenu" => SettingsMenu,
			"DialogBox" => DialogBox,
			"DialogSelection" => DialogSelection,
			"ImprovedNinePatch" => ImprovedNinePatch,
			#if sys
			"File" => sys.io.File, "FileSystem" => sys.FileSystem,
			#end
			"Lang" => Lang,
			"LangText" => LangText,
			"LangSprite" => LangSprite,
			"Main" => Main,

			// Flixel
			"FlxG" => FlxG,
			"FlxSprite" => FlxSprite,
			"FlxSpriteGroup" => flixel.group.FlxSpriteGroup,
			"FlxGamepad" => flixel.input.gamepad.FlxGamepad,
			"FlxCamera" => FlxCamera,
			"FlxTween" => FlxTween,
			"FlxEase" => FlxEase,
			"FlxText" => FlxText,
			"FlxGroup" => FlxGroup,
			"FlxColor" => getMacroAbstractClass("flixel.util.FlxColor"),
			"FlxTypedGroup" => FlxTypedGroup,
			"FlxKey" => getMacroAbstractClass("flixel.input.keyboard.FlxKey"),
			"FlxTextBorderStyle" => flixel.text.FlxTextBorderStyle,
			"FlxBasic" => FlxBasic,
			"FlxObject" => FlxObject,
			"FlxState" => FlxState,
			"FlxSubState" => FlxSubState,
			"FlxMath" => flixel.math.FlxMath,
			"FlxPoint" => getMacroAbstractClass("flixel.math.FlxPoint"),
			"FlxRect" => flixel.math.FlxRect,
			"FlxVelocity" => flixel.math.FlxVelocity,
			"FlxAngle" => flixel.math.FlxAngle,
			"FlxTimer" => flixel.util.FlxTimer,
			"FlxSave" => flixel.util.FlxSave,
			"FlxSort" => flixel.util.FlxSort,
			"FlxStringUtil" => flixel.util.FlxStringUtil,
			"FlxAxes" => getMacroAbstractClass("flixel.util.FlxAxes"),
			"FlxDirectionFlags" => getMacroAbstractClass("flixel.util.FlxDirectionFlags"),
			"FlxGraphic" => flixel.graphics.FlxGraphic,
			"FlxAtlasFrames" => flixel.graphics.frames.FlxAtlasFrames,
			"FlxFrame" => flixel.graphics.frames.FlxFrame,
			"FlxAnimationController" => flixel.animation.FlxAnimationController,
			"FlxSound" => flixel.sound.FlxSound,
			"FlxSoundGroup" => flixel.sound.FlxSoundGroup,
			"FlxKeyboard" => flixel.input.keyboard.FlxKeyboard,
			"FlxMouse" => flixel.input.mouse.FlxMouse,
			"FlxBar" => flixel.ui.FlxBar,
			"FlxBarFillDirection" => flixel.ui.FlxBar.FlxBarFillDirection,
			"FlxButton" => flixel.ui.FlxButton,
			"FlxEmitter" => flixel.effects.particles.FlxEmitter,
			"FlxParticle" => flixel.effects.particles.FlxParticle,
			"FlxTrail" => flixel.addons.effects.FlxTrail,
			"FlxTilemap" => flixel.tile.FlxTilemap,
			"FlxBaseTilemap" => flixel.tile.FlxBaseTilemap,
			"FlxShader" => flixel.system.FlxShader,

			// OpenFL
			"Assets" => Assets, // use the Assets class for accessing anything necessary.
			"Shader" => openfl.display.Shader,
			"ShaderFilter" => openfl.filters.ShaderFilter,

			// hxFileManager
			"FileDialog" => hxfilemanager.FileDialog,
			"DialogKind" => hxfilemanager.Model.DialogKind,

			// Godot (Yeah Godot, it's weird to see right?)
			"AnimatedSprite" => AnimatedSprite,
			"AnimationPlayer" => AnimationPlayer,
			"Area2D" => Area2D,
			"CenterContainer" => CenterContainer,
			"CollisionPolygon2D" => CollisionPolygon2D,
			"CollisionShape2D" => CollisionShape2D,
			"ColorRect" => ColorRect,
			"Control" => Control,
			"Curve2D" => Curve2D,
			"Label" => Label,
			"Light2D" => Light2D,
			"MarginContainer" => MarginContainer,
			"Node" => Node,
			"Node2D" => Node2D,
			"Path2D" => Path2D,
			"PathFollow2D" => PathFollow2D,
			"Sprite" => Sprite,
			"TextureRect" => TextureRect,
			"TileMap" => TileMap,

			"Math" => Math,
			"Std" => Std,
			"StringTools" => StringTools,

			"Json" => haxe.Json,
			"Map" => getMacroAbstractClass("haxe.ds.CustomMap"), // Normal Map Doesn't work some reason.
			"ObjectMap" => haxe.ds.ObjectMap,
			"IntMap" => haxe.ds.IntMap,
			"StringMap" => haxe.ds.StringMap
		];
	}

	public static function getDefaultPreprocessors():Map<String, Dynamic> {
		return macros.DefineMacro.defines;
	}

	@:noUsing public static inline function getMacroAbstractClass(className:String) {
		return Type.resolveClass('${className}_HSC');
	}

	public static var scriptExtensions:Array<String> = ["hx", "hscript", "hsc", "hxs", "pack"];
	public static var curScript:Script = null;

	public var fileName:String;
	public var extension:String;
	public var path:String = null;

	private var rawPath:String = null;
	private var didLoad:Bool = false;

	public var remappedNames:Map<String, String> = [];

	public static function create(path:String):Script {
		var originalPath = path;

		var fullPath = Assets.getPath(originalPath);
		if (Assets.exists(fullPath)) {
			return switch (Path.extension(fullPath).toLowerCase()) {
				case "hx" | "hscript" | "hsc" | "hxs":
					new HScript(originalPath);
				default:
					new DummyScript(originalPath);
			}
		}
		return new DummyScript(originalPath);
	}

	public static function fromString(code:String, path:String):Script {
		return switch (Path.extension(path).toLowerCase()) {
			case "hx" | "hscript" | "hsc" | "hxs":
				new HScript(path).loadFromString(code);
			default:
				new DummyScript(path).loadFromString(code);
		}
	}

	static function safeWithoutDirectory(path:String) {
		try {
			return Path.withoutDirectory(path);
		} catch (e:Dynamic) {
			return null;
		}
	}

	static function safeExtension(path:String) {
		try {
			return Path.extension(path);
		} catch (e:Dynamic) {
			return null;
		}
	}

	public function new(path:String) {
		super();
		this.sourcePath = path;
		path = Assets.getPath(path);
		rawPath = path;
		fileName = safeWithoutDirectory(path);
		extension = safeExtension(path);
		this.path = path;

		onCreate(path);

		for (k => e in getDefaultVariables(this))
			set(k, e);
		set("disableScript", () -> {
			active = false;
		});

		var scriptHandle:Dynamic = getScriptHandle();
		set("__script__", scriptHandle != null ? scriptHandle : this);
	}

	public function load() {
		if (didLoad)
			return;
		var oldScript = curScript;
		curScript = this;
		onLoad();
		curScript = oldScript;
		didLoad = true;
	}

	public function reload() {}

	public function _trace(v:Dynamic) {
		var fn = remappedNames.exists(fileName) ? remappedNames.get(fileName) : fileName;
		DebugMenu.addTextToDebug('$fn: ' + Std.string(v));
		var str = '$fn: ' + Std.string(v);
		#if js
		if (js.Syntax.typeof(untyped console) != "undefined" && (untyped console).log != null)
			(untyped console).log(str);
		#elseif lua
		untyped __define_feature__("use._hx_print", _hx_print(str));
		#elseif sys
		Sys.println(str);
		#else
		// Fallback if target is unsupported
		#end
	}

	public function call(func:String, ?parameters:Array<Dynamic>):Dynamic {
		var oldScript = curScript;
		curScript = this;
		var result = onCall(func, parameters == null ? [] : parameters);
		curScript = oldScript;
		return result;
	}

	public function loadFromString(code:String)
		return this;

	public function setParent(variable:Dynamic) {}

	public function get(variable:String):Dynamic
		return null;

	public function set(variable:String, value:Dynamic):Void {}

	public function setupPlayState():Void {}

	public function error(text:String, ?additionalInfo:Dynamic):Void {
		var fn = remappedNames.exists(fileName) ? remappedNames.get(fileName) : fileName;
		DebugMenu.addTextToDebug(fn + text, FlxColor.RED);
		_trace(fn + text);
	}

	override public function toString():String {
		return FlxStringUtil.getDebugString(didLoad ? [LabelValuePair.weak("path", path), LabelValuePair.weak("active", active),] : [
			LabelValuePair.weak("path", path),
			LabelValuePair.weak("active", active),
			LabelValuePair.weak("loaded", didLoad),
		]);
	}

	private function onCall(func:String, parameters:Array<Dynamic>):Dynamic
		return null;

	public function onCreate(path:String) {}

	public function onLoad() {}
}

class DummyScript extends Script {
	public var variables:Map<String, Dynamic> = [];

	public override function get(v:String)
		return variables.get(v);

	public override function set(v:String, v2:Dynamic)
		return variables.set(v, v2);

	public override function onCall(method:String, parameters:Array<Dynamic>):Dynamic {
		var func = variables.get(method);
		if (Reflect.isFunction(func))
			return (parameters != null && parameters.length > 0) ? Reflect.callMethod(null, func, parameters) : func();
		return null;
	}
}

@:access(CancellableEvent)
class ScriptPack extends Script {
	public var scripts:Array<Script> = [];
	public var additionalDefaultVariables:Map<String, Dynamic> = [];
	public var publicVariables:Map<String, Dynamic> = [];
	public var parent:Dynamic = null;

	public override function load() {
		for (e in scripts)
			e.load();
	}

	public function contains(path:String) {
		for (e in scripts)
			if (e.path == path)
				return true;
		return false;
	}

	public function new(name:String) {
		super(name);
	}

	public function getByPath(name:String) {
		for (s in scripts)
			if (s.path == name)
				return s;
		return null;
	}

	public function getByName(name:String) {
		for (s in scripts)
			if (s.fileName == name)
				return s;
		return null;
	}

	public override function call(func:String, ?parameters:Array<Dynamic>):Dynamic {
		for (e in scripts)
			if (e.active)
				e.call(func, parameters);
		return null;
	}

	override public function event<T:CancellableEvent>(func:String, event:T):T {
		for (e in scripts) {
			if (!e.active)
				continue;
			e.call(func, [event]);
			if (event.cancelled && !event.__continueCalls)
				break;
		}
		return event;
	}

	public override function get(val:String):Dynamic {
		if (publicVariables.exists(val))
			return publicVariables.get(val);
		if (staticVariables.exists(val))
			return staticVariables.get(val);

		for (e in scripts) {
			var v = e.get(val);
			if (v != null)
				return v;
		}
		return null;
	}

	public override function reload() {
		for (e in scripts)
			e.reload();
	}

	public override function set(val:String, value:Dynamic) {
		publicVariables.set(val, value);
		for (e in scripts)
			e.set(val, value);
	}

	public override function setParent(parent:Dynamic) {
		this.parent = parent;
		for (e in scripts)
			e.setParent(parent);
	}

	public override function destroy() {
		super.destroy();
		for (e in scripts)
			e.destroy();
	}

	public override function onCreate(path:String) {}

	public function add(script:Script) {
		scripts.push(script);
		__configureNewScript(script);
	}

	public function remove(script:Script) {
		scripts.remove(script);
	}

	public function insert(pos:Int, script:Script) {
		scripts.insert(pos, script);
		__configureNewScript(script);
	}

	private function __configureNewScript(script:Script) {
		script.ownerPack = this;
		if (parent != null)
			script.setParent(parent);
		for (k => e in additionalDefaultVariables)
			script.set(k, e);
	}

	override public function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("parent", FlxStringUtil.getClassName(parent, true)),
			LabelValuePair.weak("total", scripts.length),
		]);
	}

	public var staticVariables:Map<String, Dynamic> = [];
}

#if GLOBAL_SCRIPT
class GlobalScript {
	public static var scripts:ScriptPack;
	private static var initialized:Bool = false;

	public static function init() {
		if (initialized)
			return;
		initialized = true;
		onSetupScript();

		FlxG.signals.focusGained.add(function() call("focusGained"));
		FlxG.signals.focusLost.add(function() call("focusLost"));
		FlxG.signals.gameResized.add(function(w:Int, h:Int) call("gameResized", [w, h]));
		FlxG.signals.postDraw.add(function() call("postDraw"));
		FlxG.signals.postGameReset.add(function() call("postGameReset"));
		FlxG.signals.postGameStart.add(function() call("postGameStart"));
		FlxG.signals.postStateSwitch.add(function() call("postStateSwitch"));
		FlxG.signals.postUpdate.add(function() call("postUpdate", [FlxG.elapsed]));
		FlxG.signals.preDraw.add(function() call("preDraw"));
		FlxG.signals.preGameReset.add(function() call("preGameReset"));
		FlxG.signals.preGameStart.add(function() call("preGameStart"));
		FlxG.signals.preStateCreate.add(function(state:FlxState) call("preStateCreate", [state]));
		FlxG.signals.preStateSwitch.add(function() call("preStateSwitch", []));
		FlxG.signals.preUpdate.add(function() {
			call("preUpdate", [FlxG.elapsed]);
			call("update", [FlxG.elapsed]);
		});
	}

	public static function onSetupScript() {
		destroy();
		scripts = new ScriptPack("GlobalScript");

		var path = '${Flags.scriptFolder}/Global.hx';
		var script = Script.create(path);
		if (!(script is DummyScript)) {
			script.remappedNames.set(script.fileName, '${script.fileName}');
			scripts.add(script);
			script.load();
		}
	}

	public static function event<T:CancellableEvent>(name:String, event:T):T {
		if (scripts != null)
			scripts.event(name, event);
		return event;
	}

	public static inline function call(name:String, ?args:Array<Dynamic>) {
		if (scripts != null)
			scripts.call(name, args);
	}

	public static inline function destroy() {
		if (scripts != null) {
			call("destroy");
			scripts = FlxDestroyUtil.destroy(scripts);
		}
	}
}
#end
#end
