package engine.backend.parser;

typedef TilesetData = {
	var path:String;
	var rx:Int;
	var ry:Int;
	var tw:Int;
	var th:Int;
}

typedef TmxAnimData = {
	var frames:Array<Int>;
	var fps:Float;
}

typedef SortData = {
	var sortY:Float;
	var treeIndex:Int;
	var z:Int;
	var isDynamic:Bool;
	var isFlat:Bool;
}

typedef ScriptDef = {
	var target:Dynamic;
	var scriptName:String;
	var objProps:Map<String, Int>;
}

typedef SpawnPoint = {
	var x:Float;
	var y:Float;
	var dir:String;
}

typedef TmxMapProps = {
	var zoom:Null<Float>;
	var location:String;
	var spawnPlayer:Bool;
	var script:String;
	var customStrings:Map<String, String>;
}

typedef TmxEntityProps = {
	var isSolid:Bool;
	var isInteractable:Bool;
	var isFlat:Bool;
	var script:String;
	var character:String;
	var targetRoom:String;
	var exitId:Int;
	var spawnId:Int;
	var animName:String;
	var animLoop:Bool;
	var customStrings:Map<String, String>;
	var customObjects:Map<String, Int>;
}

class TmxParser {
	static inline var FLAG_H:Float = 2147483648.0;
	static inline var FLAG_V:Float = 1073741824.0;
	static inline var FLAG_D:Float = 536870912.0;

