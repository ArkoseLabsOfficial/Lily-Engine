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
		FlxAssets.FONT_DEFAULT = "assets/font/NotoSans-Regular.ttf";
		FlxText.defaultTextAntialiasing = true;
		FlxSprite.defaultAntialiasing = false;

		@:privateAccess
		Main.game = new Game(); // Stores `inventory, save, objectives, language, game pause`

		// Inits
		Game.instance.init();
		Lang.init('en', Flags.languageFolder);

		GamePrefs.loadMod();

		#if GLOBAL_SCRIPT
		HScript.GlobalScript.init();
		#end

		// Settings
		GamePrefs.loadSettings();

		#if FEATURE_TOUCH_CONTROLS
		mobile.Config.init();
		#end

		#if linux
		var iconImage = Image.fromFile("assets/images/icons/game_round.png");
		Lib.current.stage.window.setIcon(iconImage);
		#end

		#if FEATURE_DISCORD_RPC
		engine.backend.Discord.initialize();
		#end

		#if sys
		if (!SysFileSystem.exists('mods/'))
			SysFileSystem.createDirectory('mods/');
		#end

		StateBackend.switchState(new TitleMenu());
	}
}
