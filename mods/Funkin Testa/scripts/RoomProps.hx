import flixel.sound.FlxSound;
import openfl.utils.Assets;
importScript("CharacterShortcuts");

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

		lacie = new CharacterShortcuts();
		lacie.createCharacter("lacie");
		lacie.addAsFollower(Game.party[0]);

		var hmm = new CharacterShortcuts();
		hmm.createCharacter("lacie");

		Game.party.push(lacie.character);
		Game.party.push(hmm.character);
		hmm.addAsFollower(Game.party[1]);
	}
}