	public static function read(room:RoomManager, rawData:String, fileName:String, targetSpawnId:Int = 0):Void {
		var parsed:Xml = null;
		try {
			if (rawData.charCodeAt(0) == 0xFEFF)
				rawData = rawData.substr(1);
			parsed = Xml.parse(rawData).firstElement();
		} catch (e:Dynamic) {
			FlxG.log.error('TMX Parse Error in $fileName: $e');
			return;
		}
		if (parsed == null)
			return;

		var map = new Access(parsed);
		RoomManager.currentRoomName = fileName;
		var mapProps = extractMapProps(map);

		if (mapProps.zoom != null)
			room.roomZoom = mapProps.zoom;
		if (mapProps.location != null)
			Game.saveData.location = mapProps.location;

		#if FEATURE_HSCRIPT
		var scriptPath = mapProps.script != null ? mapProps.script : (fileName.lastIndexOf(".") != -1 ? fileName.substr(0,
			fileName.lastIndexOf(".")) : fileName);
		if (!StringTools.endsWith(scriptPath, ".hx"))
			scriptPath += ".hx";
		if (mapProps.script != null || LilyAssets.fileExists("scripts/" + scriptPath)) {
			var roomScript = Script.create("scripts/" + scriptPath);
			room.scripts.add(roomScript);
			roomScript.load();
		}
		#end

		var tileWidth = Std.parseInt(map.att.tilewidth);
		var tileHeight = Std.parseInt(map.att.tileheight);
		var mapWidth = Std.parseInt(map.att.width);
		var mapHeight = Std.parseInt(map.att.height);

		if (BaseRoom.instance != null && BaseRoom.instance.camGame != null) {
			var pxWidth = mapWidth * tileWidth;
			var pxHeight = mapHeight * tileHeight;
			BaseRoom.instance.camGame.setScrollBoundsRect(0, 0, pxWidth, pxHeight, true);
		}

		var tilesets = new Map<Int, TilesetData>();
		var animations = new Map<Int, TmxAnimData>();

		for (tsNode in map.nodes.tileset) {
			var firstGid = Std.parseInt(tsNode.att.firstgid);
			if (tsNode.hasNode.image) {
				var tsTw = tsNode.has.tilewidth ? Std.parseInt(tsNode.att.tilewidth) : tileWidth;
				var tsTh = tsNode.has.tileheight ? Std.parseInt(tsNode.att.tileheight) : tileHeight;
				var cols = tsNode.has.columns ? Std.parseInt(tsNode.att.columns) : Std.int(Std.parseInt(tsNode.node.image.att.width) / tsTw);
				var count = tsNode.has.tilecount ? Std.parseInt(tsNode.att.tilecount) : 0;
				var src = tsNode.node.image.att.source;

				for (i in 0...count) {
					tilesets.set(firstGid + i, {
						path: src,
						rx: (cols > 0) ? (i % cols) * tsTw : 0,
						ry: (cols > 0) ? Std.int(i / cols) * tsTh : 0,
						tw: tsTw,
						th: tsTh
					});
				}
			}
			if (tsNode.hasNode.tile) {
				for (tileNode in tsNode.nodes.tile) {
					var id = Std.parseInt(tileNode.att.id);
					if (tileNode.hasNode.image) {
						tilesets.set(firstGid + id, {
							path: tileNode.node.image.att.source,
							rx: 0,
							ry: 0,
							tw: Std.parseInt(tileNode.node.image.att.width),
							th: Std.parseInt(tileNode.node.image.att.height)
						});
					}
					if (tileNode.hasNode.animation) {
						var frames = [];
						var totalDur = 0;
						for (f in tileNode.node.animation.nodes.frame) {
							frames.push(Std.parseInt(f.att.tileid));
							totalDur += Std.parseInt(f.att.duration);
						}
						animations.set(firstGid + id, {frames: frames, fps: frames.length > 0 ? (1000.0 / (totalDur / frames.length)) : 10});
					}
				}
			}
		}

		var currentZIndex = 0, currentTreeIndex = 0, playerZIndex = 1;
		var hasSpawn = false;
		var objectIdMap = new Map<Int, FlxSprite>();
		var pendingScripts = new Array<ScriptDef>();

		for (node in map.elements) {
			if (node.name == "layer") {
				var zIndex = getLayerZ(node, currentZIndex);
				var lName = node.has.name ? node.att.name.toLowerCase() : "";
				if (lName != "")
					room.layerIndices.set(lName, zIndex);

				var layerVisible = !node.has.visible || (node.att.visible != "0" && node.att.visible != "false");
				var isAutoCollision = checkAutoCollision(node);

				if (node.hasNode.data) {
					var csv = "";
					for (child in node.node.data.x.iterator())
						if (child.nodeType == Xml.PCData || child.nodeType == Xml.CData)
							csv += child.nodeValue;
					var tokens = csv.split(",");

					for (i in 0...tokens.length) {
						var raw = Std.parseFloat(StringTools.trim(tokens[i]));
						if (raw == 0 || Math.isNaN(raw))
							continue;

						var hFlip = raw >= FLAG_H;
						if (hFlip)
							raw -= FLAG_H;
						var vFlip = raw >= FLAG_V;
						if (vFlip)
							raw -= FLAG_V;
						var dFlip = raw >= FLAG_D;
						if (dFlip)
							raw -= FLAG_D;
						var gid = Std.int(raw);
						var ts = tilesets.get(gid);

						if (ts != null) {
							var tx = (i % mapWidth) * tileWidth;
							var ty = Std.int(i / mapWidth) * tileHeight;
							if (ts.th > tileHeight)
								ty -= (ts.th - tileHeight);

							var tile = new WorldObject(tx, ty, zIndex, "tile_" + tx + "_" + ty);
							tile.loadGraphic(LilyAssets.image(cleanAssetPath(ts.path)), true, ts.tw, ts.th);

							var anim = animations.get(gid);
							if (anim != null) {
								tile.animation.add("play", anim.frames, anim.fps, true);
								tile.animation.play("play");
							} else if (tile.graphic != null) {
								var sheetColumns = Std.int(tile.graphic.width / ts.tw);
								if (sheetColumns > 0)
									tile.animation.frameIndex = (Std.int(ts.ry / ts.th) * sheetColumns) + Std.int(ts.rx / ts.tw);
							}

							applyTmxTransform(tile, hFlip, vFlip, dFlip, 0);
							setupObject(room, tile, layerVisible, isAutoCollision, zIndex, currentTreeIndex++, true);
						}
					}
				}
				currentZIndex++;
			} else if (node.name == "objectgroup") {
				var zIndex = getLayerZ(node, currentZIndex);
				var gName = node.has.name ? node.att.name.toLowerCase() : "";
				var gClass = node.x.exists("class") ? node.x.get("class").toLowerCase() : "";

				if (gName != "")
					room.layerIndices.set(gName, zIndex);
				if (gClass == "player" || gName == "player" || gName == "characters")
					playerZIndex = zIndex;

				var groupVisible = !node.has.visible || (node.att.visible != "0" && node.att.visible != "false");
				var groupPropsRaw = extractRawProps(node);

				for (objNode in node.nodes.object) {
					var objVisible = !objNode.has.visible || (objNode.att.visible != "0" && objNode.att.visible != "false");
					var finalVis = groupVisible && objVisible;

					var type = objNode.has.type ? objNode.att.type : (objNode.x.exists("class") ? objNode.x.get("class") : "");
					var ow = objNode.has.width ? Std.parseFloat(objNode.att.width) : 32;
					var oh = objNode.has.height ? Std.parseFloat(objNode.att.height) : 32;
					var objId = objNode.has.id ? Std.parseInt(objNode.att.id) : 0;
					var name = objNode.has.name ? objNode.att.name : "obj";

					var xmlRot = objNode.has.rotation ? Std.parseFloat(objNode.att.rotation) : 0;
					var rad = xmlRot * Math.PI / 180;
					var realX = (objNode.has.x ? Std.parseFloat(objNode.att.x) : 0)
						+ ((ow / 2) * Math.cos(rad) - (objNode.has.gid ? (-oh / 2) : (oh / 2)) * Math.sin(rad))
						- (ow / 2);
					var realY = (objNode.has.y ? Std.parseFloat(objNode.att.y) : 0)
						+ ((ow / 2) * Math.sin(rad) + (objNode.has.gid ? (-oh / 2) : (oh / 2)) * Math.cos(rad))
						- (oh / 2);

					var props = extractEntityProps(objNode, groupPropsRaw, name);
					var baseObj:FlxSprite = null;
					var addToEntities = true;

					switch (type) {
						case "SpawnPoint":
							hasSpawn = true;
							room.spawnPoints.set("spawn_" + props.spawnId, {x: realX + (ow / 2), y: realY + (oh / 2), dir: "down"});
							addToEntities = false;

						case "Collision":
							baseObj = new CollisionBlock(realX, realY, Std.int(ow), Std.int(oh));
							room.solids.add(cast baseObj);
							addToEntities = false;

						case "Exit":
							var exitObj = new WorldObject(realX, realY, zIndex, name);
							exitObj.tiledID = objId;
							exitObj.makeGraphic(Std.int(ow), Std.int(oh), 0x8000FF00);
							room.quitObjects.set(exitObj, {room: props.targetRoom, spawnId: props.exitId});
							baseObj = exitObj;

						case "Trigger":
							var trigger = new WorldObject(realX, realY, zIndex, name);
							trigger.tiledID = objId;
							trigger.makeGraphic(Std.int(ow), Std.int(oh), 0x00000000);
							trigger.applyProperties(props.customStrings);
							var nPress = props.customStrings.get("needsPress") == "true" || props.customStrings.get("needsPress") == "1";
							room.triggers.push({obj: trigger, needsPress: nPress});
							baseObj = trigger;

						case "Entity":
							var spr = new CharacterEntity(realX + (ow / 2), objNode.has.gid ? realY + oh : realY, zIndex, name);
							spr.tiledID = objId;
							spr.loadEntity("", "characters/" + props.character);
							if (objNode.has.gid) {
								var raw = Std.parseFloat(objNode.att.gid);
								if (raw >= FLAG_H)
									spr.flipX = true;
								if ((raw >= FLAG_H ? raw - FLAG_H : raw) >= FLAG_V)
									spr.flipY = true;
							}
							spr.angle = xmlRot;
							spr.applyProperties(props.customStrings);
							room.characters.set(spr.xmlName, spr);
							baseObj = spr;

						default:
							if (objNode.has.gid) {
								var raw = Std.parseFloat(objNode.att.gid);
								var hFlip = raw >= FLAG_H;
								if (hFlip)
									raw -= FLAG_H;
								var vFlip = raw >= FLAG_V;
								if (vFlip)
									raw -= FLAG_V;
								var dFlip = raw >= FLAG_D;
								if (dFlip)
									raw -= FLAG_D;
								var gid = Std.int(raw);
								var ts = tilesets.get(gid);

								if (ts != null) {
									var spr = new WorldObject(realX, realY, zIndex, name);
									spr.tiledID = objId;
									spr.loadGraphic(LilyAssets.image(cleanAssetPath(ts.path)), true, ts.tw, ts.th);

									var anim = animations.get(gid);
									if (anim != null) {
										spr.animation.add(props.animName, anim.frames, anim.fps, props.animLoop);
										spr.animation.play(props.animName);
									} else if (spr.graphic != null) {
										var cols = Std.int(spr.graphic.width / ts.tw);
										if (cols > 0)
											spr.animation.frameIndex = (Std.int(ts.ry / ts.th) * cols) + Std.int(ts.rx / ts.tw);
									}

									applyTmxTransform(spr, hFlip, vFlip, dFlip, xmlRot);
									spr.generateAccurateHitbox();
									spr.x = realX + spr.offset.x;
									spr.y = realY + spr.offset.y;
									spr.applyProperties(props.customStrings);
									baseObj = spr;
								}
							}
					}

					if (baseObj != null) {
						baseObj.visible = finalVis;
						if (!finalVis)
							baseObj.alpha = 0;
						if (objId > 0)
							objectIdMap.set(objId, baseObj);

						if (addToEntities) {
							if (Std.isOfType(baseObj, WorldObject)) {
								var wObj:WorldObject = cast baseObj;
								wObj.solidCollision = props.isSolid;
								wObj.allowCollisions = props.isSolid ? FlxObject.ANY : FlxObject.NONE;
								wObj.immovable = true;
								if (props.isInteractable)
									wObj.interactable = true;
							}

							room.addEntity(cast baseObj);
							room.sortMap.set(baseObj, {
								sortY: 0,
								treeIndex: currentTreeIndex++,
								z: zIndex,
								isDynamic: type == "Entity",
								isFlat: props.isFlat
							});

							if (props.script != null) {
								if (Std.isOfType(baseObj, WorldObject) && type != "Trigger")
									(cast baseObj : WorldObject).interactable = true;
								pendingScripts.push({target: baseObj, scriptName: props.script, objProps: props.customObjects});
							}
						}
					}
				}
				currentZIndex++;
			} else if (node.name == "imagelayer" || node.name == "group") {
				currentZIndex++;
			}
		}

		#if FEATURE_HSCRIPT
		for (def in pendingScripts) {
			var s = StringTools.endsWith(def.scriptName, ".hx") ? def.scriptName : def.scriptName + ".hx";
			var objScript = Script.create("scripts/" + s);

			room.scripts.add(objScript);
			room.entityScripts.set(def.target.xmlName, objScript);

			objScript.load();
			if (objScript != null) {
				objScript.set("this", def.target);
				objScript.set("obj", def.target);
				for (propName in def.objProps.keys()) {
					var linked = objectIdMap.get(def.objProps.get(propName));
					if (linked != null)
						objScript.set(propName, linked);
					else
						FlxG.log.error('Script Error: $s failed to link obj ID ${def.objProps.get(propName)}');
				}
			}
		}
		#end

		if (hasSpawn && mapProps.spawnPlayer) {
			var spawnPt = room.spawnPoints.exists("spawn_" + targetSpawnId) ? room.spawnPoints.get("spawn_" + targetSpawnId) : room.spawnPoints.get("spawn_0");
			if (spawnPt != null && room.player == null)
				room.spawnParty(spawnPt.x, spawnPt.y, playerZIndex);
		}
	}

