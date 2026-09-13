package;

import flixel.FlxGame;
import openfl.display.Sprite;
import engine.states.TitleMenu;
import flixel.system.FlxAssets;
import flixel.FlxSprite;
import openfl.Assets;
import openfl.Lib;
import openfl.display.StageScaleMode;
import haxe.io.Bytes;
import openfl.display.Bitmap;
import openfl.events.MouseEvent;
import debug.FPSCounter;
import debug.DebugMenu;
import hxfilemanager.FileDialog;

#if FEATURE_TOUCH_CONTROLS
import mobile.openfl.controls.MobileControls;
#end
import openfl.ui.Mouse;

class Main extends Sprite {
	public static var game:Game;
	#if FEATURE_TOUCH_CONTROLS
	public static var mobileControls:MobileControls;
	#end
	public static var fpsVar:FPSCounter;
	public static var fileDialog:FileDialog; // Custom File Dialog.

    public function new() {
        super();
		/* Game and Mobile Control Childs */
		#if FEATURE_TOUCH_CONTROLS
		mobileControls = new MobileControls(1920, 1080);
		#end
		addChild(new FlxGame(1920, 1080, MainState, 60, 60, true));
		addChild(fileDialog = new FileDialog());
		#if FEATURE_TOUCH_CONTROLS
		addChild(mobileControls);
		mobile.openfl.screen.ScreenUtil.init(stage);
		#end
		#if android FlxG.android.preventDefaultKeys = [BACK]; #end
		addChild(new DebugMenu());

		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = true;
		}

		FlxG.mouse.useSystemCursor = true;
		FlxG.fixedTimestep = true;

		// Custom Mouse Loading for Desktop Builds
		#if desktop
		var bitmapData = Assets.getImage("ui/cursor");
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
}