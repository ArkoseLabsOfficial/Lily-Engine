package engine.backend.game;

class Room extends FlxGroup {
	public static var instance:Room;
	public var scene:Scene;

	#if FEATURE_HSCRIPT
	public var scripts:ScriptPack = new ScriptPack("RoomScripts");
	#end

	public function new() {
		super();
		instance = this;
	}

	public function loadRoom(roomName:String, isFromLoad:Bool = false):Void {
		var tscnPath = '${Flags.roomFolder}$roomName.tscn';

		if (!Assets.exists(tscnPath)) {
			trace("Failed to load room. TSCN does not exist for: " + roomName);
			return;
		}

		if (scene != null) {
			remove(scene, true);
			scene.destroy();
			scene = null;
		}

		#if FEATURE_HSCRIPT
		if (scripts != null) {
			scripts.destroy();
		}
		scripts = new ScriptPack("RoomScripts");
		#end

		scene = new Scene();
		scene.applyScript.add(onNodeScriptApply);

		scene.load(Assets.getPath(tscnPath));
		add(scene);

		spawnParty(0, 0, 0, isFromLoad);

		Game.save.room = roomName;
		#if FEATURE_HSCRIPT
		scripts.setParent(this);
		scripts.load();
		scripts.call("onRoomLoaded", [roomName]);
		#end
	}

	private function onNodeScriptApply(node:Node, hxScriptPath:String):Void {
		#if FEATURE_HSCRIPT
		if (hxScriptPath.startsWith("script/")) {
			hxScriptPath = hxScriptPath.replace("script/", Flags.scriptFolder);
		}
		if (hxScriptPath.startsWith("assets/")) {
			hxScriptPath = hxScriptPath.replace("assets/", "");
		}
		if (Assets.exists(hxScriptPath)) {
			var script = Script.create(hxScriptPath);
			script.set("obj", node);
			if (TscnParser.scriptPropertiesMap.exists(node)) {
				var props:Map<String, Dynamic> = TscnParser.scriptPropertiesMap.get(node);
				for (key in props.keys()) {
					script.set(key, props.get(key));
				}
			}
			scripts.add(script);
		}
		#end
	}

	public function spawnParty(spawnX:Float, spawnY:Float, spawnZ:Int, isFromLoad:Bool = false):Void {
		var party = Game.save.party;
		if (party == null || party.length == 0)
			party = ["lacie"];

		for (f in Game.party) {
			f.kill();
			f.destroy();
		}
		Game.party = [];
		Game.baseRoom.clearFollowers();

		var targetNode:Dynamic = scene.getNode("Main");
		if (targetNode == null)
			targetNode = scene.root;

		if (Std.isOfType(targetNode, Node2D)) {
			var n2d:Node2D = cast targetNode;
			n2d.ySort = true;
		}

		var prev:Character = null;
		for (i in 0...party.length) {
			var member:Character;
			if (i == 0)
				member = new Player(spawnX, spawnY, spawnZ, party[i]);
			else
				member = new Character(spawnX, spawnY, spawnZ, party[i]);

			member.loadEntity(party[i]);

			targetNode.add(member);
			Game.party.push(member);

			if (prev != null)
				Game.baseRoom.addFollower(member, prev, 12, true);

			prev = member;
		}

		var savePos = Game.save.partyPositions;
		for (i in 0...Game.party.length) {
			var member = Game.party[i];
			if (isFromLoad && savePos != null) {
				member.x = savePos[i].x;
				member.y = savePos[i].y;
			}
			member.positionHistory = [];
		}

		Game.baseRoom.camGame.zoom = 3;
		Game.baseRoom.camGame.follow(Game.party[0], NO_DEAD_ZONE, 1);
		Game.baseRoom.camGame.focusOn(Game.party[0].getPosition());
	}

	public function followPath2D(path2dnodepath:String, objnode:Dynamic, speed:Float = 150, loop:Bool = false, ?onFinish:Dynamic):Void {
		var pathNode:PathFollow2D = Game.room.scene.getObject(path2dnodepath, PathFollow2D);
		if (pathNode != null) {
			pathNode.speed = speed;
			pathNode.loop = loop;
			pathNode.paused = false;

			var char:Character = Std.isOfType(objnode, Character) ? cast objnode : null;
			if (char != null) {
				char.isFollowingPath = true;
			}

			pathNode.onFinish = function() {
				if (char != null)
					char.isFollowingPath = false;

				if (onFinish != null && Reflect.isFunction(onFinish)) {
					Reflect.callMethod(null, onFinish, []);
				}
			};

			pathNode.follow(objnode);
		} else {
			FlxG.log.error('followPath2D failed: PathFollow2D node not found at path "${path2dnodepath}"');
		}
	}

	override public function update(elapsed:Float):Void {
		#if FEATURE_HSCRIPT
		scripts?.call("update", [elapsed]);
		#end

		super.update(elapsed);

		Game.save.partyPositions = [];
		for (member in Game.party) {
			Game.save.partyPositions.push({x: member.x, y: member.y});
		}

		#if FEATURE_HSCRIPT
		scripts?.call("postUpdate", [elapsed]);
		#end
	}

	override public function destroy():Void {
		#if FEATURE_HSCRIPT
		if (scripts != null) {
			scripts.destroy();
			scripts = null;
		}
		#end

		if (scene != null) {
			scene.destroy();
			scene = null;
		}

		super.destroy();
	}
}
