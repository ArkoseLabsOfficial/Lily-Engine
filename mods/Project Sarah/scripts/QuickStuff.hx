import flixel.FlxSprite;
import engine.ui.GameCamera;

/**
 * A Quick static stuff for making things much easier.
 * @:Author: Zack Everett
 **/
class QuickStuff {
	public static var black:FlxSprite;
	public static var quickStuffCamera:FlxCamera;
	public static var registeredNPCs:StringMap = new StringMap();

	public static function init() {
		if (quickStuffCamera == null) {
			quickStuffCamera = new GameCamera();
			FlxG.cameras.add(quickStuffCamera, false);
			quickStuffCamera.bgColor = FlxColor.TRANSPARENT;
		}
	}

	public static function disablePlayer() {
		var player = Game.party[0];
		player.visible = false;
		player.movementEnabled = false;
	}

	public static function disableInteraction() {
		for (interaction in Game.party[0].interactions) {
			interaction.enabled = false;
		}
	}

	public static function enableInteraction() {
		for (interaction in Game.party[0].interactions) {
			interaction.enabled = true;
		}
	}

	public static function enablePlayer() {
		var player = Game.party[0];
		player.visible = true;
		player.movementEnabled = true;
	}

	public static function createNPC(name:String, sprite:String) {
		var character = new Character(0, 0, 1, name);
		character.loadEntity(sprite);
		var targetNode:Dynamic = Game.scene.getNode("Main");
		if (targetNode == null) {
			targetNode = Game.scene.root;
		}
		targetNode.add(character);
		registeredNPCs.set(name, character);
		return character;
	}

	public static function createBlackBox() {
		init();
		if (black == null) {
			black = new FlxSprite(0, 0).makeGraphic(1920, 1080, FlxColor.BLACK);
			Game.baseRoom.add(black);
			black.camera = quickStuffCamera;
		}
	}

	public static function blackIn(take:Float, ?onComplete:Void->Void) {
		init();
		createBlackBox();
		black.alpha = 0;
		FlxTween.tween(black, {alpha: 1}, take, { onComplete: onComplete });
	}

	public static function blackOut(take:Float, ?onComplete:Void->Void) {
		init();
		createBlackBox();
		FlxTween.tween(black, {alpha: 0}, take, { onComplete: onComplete });
	}

	public static function createPartyChar(name:String, follow:Dynamic):Character {
        var character = new Character(0, 0, 0, name);
        character.isSolid = false;
        character.loadEntity(name);
		character.follow(follow);
        var targetNode:Dynamic = Game.room.scene.getNode("Main");
        if (targetNode == null)
            targetNode = Game.room.scene.root;

        if (targetNode != null)
            targetNode.add(character);

        Game.party.push(character);

		return character;
    }
}