package engine.states;

typedef FollowerInfo = {
	var follower:Character;
	var target:Character;
	var distance:Int;
	var copyAnims:Bool;
}

class BaseRoom extends StateBackend {
	var room:RoomManager;
	var isFromLoad:Bool;
	var roomName:String;

	public var camGame:FlxCamera;

	public static var instance:BaseRoom;

	public var objectives:ObjectiveManager;
	public var followers:Array<FollowerInfo> = [];

	public function new(room:String = "bathroom", fromLoad:Bool = false) {
		super();
		this.isFromLoad = fromLoad;
		this.roomName = room;
	}

	override function openSubState(SubState:FlxSubState) {
		if (room != null && room.player != null)
			room.player.canMove = false;

		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeJoyStick();
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		#end
		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (room != null && room.player != null)
			room.player.canMove = true;

		super.closeSubState();
		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeJoyStick();
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		Game.mobileC.addJoyStick("GAME");
		Game.mobileC.addButton("GAME");
		#end
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

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		instance = this;
		objectives = new ObjectiveManager();

		room = new RoomManager(this);
		room.loadRoom(roomName);

		room.initPlayerState(camGame, isFromLoad);

		add(room);

		#if FEATURE_HSCRIPT
		room.scripts.setParent(this);
		room.scripts.call("onRoomLoaded", [roomName]);
		#end
		Game.save.room = roomName;
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

	public function clearFollowers():Void {
		followers = [];
	}

	public function addFollower(follower:Character, target:Character, distance:Int = 12, copyAnims:Bool = false):Void {
		removeFollower(follower);
		followers.push({
			follower: follower,
			target: target,
			distance: distance,
			copyAnims: copyAnims
		});
		follower.solidCollision = false;
	}

	public function removeFollower(follower:Character):Void {
		var i = followers.length;
		while (i > 0) {
			i--;
			if (followers[i].follower == follower) {
				followers.splice(i, 1);
				return;
			}
		}
	}

	override public function update(elapsed:Float):Void {
		if (Game.paused)
			return;

		super.update(elapsed);

		Game.save.playtime += elapsed;

		var currentTarget = camGame.target;
		if (currentTarget != null && Std.isOfType(currentTarget, Character)) {
			var charTarget:Character = cast currentTarget;
			camGame.targetOffset.set(charTarget.cameraOffset.x, charTarget.cameraOffset.y);
		} else if (room.player != null) {
			camGame.targetOffset.set(room.player.cameraOffset.x, room.player.cameraOffset.y);
		}

		var i = followers.length;
		while (i > 0) {
			i--;
			var f = followers[i];
			var follower = f.follower;
			var target = f.target;

			if (follower == null || !follower.exists || follower.velocity == null || target == null || !target.exists) {
				followers.splice(i, 1);
				continue;
			}

			if (target.positionHistory.length > f.distance) {
				var targetPos = target.positionHistory[f.distance];
				if (targetPos == null)
					continue;

				var oldX = follower.x;
				var oldY = follower.y;
				var lerp = elapsed * 14;
				if (lerp > 1)
					lerp = 1;

				follower.x += (targetPos.x - follower.x) * lerp;
				follower.y += (targetPos.y - follower.y) * lerp;
				follower.velocity.x = (follower.x - oldX) / elapsed;
				follower.velocity.y = (follower.y - oldY) / elapsed;

				if (Math.abs(targetPos.x - follower.x) < 0.5 && Math.abs(targetPos.y - follower.y) < 0.5) {
					follower.x = targetPos.x;
					follower.y = targetPos.y;
					follower.velocity.set(0, 0);
				}
			} else {
				follower.x = target.x;
				follower.y = target.y;
				follower.velocity.set(0, 0);
			}

			if (f.copyAnims) {
				follower.direction = target.direction;
				follower.state = target.state;

				var faceStr = switch (follower.direction) {
					case UP: "UP";
					case LEFT: "LEFT";
					case RIGHT: "RIGHT";
					default: "DOWN";
				};

				var animName = switch (follower.state) {
					case Walking: "walk" + faceStr;
					case Running: "run" + faceStr;
					default: "idle" + faceStr;
				};

				if (follower.animData.keys().hasNext()) {
					if (!follower.animData.exists(animName) && follower.state == Standing) {
						animName = follower.animData.exists("idle") ? "idle" : "idleDOWN";
					}
					follower.playAnim(animName);
				} else {
					var legacyFace = switch (follower.direction) {
						case UP: "_up";
						case LEFT: "_left";
						case RIGHT: "_right";
						default: "_down";
					};
					var legacyAnim = switch (follower.state) {
						case Walking: "walk" + legacyFace;
						case Running: "run" + legacyFace;
						default: "idle" + legacyFace;
					};
					follower.playAnim(legacyAnim);
				}
			}
		}

		if (Controls.MENU)
			openSubState(new Pause());
	}
}
