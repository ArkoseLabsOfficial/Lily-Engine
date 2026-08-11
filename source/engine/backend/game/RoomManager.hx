package engine.backend.game;

class RoomManager extends FlxGroup {
	public static var instance:RoomManager;
	public static var currentRoomName:String;

	public var partyMembers:Array<Character> = [];

	public var currentScene:Scene;

	public var player:Player;
	public var roomZoom:Float = 3.0;

	public var info:Map<String, Dynamic> = new Map();

	#if FEATURE_HSCRIPT
	public var scripts:ScriptPack = new ScriptPack("RoomScripts");
	#end

	public var mainState:Dynamic = null;

	public function new(?mainState:Dynamic) {
		super();
		instance = this;
		this.mainState = mainState;
	}

	public function loadRoom(filePath:String):Void {
		var tscnPath = Flags.roomFolder + filePath + ".tscn";

		if (!LilyAssets.fileExists(tscnPath)) {
			FlxG.log.error("Failed to load map. TSCN does not exist for: " + filePath);
			return;
		}

		RoomManager.currentRoomName = filePath;

		if (currentScene != null) {
			remove(currentScene, true);
			currentScene.destroy();
		}

		#if FEATURE_HSCRIPT
		if (scripts != null) {
			scripts.destroy();
		}
		scripts = new engine.scripting.ScriptPack("RoomScripts");
		#end

		currentScene = new Scene();
		currentScene.applyScript.add(onNodeScriptApply);

		currentScene.load(LilyAssets.getPath(tscnPath));
		add(currentScene);

		spawnParty(0, 0, 0);

		if (BaseRoom.instance != null && BaseRoom.instance.camGame != null) {
			initPlayerState(BaseRoom.instance.camGame, false);
		}

		#if FEATURE_HSCRIPT
		injectScriptVariables();
		scripts.setParent(BaseRoom.instance);
		scripts.load();
		scripts.call("create");
		#end
	}

	private function onNodeScriptApply(node:Node, hxScriptPath:String):Void {
		#if FEATURE_HSCRIPT
		if (hxScriptPath.startsWith("script/")) {
			hxScriptPath = hxScriptPath.replace("script/", "scripts/");
		}
		if (hxScriptPath.startsWith("assets/")) {
			hxScriptPath = hxScriptPath.replace("assets/", "");
		}
		if (LilyAssets.fileExists(hxScriptPath)) {
			var script = engine.scripting.Script.create(hxScriptPath);
			script.set("this", node);
			script.set("obj", node);
			if (TscnParser.scriptPropertiesMap.exists(node)) {
				var props:Map<String, Dynamic> = TscnParser.scriptPropertiesMap.get(node);
				for (key in props.keys()) {
					script.set(key, props.get(key));
				}
			}
			scripts.add(script);
			try {
				Reflect.setField(node, "__script__", script);
			} catch (e:Dynamic) {}
		}
		scripts.set(node.nodeName, node);
		#end
	}

	public function initPlayerState(camGame:FlxCamera, isFromLoad:Bool):Void {
		if (player == null)
			return;

		var savePos = Game.save.partyPositions;
		if (isFromLoad && savePos != null && savePos.length > 0) {
			player.x = savePos[0].x;
			player.y = savePos[0].y;
		} else {
			Game.save.partyPositions = [{x: player.x, y: player.y}];
		}
		player.positionHistory = [];

		for (i in 0...partyMembers.length) {
			var member = partyMembers[i];
			if (isFromLoad && savePos != null && i + 1 < savePos.length) {
				member.x = savePos[i + 1].x;
				member.y = savePos[i + 1].y;
			} else {
				member.x = player.x;
				member.y = player.y;
			}
			member.positionHistory = [];
		}

		camGame.zoom = roomZoom;
		camGame.follow(player, NO_DEAD_ZONE, 1);
	}

	public function getNodesOfType<T>(classType:Class<T>, ?startGroup:Dynamic):Array<T> {
		var results:Array<T> = [];
		var grp:Dynamic = startGroup != null ? startGroup : currentScene;
		if (grp == null)
			return results;

		function search(g:Dynamic) {
			var members:Array<Dynamic> = null;

			if (Std.isOfType(g, FlxGroup)) {
				members = (cast g : FlxGroup).members;
			} else if (Std.isOfType(g, FlxSpriteGroup)) {
				members = (cast g : FlxSpriteGroup).group.members;
			}

			if (members != null) {
				for (m in members) {
					if (m == null)
						continue;

					if (Std.isOfType(m, classType)) {
						results.push(cast m);
					}

					if (Std.isOfType(m, FlxGroup) || Std.isOfType(m, FlxSpriteGroup)) {
						search(m);
					}
				}
			}
		}

		search(grp);
		return results;
	}

