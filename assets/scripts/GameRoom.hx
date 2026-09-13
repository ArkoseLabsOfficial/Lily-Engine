import engine.scripting.ScriptedSubState;
import flixel.FlxG;
import flixel.FlxSound;
import flixel.util.FlxTimer;
importScript("QuickStuff");

using StringTools;

class GameRoom {
	public var cutscene:Bool = false;
	public var cameraZoom:Float = 1.0;

	public var cameraLimitLeft:Int = -10000000;
	public var cameraLimitTop:Int = -10000000;
	public var cameraLimitRight:Int = 10000000;
	public var cameraLimitBottom:Int = 10000000;

	public var bgm:String = null;
	public var bgmVolume:Float = 1.0;
	public var bgmCrossfade:Bool = false;

	public static var music:FlxSound = null;

	public var type:String = "default";
	public var disableRunning:Bool = false;
	public var enableSneaking:Bool = false;
	public var hideFollowers:Bool = false;

	public var saveLocation:String = "";
	public var saveImage:String = "";

	var scene = parent.scene;

	public function add(obj:Dynamic) {
		parent.add(obj);
	}

	public function onRoomLoaded(roomName:String) {
		if (Game.baseRoom.camGame != null) {
			Game.baseRoom.camGame.zoom = cameraZoom + 2;
			Game.baseRoom.camGame.setScrollBounds(cameraLimitLeft, cameraLimitRight, cameraLimitTop, cameraLimitBottom);
		}

		QuickStuff.registeredNPCs.clear();
		QuickStuff.quickStuffCamera = null;
		QuickStuff.black = null;
		_Initialize();
		_Ready();
		_BeforeFadeIn();
		_UpdateRoom();
	}

	function update(elapsed:Float) {
		if (FlxG.keys.justPressed.P)
			FlxG.state.openSubState(new ScriptedSubState("ObtainUI", {
				items: [{id: "ch1_knife", amount: 5}, {id: "ch1_knife", amount: 12}]
			}));

		_RoomProcess(elapsed);
	}

	function _RoomProcess(elapsed:Float) {}

	function _Initialize() {
		if (bgm != null && bgm.length > 0) {
			playMusic(bgm, bgmVolume, bgmCrossfade);
		}
	}

	public function playMusic(song:String, volume:Float = 1.0, fadeOut:Bool = true, fadeIn:Bool = true) {
		song = song.replace("assets/", "");
		var musicPath = 'sounds/$song';

		if (music != null && music.playing) {
			if (fadeOut) {
				music.fadeOut(1.0, 0, function(tmr) {
					music.stop();
					startNewMusic(musicPath, volume, fadeIn);
				});
				return;
			} else {
				music.stop();
			}
		}

		startNewMusic(musicPath, volume, fadeIn);
	}

	public function fadeOutMusic(duration:Float = 1.0) {
		if (music != null && music.playing) {
			music.fadeOut(duration, 0, function(tmr) {
				music.stop();
				music = null;
			});
		}
	}

	public function stopMusic() {
		if (music != null) {
			music.stop();
			music = null;
		}
	}

	private function startNewMusic(path:String, volume:Float, fade:Bool) {
		if (!Assets.exists(path))
			return;

		music = FlxG.sound.play(path, volume, true);

		if (music != null && fade) {
			music.volume = 0;
			music.fadeIn(1.0, 0, volume);
		}
	}

	function _UpdateRoom() {}

	function _Ready() {}

	function _BeforeFadeIn() {}
}
