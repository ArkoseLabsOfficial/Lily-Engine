import flixel.sound.FlxSound;
import openfl.utils.Assets;
importScript("PartyShortcuts");

class RoomProps {
	public static var music:FlxSound = null;
	public static var lacie:CharacterShortcuts;

	public var location:String = "Unknown";
	public var party:Array<String> = [];
	public var BGMusic:String = "";

	public function onRoomLoaded():Void {
		Game.save.location = location;

		if (BGMusic != "" && BGMusic != null) {
			if (music != null) {
				music.stop();
				music.destroy();
			}
			music = new FlxSound();
			music.loadEmbedded('sounds/bgm/$BGMusic.ogg', true);
			FlxG.sound.list.add(music);
			music.play();
		}


		PartyShortcuts.createPartyChar("lacie");
		Game.baseRoom.addFollower(Game.party[1], Game.party[0]);

		PartyShortcuts.createPartyChar("lacie");
		Game.baseRoom.addFollower(Game.party[2], Game.party[1]);
	}
}
