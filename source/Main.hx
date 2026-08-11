package;

import flixel.FlxGame;
import openfl.display.Sprite;
import engine.states.TitleMenu;
import flixel.system.FlxAssets;
import flixel.FlxSprite;
import openfl.Assets;
import haxe.io.Bytes;
import openfl.display.Bitmap;
#if sys
import sys.FileSystem as SysFileSystem;
import sys.io.File as SysFile;
#end
import openfl.events.MouseEvent;

#if FEATURE_TOUCH_CONTROLS
import mobile.openfl.controls.MobileControls;
#end
import openfl.ui.Mouse;

class Main extends Sprite {
	public static var game:Game;
	#if FEATURE_TOUCH_CONTROLS
	public static var mobileControls:MobileControls;
	#end
    public function new() {
        super();
		/* Game and Mobile Control Childs */
		#if FEATURE_TOUCH_CONTROLS
		mobileControls = new MobileControls(1920, 1080);
		#end
		addChild(new FlxGame(1920, 1080, MainState, 60, 60, true));
		#if FEATURE_TOUCH_CONTROLS
		addChild(mobileControls);
		mobile.openfl.screen.ScreenUtil.init(stage);
		#end

		FlxG.mouse.useSystemCursor = true;
		FlxG.fixedTimestep = false;

		// Custom Mouse Loading for Desktop Builds
		#if desktop
		var bitmapData = FileSystem.getBitmapData("assets/images/ui/cursor.png");
        var customCursor = new Bitmap(bitmapData);
        addChild(customCursor);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
			Mouse.hide();
			customCursor.x = e.stageX;
			customCursor.y = e.stageY;
		});
		customCursor.smoothing = true;
		customCursor.scaleX = 0.13;
		customCursor.scaleY = 0.13;
		#end
    }

	static var loadedFiles = new Map<String, Bool>();
}