	private static inline function setupObject(room:RoomManager, obj:WorldObject, vis:Bool, solid:Bool, zIndex:Int, treeIdx:Int, isFlat:Bool):Void {
		obj.visible = vis;
		if (!vis)
			obj.alpha = 0;
		obj.solidCollision = solid;
		obj.allowCollisions = solid ? FlxObject.ANY : FlxObject.NONE;
		obj.immovable = true;
		room.addEntity(obj);
		room.sortMap.set(obj, {
			sortY: 0,
			treeIndex: treeIdx,
			z: zIndex,
			isDynamic: false,
			isFlat: isFlat
		});
	}

	private static inline function extractRawProps(node:Access):Map<String, String> {
		var raw = new Map<String, String>();
		if (node.hasNode.properties) {
			for (prop in node.node.properties.nodes.property)
				raw.set(prop.att.name, prop.has.value ? prop.att.value : "");
		}
		return raw;
	}

	private static inline function extractMapProps(node:Access):TmxMapProps {
		var raw = extractRawProps(node);
		var spVal = raw.get("spawnPlayer");
		var zoomStr = raw.get("zoom");
		return {
			zoom: zoomStr != null ? Std.parseFloat(zoomStr) : null,
			location: raw.get("location"),
			spawnPlayer: spVal == null || spVal == "true" || spVal == "1",
			script: raw.get("script"),
			customStrings: raw
		};
	}

