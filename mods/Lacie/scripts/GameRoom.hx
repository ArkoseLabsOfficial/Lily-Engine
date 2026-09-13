import flixel.util.FlxTimer;

using StringTools;

class GameRoom {
	public var Cutscene:Bool = false;
	public var CameraZoom:Float = 1.0;

	public var CameraLimitLeft:Int = -10000000;
	public var CameraLimitTop:Int = -10000000;
	public var CameraLimitRight:Int = 10000000;
	public var CameraLimitBottom:Int = 10000000;

	public var Bgm:String = null;
	public var BgmVolume:Float = 1.0;
	public var BgmCrossfade:Bool = false;

	public static var music:FlxSound = null;

	public var Type:String = "default";
	public var DisableRunning:Bool = false;
	public var EnableSneaking:Bool = false;
	public var HideFollowers:Bool = false;

	public var SaveLocation:String = "";
	public var SaveImage:String = "";

	var scene = parent.scene;

	public function add(obj:Dynamic) {
		parent.add(obj);
	}

	public function onRoomLoaded(roomName:String) {
		if (Game.baseRoom.camGame != null) {
			Game.baseRoom.camGame.zoom = CameraZoom + 2;
			Game.baseRoom.camGame.setScrollBounds(CameraLimitLeft, CameraLimitRight, CameraLimitTop, CameraLimitBottom);
		}

		_Initialize();
		_Ready();
		_BeforeFadeIn();
		_UpdateRoom();

		if (roomName == "Void") {
			for (member in Game.party) {
				member.canMove = false;
				member.visible = false;
			}
		}
	}

	function update(elapsed:Float) {
		_RoomProcess(elapsed);
	}

	function _RoomProcess() {}

	function _Initialize() {
		if (Bgm != null && Bgm.length > 0) {
			playMusic(Bgm, BgmVolume, BgmCrossfade);
		}
	}

	/**
	 * Plays background music with explicit options for fading out the old track and fading in the new one.
	 * @param song The music file name/path.
	 * @param volume Target volume for the music.
	 * @param fadeOut Whether to fade out the currently playing music before starting the new one.
	 * @param fadeIn Whether to fade in the new music once it starts.
	 */
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

	/**
	 * Smoothly fades out and stops the current background music.
	 * @param duration How long the fade-out should take in seconds (default is 1.0).
	 */
	public function fadeOutMusic(duration:Float = 1.0) {
		if (music != null && music.playing) {
			music.fadeOut(duration, 0, function(tmr) {
				music.stop();
				music = null;
			});
		}
	}

	public function stopMusic() {
		music.stop();
		music = null;
	}

	private function startNewMusic(path:String, volume:Float, fade:Bool) {
		music = FlxG.sound.play(path, volume, true); // true = loops
		if (music != null && fade) {
			music.volume = 0;
			music.fadeIn(1.0, 0, volume);
		}
	}

	function _UpdateRoom() {}

	function _Ready() {}

	function _BeforeFadeIn() {}
}
