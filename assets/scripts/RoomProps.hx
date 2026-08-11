package;

import engine.backend.Game;
import io.LilyAssets;
import flixel.sound.FlxSound;

class RoomProps {
	public static var music:FlxSound = null;

	public var location:String = "Unknown";
	public var party:Array<String> = [];
	public var BGMusic:String = "";

	public function onRoomLoaded():Void {
		Game.save.location = location;

		if (BGMusic != "" && BGMusic != null) {
			var bgmAsset = LilyAssets.sound('bgm/$BGMusic');
			if (bgmAsset != null) {
				if (music != null) {
					music.stop();
					music.destroy();
				}
				music = new FlxSound();
				music.loadEmbedded(bgmAsset, true);
				FlxG.sound.list.add(music);
				music.play();
			}
		}

		Game.objectives.addObjective("main_investigation");
		Game.objectives.failObjective("main_investigation.explore_hall.open_drawer");
	}
}
