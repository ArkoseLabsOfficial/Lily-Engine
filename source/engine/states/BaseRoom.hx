package engine.states;

class BaseRoom extends StateBackend {
	var room:Room;
	var isFromLoad:Bool;
	var roomName:String;
	var canPause:Bool = true;

	public var camGame:GameCamera;

	public static var instance:BaseRoom;

	public var party:Array<Character> = [];

	public function new(room:String = "bathroom", fromLoad:Bool = false) {
		super();
		this.isFromLoad = fromLoad;
		this.roomName = room;
	}

	override function openSubState(SubState:FlxSubState) {
		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeJoyStick();
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		#end
		canPause = false;
		super.openSubState(SubState);
	}

	override function closeSubState() {
		super.closeSubState();
		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeJoyStick();
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		Game.mobileC.addJoyStick("GAME");
		Game.mobileC.addButton("GAME");
		#end
		canPause = true;
		Discord.updatePresence('In the $roomName Room', 'Mod: ${GamePrefs.currentMod}');
	}

	override public function create():Void {
		super.create();
		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeJoyStick();
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		Game.mobileC.addJoyStick("GAME");
		Game.mobileC.addButton("GAME");
		#end

		camGame = new GameCamera();
		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		instance = this;

		room = new Room();
		room.loadRoom(roomName, isFromLoad);

		add(room);
	}

	public function followTheObject(obj:Dynamic, type:String = "NO_DEAD_ZONE", smoothness:Float = 1):Void {
		var realType:FlxCameraFollowStyle = NO_DEAD_ZONE;
		switch (type) {
			case "LOCKON":
				realType = LOCKON;
			case "PLATFORMER":
				realType = PLATFORMER;
			case "TOPDOWN":
				realType = TOPDOWN;
			case "TOPDOWN_TIGHT":
				realType = TOPDOWN_TIGHT;
			case "SCREEN_BY_SCREEN":
				realType = SCREEN_BY_SCREEN;
			case "NO_DEAD_ZONE":
				realType = NO_DEAD_ZONE;
		}

		camGame.follow(obj, realType, smoothness);
	}

	override public function update(elapsed:Float):Void {
		if (Game.paused)
			return;

		super.update(elapsed);

		Game.save.playtime += elapsed;

		var targetCharacter:Character = cast camGame.target;
		if (targetCharacter != null)
			camGame.targetOffset.set(targetCharacter.cameraOffset.x, targetCharacter.cameraOffset.y);

		if (Controls.MENU && canPause) {
			openSubState(new PauseMenu());
		}
	}
}
