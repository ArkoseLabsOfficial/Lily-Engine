package hxscript;

#if (!macro) import hxscript.setup.Defines; #end
import hxscript.syntax.Expr;
import hxscript.proxy.*;
#if (hl || python) import hxscript.proxy.MathProxy; #end

/**
 * Global, process-wide interpreter configuration: which interpreter class to instantiate, access
 * rules, reflection shims, the default variable/import/type-proxy tables, and the type blacklist.
 * These are static so every `Interp`, `Module`, and `Script` shares one setup.
 */
class Config {
	#if (!macro)
	/** The interpreter class instantiated by `Module`/`Script`; override to plug in a subclass. */
	public static var interpClass:Class<hxscript.runtime.Interp> = hxscript.runtime.Interp;

	/**
	 * Enforces `private` on script-declared members: reading or writing one from outside the declaring class
	 * (or a subclass) errors instead of succeeding. Only explicit `private` counts. Scripts treat
	 * unmarked members as public, unlike Haxe, because every existing script relies on that.
	 */
	public static var strictAccess:Bool = false;

	/**
	 * Whether cppia declares a `Bool` field with its real type, which needs the hxcpp fix in
	 * `HXCPP-ISSUES.md`. `-D hxscript_cppia_bool_compat` turns it off for a stock hxcpp, where a
	 * boolean is then right interpreted and wrong jitted.
	 */
	public static var nativeBoolSlots:Bool = #if hxscript_cppia_bool_compat false #else true #end;

	/**
	 * Runtime type enforcement. When on, declared types on variables, function parameters, function returns,
	 * and `cast(x, T)` are checked against the value: assignable ones pass (with `Int`->`Float` widening),
	 * and an incompatible value throws, the way typed Haxe would reject it. When off, type annotations are
	 * ignored and everything stays dynamic (only abstract `from`/`to` casts apply).
	 */
	public static var typedMode:Bool = #if hxscript_dynamic false #else true #end;

	/**
	 * Emulation shims for methods that have NO runtime representation and so can't be reflected on,
	 * notably `inline extern` overloads, which compiled Haxe inlines at the call site but a script can only reach
	 * reflectively (and gets null). A shim is a real compiled closure that performs the call; it is keyed by
	 * the owner's fully-qualified class name + `.` + method (e.g. `some.pack.Owner.method`).
	 */
	public static var callShims:Map<String, (o:Dynamic, args:Array<Dynamic>) -> Dynamic> = new Map();

	/** Preprocessor values visible to `#if`/`#elseif` in scripts, seeded from the host compiler defines plus `hxscript`. */
	public static var preprocessorValues:Map<String, Dynamic> = Defines.appendCompilerDefines(['hxscript' => '1']);

	/**
	 * Variables defined in every interpreter by default: the literals `null`/`true`/`false`, and the
	 * `Int`/`Float`/`Bool` type tokens (see `CoreType`) so those primitives are usable as
	 * values in `is`/`Std.isOfType`/`cast`.
	 */
	public static var globalVariables:Map<String, Dynamic> = [
		'null' => null,
		'true' => true,
		'false' => false,
		'Int' => CoreType.CTInt,
		'Float' => CoreType.CTFloat,
		'Bool' => CoreType.CTBool,


        
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
		"FlxTypedGroup" => FlxTypedGroup,
		"FlxTextBorderStyle" => flixel.text.FlxTextBorderStyle,
		"FlxBasic" => FlxBasic,
		"FlxObject" => FlxObject,
		"FlxState" => FlxState,
		"FlxSubState" => FlxSubState,
		"FlxMath" => flixel.math.FlxMath,
		"FlxRect" => flixel.math.FlxRect,
		"FlxVelocity" => flixel.math.FlxVelocity,
		"FlxAngle" => flixel.math.FlxAngle,
		"FlxTimer" => flixel.util.FlxTimer,
		"FlxSave" => flixel.util.FlxSave,
		"FlxSort" => flixel.util.FlxSort,
		"FlxStringUtil" => flixel.util.FlxStringUtil,
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
	];

	/**
	 * Bare names that stand for a host static, as `owner.path::field`, read afresh for each interpreter.
	 */
	public static var globalStatics:Map<String, String> = [];

	/** Imports applied to every interpreter by default (the root package, wildcard-imported). */
	public static var globalImports:Map<String, ImportMode> = ['' => IAll];

	/** Maps a native type name a script might reference to the proxy class that stands in for it. */
	@:unreflective public static var typeProxy:Map<String, Dynamic> = [
		#if (hl || python)
		'Math' => MathProxy,
		#end
		'Reflect' => ReflectProxy,
		'Type' => TypeProxy,
		'Std' => StdProxy
	];

	/** Types scripts are forbidden to touch, grouped by how they are matched (exact type, module, or package). */
	@:unreflective public static var blacklist:Map<ConfigBlacklistKind,
		Array<String>> = [ByPackage(false) => [], ByPackage(true) => [], ByModule => [], ByType => [],];
	#end
}

/** Helpers for enforcing the `Config.blacklist`. */
class ConfigUtil {
	/**
	 * Tests whether a type is blacklisted by exact name, by its module, or by its package (exact or
	 * prefix, depending on how the package rule was registered).
	 *
	 * @param type The class or enum to test.
	 * @return True if the type is blacklisted.
	 */
	public static function typeIsBlacklisted(type:Dynamic):Bool {
		if (type == null)
			return false;

		var name:String = (type is Enum ? Type.getEnumName(type) : Type.getClassName(type));
		if (Config.blacklist.get(ByType)?.contains(name))
			return true;

		var info = hxscript.types.TypeCollection.main.fromCompilePath(name);
		if (info != null) {
			if (Config.blacklist.get(ByModule)?.contains(info[0].module))
				return true;
			if (Config.blacklist.get(ByPackage(false))?.contains(info[0].pack.join('.')))
				return true;
			if (Config.blacklist.exists(ByPackage(true))) {
				var eq:Bool = false;
				var pack:String = info[0].pack.join('.');

				for (p in Config.blacklist.get(ByPackage(true))) {
					if (StringTools.startsWith(pack, p))
						return true;
				}
			}
		}

		return false;
	}

	/**
	 * Passes a type through unless it is blacklisted, in which case it warns and returns null. Used
	 * to gate type lookups at their resolution points.
	 *
	 * @param type The class or enum to check.
	 * @return The same type, or null if blacklisted.
	 */
	public static function assertBlacklisted(type:Dynamic):Dynamic {
		if (typeIsBlacklisted(type)) {
			trace('WARNING: ${type is Enum ? Type.getEnumName(type) : Type.getClassName(type)} is blacklisted');

			return null;
		} else {
			return type;
		}
	}
}

/** How a `Config.blacklist` entry matches a type. */
enum ConfigBlacklistKind {
	/** Match every type in a package; `recursive` also matches sub-packages by prefix. */
	ByPackage(recursive:Bool);

	/** Match every type in a module. */
	ByModule;

	/** Match one exact type by fully-qualified name. */
	ByType;
}