	public function getObject<T>(objName:String, objClass:Class<T>):T {
		var node = currentScene.getNode(objName);
		return (node != null && Std.isOfType(node, objClass)) ? cast node : null;
	}

	public function getPartyMember(index:Int):Character {
		if (index == 0)
			return player;
		return (index > 0 && index <= partyMembers.length) ? partyMembers[index - 1] : null;
	}

	public function spawnParty(px:Float, py:Float, pz:Int, ?nodeName:String):Void {
		var party = Game.save.party;
		if (party == null || party.length == 0)
			party = ["lacie"];

		if (player != null) {
			player.kill();
			player.destroy();
		}
		for (f in partyMembers) {
			f.kill();
			f.destroy();
		}
		partyMembers = [];

		if (BaseRoom.instance != null) {
			BaseRoom.instance.clearFollowers();
		}

		var targetNode:Dynamic = currentScene.getNode("Main");
		if (targetNode == null)
			targetNode = currentScene.root;

		if (Std.isOfType(targetNode, godot.nodes.Node2D)) {
			var n2d:Node2D = cast targetNode;
			n2d.ySort = true;
		}

		player = new Player(px, py, pz, nodeName != null ? nodeName : "player");
		player.loadEntity(party[0]);
		targetNode.add(player);

		var prev:Character = player;
		for (i in 1...party.length) {
			var member = new Character(px, py, pz, party[i]);
			member.loadEntity(party[i]);

			targetNode.add(member);
			partyMembers.push(member);

			if (BaseRoom.instance != null) {
				BaseRoom.instance.addFollower(member, prev, 12, true);
			}
			prev = member;
		}

		if (BaseRoom.instance != null && BaseRoom.instance.camGame != null) {
			BaseRoom.instance.camGame.focusOn(player.getPosition());
		}
	}

	public function changeLayer(obj:Dynamic, layerName:String):Void {
		var targetNode:Node = null;

		if (Std.isOfType(obj, Node)) {
			targetNode = cast obj;
		} else if (Std.isOfType(obj, String)) {
			targetNode = currentScene.getNode(cast(obj, String));
		}

		if (targetNode == null) {
			FlxG.log.warn('RoomManager.changeLayer: Object is null or not a valid Node.');
			return;
		}

		var newParent:Node = currentScene.getNode(layerName);
		if (newParent == null) {
			FlxG.log.warn('RoomManager.changeLayer: Layer "$layerName" not found in scene.');
			return;
		}

		var savedX:Float = targetNode.x;
		var savedY:Float = targetNode.y;

		var oldParent:Node = targetNode.parentNode;
		if (oldParent != null) {
			oldParent.removeChild(targetNode.nodeName, targetNode);
		}

		newParent.addChild(targetNode.nodeName, targetNode);

		targetNode.x = savedX;
		targetNode.y = savedY;
	}

	public function followPath2D(path2dnodepath:String, objnode:Dynamic, speed:Float = 150, loop:Bool = false, ?onFinish:Dynamic):Void {
		var pathNode:PathFollow2D = getObject(path2dnodepath, PathFollow2D);
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

	public function injectScriptVariables():Void {
		#if FEATURE_HSCRIPT
		if (scripts == null)
			return;

		Game.instance.bindToScript(scripts);

		var allNodes = getNodesOfType(FlxBasic);
		for (node in allNodes) {
			if (Reflect.hasField(node, "nodeName")) {
				var n:String = Reflect.field(node, "nodeName");
				if (n != null && n != "")
					scripts.set(n, node);
			} else if (Reflect.hasField(node, "xmlName")) {
				var n:String = Reflect.field(node, "xmlName");
				if (n != null && n != "")
					scripts.set(n, node);
			}
		}
		#end
	}

	override public function update(elapsed:Float):Void {
		#if FEATURE_HSCRIPT
		scripts?.call("update", [elapsed]);
		#end

		super.update(elapsed);

		if (player != null && player.canMove) {
			Game.save.partyPositions = [{x: player.x, y: player.y}];
			for (member in partyMembers)
				Game.save.partyPositions.push({x: member.x, y: member.y});
		}

		#if FEATURE_HSCRIPT
		scripts?.call("postUpdate", [elapsed]);
		#end
	}

	override public function destroy():Void {
		TscnParser.scriptPropertiesMap = new haxe.ds.ObjectMap();

		#if FEATURE_HSCRIPT
		if (scripts != null) {
			scripts.destroy();
			scripts = null;
		}
		#end

		if (currentScene != null) {
			currentScene.destroy();
			currentScene = null;
		}

		currentRoomName = null;
		super.destroy();
	}
}