	private static inline function extractEntityProps(objNode:Access, groupProps:Map<String, String>, defaultName:String):TmxEntityProps {
		var strings = new Map<String, String>();
		var objects = new Map<String, Int>();
		for (k in groupProps.keys())
			strings.set(k, groupProps.get(k));

		if (objNode.hasNode.properties) {
			for (prop in objNode.node.properties.nodes.property) {
				if ((prop.has.type ? prop.att.type : "string") == "object")
					objects.set(prop.att.name, Std.parseInt(prop.has.value ? prop.att.value : "0"));
				else
					strings.set(prop.att.name, prop.has.value ? prop.att.value : "");
			}
		}

		var nLower = defaultName.toLowerCase();
		var autoCol = strings.get("autocollision"),
			interact = strings.get("interactable"),
			flat = strings.get("isFlat");
		var charStr = strings.get("character"),
			roomStr = strings.get("room"),
			exitStr = strings.get("exit"),
			spawnStr = strings.get("id");

		var loopStr = strings.get("anim_loop");
		var animNameStr = strings.get("anim_name");

		return {
			isSolid: autoCol == "true" || autoCol == "1",
			isInteractable: interact == "true" || interact == "1",
			isFlat: flat == "true" || flat == "1" || nLower.indexOf("floor") != -1 || nLower.indexOf("carpet") != -1,
			script: strings.get("script"),
			character: charStr != null ? charStr : nLower,
			targetRoom: roomStr != null ? roomStr : "",
			exitId: exitStr != null ? Std.parseInt(exitStr) : 0,
			spawnId: spawnStr != null ? Std.parseInt(spawnStr) : 0,
			animName: animNameStr != null ? animNameStr : "play",
			animLoop: loopStr == null || loopStr == "true" || loopStr == "1",
			customStrings: strings,
			customObjects: objects
		};
	}

