package engine.backend.game;

typedef SortData = {
	var sortY:Float;
	var treeIndex:Int;
	var z:Int;
	var isDynamic:Bool;
	var isFlat:Bool;
}

class RoomManager extends FlxTypedGroup<FlxSprite> {
	public static var instance:RoomManager;
	public static var currentRoomName:String;

	public var entities:Map<String, WorldObject>;
	public var characters:Map<String, CharacterEntity>;
	public var solids:FlxTypedGroup<CollisionBlock>;
	public var partyMembers:Array<Follower>;
	public var spawnPoints:Map<String, {x:Float, y:Float, dir:String}>;
	public var roomEvents:Array<{id:String, rect:FlxRect, trigger:String}>;
	public var quitObjects:Map<WorldObject, {room:String, spawnId:Int}>;
	public var triggers:Array<{obj:WorldObject, needsPress:Bool}>;
	public var sortMap:Map<FlxSprite, SortData>;
	public var layerIndices:Map<String, Int>;
	public var player:Player;
	public var roomZoom:Float = 1.0;
	public var info:Map<String, Dynamic>;

	private var interactCooldown:Float = 0;
	private var wasInteractPressed:Bool = false;
	private var previousOverlaps:Map<String, Bool>;

	#if FEATURE_HSCRIPT
	public var scripts:ScriptPack;
	public var entityScripts:Map<String, Script>;
	#end
	public var mainState:Dynamic = null;

	public function new(?mainState:Dynamic) {
		super();
		instance = this;
		entities = new Map();
		characters = new Map();
		solids = new FlxTypedGroup<CollisionBlock>();
		partyMembers = [];
		spawnPoints = new Map();
		roomEvents = [];
		quitObjects = new Map();
		triggers = [];
		sortMap = new Map();
		layerIndices = new Map();
		info = new Map<String, Dynamic>();
		previousOverlaps = new Map<String, Bool>();

		#if FEATURE_HSCRIPT
		scripts = new ScriptPack("RoomScripts");
		entityScripts = new Map<String, Script>();
		#end
		this.mainState = mainState;
	}

	public function loadRoom(filePath:String, spawnId:Int = 0):Void {
		var tmxPath = "rooms/" + filePath + ".tmx";
		if (LilyAssets.fileExists(tmxPath)) {
			TmxParser.read(this, LilyAssets.getTextFromFile(tmxPath), filePath, spawnId);
		} else {
			FlxG.log.error("Failed to load map. File does not exist: " + tmxPath);
			return;
		}

		#if FEATURE_HSCRIPT
		injectScriptVariables();
		scripts.setParent(engine.states.BaseRoom.instance);
		Game.instance.bindToScript(scripts);
		if (scripts != null)
			scripts.call("create");
		#end
	}

