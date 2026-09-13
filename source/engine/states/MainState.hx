package engine.states;

import lang.Lang;
#if linux
import lime.app.Application;
import lime.graphics.Image;
import openfl.Lib;
#end
#if sys
import sys.FileSystem as SysFileSystem;
import sys.io.File as SysFile;
#end

class MainState extends StateBackend {
	public override function create() {
		super.create();
		#if android
		Sys.setCwd(haxe.io.Path.addTrailingSlash(android.content.Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.documentsDirectory);
		#end

		@:privateAccess
		Main.game = new Game(); // Stores `inventory, save, objectives, language, game pause`

		// Inits
		GamePrefs.loadMod();
		Game.instance.init();
		Lang.init('en', Flags.languageFolder);

		FlxText.defaultTextAntialiasing = true;
		FlxSprite.defaultAntialiasing = false;

		#if GLOBAL_SCRIPT
		HScript.GlobalScript.init();
		#end

		// Settings
		GamePrefs.loadSettings();

		// font map
		Flags.fonts.set("NotoSans", '${Flags.fontFolder}/${Lang.get('fonts.NotoSans')}');
		Flags.fonts.set("AlegreyaSC", '${Flags.fontFolder}/${Lang.get('fonts.AlegreyaSC')}');
		FlxAssets.FONT_DEFAULT = Flags.fonts.get("NotoSans");

		#if FEATURE_TOUCH_CONTROLS
		mobile.Config.init();
		#end

		#if linux
		var iconImage = Image.fromFile('assets/${Flags.imageFolder}/icons/game_round.png');
		Lib.current.stage.window.setIcon(iconImage);
		#end

		#if FEATURE_DISCORD_RPC
		engine.backend.Discord.initialize();
		#end

		#if sys
		if (!SysFileSystem.exists('mods/'))
			SysFileSystem.createDirectory('mods/');
		#end

		FlxG.switchState(new TitleMenu());
	}
}