	private static inline function getLayerZ(node:Access, defaultZ:Int):Int {
		var z = defaultZ;
		if (node.hasNode.properties) {
			for (prop in node.node.properties.nodes.property) {
				if (prop.att.name == "z") {
					z = Std.parseInt(prop.att.value);
					break;
				}
			}
		}
		return z;
	}

	private static inline function checkAutoCollision(node:Access):Bool {
		var col = false;
		if (node.hasNode.properties) {
			for (prop in node.node.properties.nodes.property) {
				if (prop.att.name == "autocollision" && prop.att.value == "true") {
					col = true;
					break;
				}
			}
		}
		return col;
	}

	private static function cleanAssetPath(rawPath:String):String {
		var clean = StringTools.replace(rawPath, "\\", "/");
		if (StringTools.endsWith(clean, ".png"))
			clean = clean.substring(0, clean.length - 4);
		while (clean.indexOf("../") != -1)
			clean = StringTools.replace(clean, "../", "");
		return StringTools.startsWith(clean, "images/") ? clean.substr(7) : clean;
	}

	private static inline function applyTmxTransform(spr:FlxSprite, hFlip:Bool, vFlip:Bool, dFlip:Bool, rotation:Float = 0):Void {
		spr.angle = rotation;
		spr.flipX = false;
		spr.flipY = false;
		if (dFlip) {
			spr.angle += (hFlip == vFlip) ? 90 : -90;
			if (hFlip && vFlip)
				spr.flipX = true;
			else if (!hFlip && !vFlip)
				spr.flipY = true;
		} else {
			if (hFlip && vFlip)
				spr.angle += 180;
			else {
				spr.flipX = hFlip;
				spr.flipY = vFlip;
			}
		}
	}
}