	public function initPlayerState(camGame:FlxCamera, isFromLoad:Bool):Void {
		if (player == null)
			return;

		var savePos = Game.saveData.partyPositions;
		if (isFromLoad && savePos != null && savePos.length > 0) {
			player.x = savePos[0].x;
			player.y = savePos[0].y;
		} else {
			Game.saveData.partyPositions = [{x: player.x, y: player.y}];
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

	public function getObject<T>(objName:String, objClass:Class<T>):T {
		var obj = entities.get(objName);
		return (obj != null && Std.isOfType(obj, objClass)) ? cast obj : null;
	}

	public function getPartyMember(index:Int):CharacterEntity {
		if (index == 0)
			return player;
		return (index > 0 && index <= partyMembers.length) ? partyMembers[index - 1] : null;
	}

	public function spawnParty(px:Float, py:Float, pz:Int, ?node:Access):Void {
		var party = Game.saveData.party;
		if (party == null || party.length == 0)
			party = ["lacie"];

		if (player != null) {
			remove(player);
			entities.remove(player.xmlName);
			characters.remove(player.xmlName);
			sortMap.remove(player);
		}
		for (f in partyMembers) {
			remove(f);
			entities.remove(f.xmlName);
			characters.remove(f.xmlName);
			sortMap.remove(f);
		}
		partyMembers = [];

		player = new Player(px, py, pz, (node != null && node.has.name) ? node.att.name : "player");
		player.loadEntity("", "characters/" + party[0]);
		addEntity(player);
		characters.set(player.xmlName, player);
		sortMap.set(player, {
			sortY: 0,
			treeIndex: 1000000,
			z: pz,
			isDynamic: true,
			isFlat: false
		});

		var prev:CharacterEntity = player;
		for (i in 1...party.length) {
			var member = new Follower(px, py, pz, party[i]);
			member.loadEntity("", "characters/" + party[i]);
			member.target = prev;
			addEntity(member);
			characters.set(member.xmlName, member);
			sortMap.set(member, {
				sortY: 0,
				treeIndex: 1000000 + i,
				z: pz,
				isDynamic: true,
				isFlat: false
			});
			partyMembers.push(member);
			prev = member;
		}
	}

	public function addEntity(obj:WorldObject):Void {
		add(obj);
		entities.set(obj.xmlName, obj);
	}

	public function changeLayer(obj:Dynamic, layerName:String):Void {
		var targetSpr:FlxSprite = Std.isOfType(obj,
			FlxSprite) ? cast obj : (Std.isOfType(obj, String) ? (characters.exists(obj) ? characters.get(obj) : entities.get(obj)) : null);

		if (targetSpr != null && layerName != null) {
			var ln = layerName.toLowerCase();
			if (layerIndices.exists(ln) && sortMap.exists(targetSpr)) {
				sortMap.get(targetSpr).z = layerIndices.get(ln);
			} else {
				FlxG.log.error('changeLayer Failed: Layer "$layerName" does not exist!');
			}
		}
	}

	public function injectScriptVariables():Void {
		#if FEATURE_HSCRIPT
		if (scripts == null)
			return;

		function set(name:String, thing:Dynamic) {
			scripts.set(name, thing);
		}
		set("room", RoomManager.instance);
		set("player", RoomManager.instance.player);
		set("parent", engine.states.BaseRoom.instance);
		set("changeLayer", RoomManager.instance.changeLayer);
		set("addItem", Game.itemsData.addItem);
		set("removeItem", Game.itemsData.removeItem);
		set("getOwnedAmount", Game.itemsData.getOwnedAmount);
		set("lockPlayer", function(locked:Bool = true) {
			if (RoomManager.instance.player != null) {
				RoomManager.instance.player.canMove = !locked;
				if (locked)
					RoomManager.instance.player.velocity.set(0, 0);
			}
		});

		set("wait", function(time:Float, cb:Dynamic) {
			new FlxTimer().start(time, function(_) {
				if (cb != null)
					Reflect.callMethod(null, cb, []);
			});
		});

		set("walkEntity", function(id:String, x:Float, y:Float, speed:Float, cb:Dynamic) {
			var ent:engine.objects.CharacterEntity = null;

			if (id == "player" && RoomManager.instance.player != null)
				ent = RoomManager.instance.player;
			else if (RoomManager.instance.characters.exists(id))
				ent = RoomManager.instance.characters.get(id);
			else if (RoomManager.instance.entities.exists(id) && Std.isOfType(RoomManager.instance.entities.get(id), CharacterEntity)) {
				ent = cast RoomManager.instance.entities.get(id);
			}

			if (ent != null) {
				ent.walkTo(x, y, speed, function() {
					if (cb != null)
						cb();
				});
			} else {
				FlxG.log.warn('walkEntity: Character "' + id + '" not found or is not a CharacterEntity.');
				if (cb != null)
					cb();
			}
		});

		set("faceEntity", function(id:String, dir:String) {
			var ent:CharacterEntity = null;

			if (id == "player" && RoomManager.instance.player != null)
				ent = RoomManager.instance.player;
			else if (RoomManager.instance.characters.exists(id))
				ent = RoomManager.instance.characters.get(id);
			else if (RoomManager.instance.entities.exists(id) && Std.isOfType(RoomManager.instance.entities.get(id), CharacterEntity)) {
				ent = cast RoomManager.instance.entities.get(id);
			}

			if (ent != null) {
				var d = CharacterEntity.FacingDirection.DOWN;
				switch (dir.toLowerCase()) {
					case "up":
						d = UP;
					case "down":
						d = DOWN;
					case "left":
						d = LEFT;
					case "right":
						d = RIGHT;
				}
				ent.currentFacing = d;
				ent.updateAnimations();
			}
		});

		set("setCameraTarget", function(id:String) {
			var target:FlxObject = null;

			if (id == "player" && RoomManager.instance.player != null)
				target = RoomManager.instance.player;
			else if (RoomManager.instance.characters.exists(id))
				target = RoomManager.instance.characters.get(id);
			else if (RoomManager.instance.entities.exists(id))
				target = RoomManager.instance.entities.get(id);

			if (target != null) {
				BaseRoom.instance.followTheObject(target, "NO_DEAD_ZONE", 1);
			} else {
				FlxG.log.warn('setCameraTarget: Target "' + id + '" not found.');
			}
		});

		for (key => val in RoomManager.instance.entities)
			set(key, val);
		for (key => val in RoomManager.instance.characters)
			if (!RoomManager.instance.entities.exists(key))
				set(key, val);
		#end
	}

	override public function update(elapsed:Float):Void {
		#if FEATURE_HSCRIPT
		if (scripts != null)
			scripts.call("update", [elapsed]);
		#end

		super.update(elapsed);
		if (interactCooldown > 0)
			interactCooldown -= elapsed;

		if (player != null && player.canMove) {
			FlxG.collide(player, solids);
			for (entity in entities) {
				if (entity != player && entity.solidCollision)
					FlxG.collide(player, entity);
			}

			Game.saveData.partyPositions = [{x: player.x, y: player.y}];
			for (member in partyMembers)
				Game.saveData.partyPositions.push({x: member.x, y: member.y});

			var playerHitbox = player.getCollisionBox();
			var isInteractPressedNow = Controls.ACCEPT;
			var switchedRoom = false;

			var currentOverlaps = new Map<String, Bool>();
			for (t in triggers) {
				var tBox = t.obj.getCollisionBox();
				var isOver = playerHitbox.overlaps(tBox);
				var isOverInteraction = player.getInteractionBox().overlaps(tBox);

				if (isOver && !t.needsPress || isOverInteraction && t.needsPress) {
					currentOverlaps.set(t.obj.xmlName, true);
					var justEntered = !previousOverlaps.exists(t.obj.xmlName);

					if (!t.needsPress && justEntered) {
						#if FEATURE_HSCRIPT
						var s = entityScripts.get(t.obj.xmlName);
						if (s != null)
							s.call("onInteracted", [t.obj.xmlName, t.obj.tiledID, "Trigger", t.obj.tiledProps]);
						#end
						if (t.obj.dialogPath != "")
							Game.instance.playDialogue(t.obj.dialogPath, "start");
					} else if (t.needsPress && isInteractPressedNow && !wasInteractPressed && interactCooldown <= 0) {
						interactCooldown = 0.2;
						#if FEATURE_HSCRIPT
						var s = entityScripts.get(t.obj.xmlName);
						if (s != null)
							s.call("onInteracted", [t.obj.xmlName, t.obj.tiledID, "Trigger", t.obj.tiledProps]);
						#end
						if (t.obj.dialogPath != "")
							Game.instance.playDialogue(t.obj.dialogPath, "start");
					}
				}
				tBox.put();
			}
			previousOverlaps = currentOverlaps;

			if (isInteractPressedNow && !wasInteractPressed && interactCooldown <= 0) {
				for (quitObj => quitData in quitObjects) {
					if (playerHitbox.overlaps(quitObj.getCollisionBox())) {
						StateBackend.switchState(new engine.states.BaseRoom(quitData.room, quitData.spawnId, false));
						switchedRoom = true;
						break;
					}
				}

				if (!switchedRoom) {
					var box = player.getInteractionBox();
					for (entity in entities) {
						if (entity != player && entity.interactable && box.overlaps(entity.getCollisionBox())) {
							interactCooldown = 0.2;
							#if FEATURE_HSCRIPT
							var s = entityScripts.get(entity.xmlName);
							if (s != null)
								s.call("onInteracted", [
									entity.xmlName,
									entity.tiledID,
									Std.isOfType(entity, CharacterEntity) ? "Entity" : "Object",
									entity.tiledProps
								]);
							#end
							if (entity.dialogPath != "")
								Game.instance.playDialogue(entity.dialogPath, "start");
							break;
						}
					}
					box.put();
				}
			}
			wasInteractPressed = isInteractPressedNow;
			playerHitbox.put();
		}

		sort(depthSortCallback);

		#if FEATURE_HSCRIPT
		if (scripts != null)
			scripts.call("postUpdate", [elapsed]);
		#end
	}

	private function depthSortCallback(order:Int, obj1:FlxSprite, obj2:FlxSprite):Int {
		var d1 = sortMap.get(obj1);
		var d2 = sortMap.get(obj2);

		var z1 = d1 != null ? d1.z : (Std.isOfType(obj1, WorldObject) ? (cast obj1 : WorldObject).z : 1);
		var z2 = d2 != null ? d2.z : (Std.isOfType(obj2, WorldObject) ? (cast obj2 : WorldObject).z : 1);

		if (z1 != z2)
			return FlxSort.byValues(order, z1, z2);

		var b1 = obj1.y - obj1.offset.y + (obj1.frameHeight != 0 ? obj1.frameHeight : obj1.height);
		var b2 = obj2.y - obj2.offset.y + (obj2.frameHeight != 0 ? obj2.frameHeight : obj2.height);

		if (b1 != b2)
			return FlxSort.byValues(order, b1, b2);

		return FlxSort.byValues(order, d1 != null ? d1.treeIndex : 0, d2 != null ? d2.treeIndex : 0);
	}

	override public function destroy():Void {
		#if FEATURE_HSCRIPT
		if (scripts != null) {
			scripts.destroy();
			scripts = null;
		}
		if (entityScripts != null) {
			entityScripts.clear();
			entityScripts = null;
		}
		#end
		currentRoomName = null;
		if (layerIndices != null) {
			layerIndices.clear();
			layerIndices = null;
		}
		if (quitObjects != null) {
			quitObjects.clear();
			quitObjects = null;
		}
		triggers = null;
		previousOverlaps = null;
		super.destroy();
	}
}
