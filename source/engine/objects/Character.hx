package engine.objects;

import godot.nodes.Sprite;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import haxe.xml.Access;
import engine.backend.Game;

typedef CharAnimData = {
	var name:String;
	var prefix:String;
	var fps:Int;
	var loop:Bool;
	var offsetX:Float;
	var offsetY:Float;
	var cameraX:Float;
	var cameraY:Float;
	var spritePath:String;
}

enum abstract FacingDirection(String) from String to String {
	var UP = "up";
	var DOWN = "down";
	var LEFT = "left";
	var RIGHT = "right";
}

enum CharacterState {
	Idle;
	Walking;
	Running;
	Custom;
}

typedef RelativeBox = {
	var name:String;
	var x:Float;
	var y:Float;
	var width:Float;
	var height:Float;
	var visible:Bool;
	var enabled:Bool;
}

class Character extends Sprite {
	public var isSolid:Bool = true;
	public var movementEnabled:Bool = true;
	public var direction:FacingDirection = DOWN;
	public var state:CharacterState = Idle;

	public var isFollowingPath:Bool = false;
	public var pathTarget:FlxPoint = null;
	public var baseSpeed:Float = 160;
	public var runMultiplier:Float = 1.75;
	public var runningThreshold:Float = 200;
	public var onPathComplete:Void->Void = null;

	public var followTarget:Character = null;
	public var followDistance:Int = 12;
	public var syncAnimations:Bool = false;

	public var positionHistory:Array<FlxPoint> = [];
	public var maxHistory:Int = 40;
	public var historySpacing:Float = 2.0;

	public var idlePrefix:String = "idle";
	public var walkPrefix:String = "walk";
	public var runPrefix:String = "run";

	public var animData:Map<String, CharAnimData> = new Map();
	public var loadedFrames:Map<String, FlxAtlasFrames> = new Map();
	public var currentSpritePath:String = "";
	public var cameraOffset:FlxPoint = FlxPoint.get();

	public var hitboxes:Array<RelativeBox> = [];
	public var interactions:Array<RelativeBox> = [];
	public var drawDebugBoxes:Bool = false;

	public var defaultHitbox:RelativeBox;

	public var debugBoxesGroup:FlxSpriteGroup;

	private var hitboxSprites:Map<String, FlxSprite> = new Map();
	private var interactionSprites:Map<String, FlxSprite> = new Map();

	private var lastX:Float = 0;
	private var lastY:Float = 0;

	#if FEATURE_HSCRIPT
	public var __script:Script;
	#end

	public function new(x:Float, y:Float, zIndex:Int, name:String) {
		super();
		this.x = x;
		this.y = y;
		this.zindex = zIndex;
		this.name = name;
		this.centered = false;
		visual.antialiasing = false;

		lastX = x;
		lastY = y;

		initBoxes();

		debugBoxesGroup = new FlxSpriteGroup();
		add(debugBoxesGroup);
	}

	function initBoxes():Void {
		defaultHitbox = addHitbox("body", -16, -12, 32, 12, false, true);

		addInteraction("interact_down", -6, 0, 12, 12, false, true);
		addInteraction("interact_up", -6, -26, 12, 12, false, true);
		addInteraction("interact_left", -24, -14, 12, 12, false, true);
		addInteraction("interact_right", 12, -14, 12, 12, false, true);
	}

	public function addHitbox(name:String, x:Float, y:Float, width:Float, height:Float, visible:Bool = false, enabled:Bool = true):RelativeBox {
		var box:RelativeBox = {
			name: name,
			x: x,
			y: y,
			width: width,
			height: height,
			visible: visible,
			enabled: enabled
		};
		hitboxes.push(box);
		return box;
	}

	public function addInteraction(name:String, x:Float, y:Float, width:Float, height:Float, visible:Bool = false, enabled:Bool = true):RelativeBox {
		var box:RelativeBox = {
			name: name,
			x: x,
			y: y,
			width: width,
			height: height,
			visible: visible,
			enabled: enabled
		};
		interactions.push(box);
		return box;
	}

	public function getHitboxRect(?box:RelativeBox):FlxRect {
		if (box == null)
			box = defaultHitbox;
		return FlxRect.get(this.x + box.x, this.y + box.y, box.width, box.height);
	}

	public function getHitboxRects():Array<FlxRect> {
		var rects = [];
		for (box in hitboxes) {
			if (box.enabled) {
				rects.push(FlxRect.get(this.x + box.x, this.y + box.y, box.width, box.height));
			}
		}
		return rects;
	}

	public function getInteractionRect(?targetName:String):FlxRect {
		if (targetName == null)
			targetName = "interact_" + direction;

		for (box in interactions) {
			if (box.name == targetName && box.enabled) {
				return FlxRect.get(this.x + box.x, this.y + box.y, box.width, box.height);
			}
		}
		return FlxRect.get(this.x, this.y, 0, 0);
	}

	public function getCollisionBox():FlxRect {
		return getHitboxRect(defaultHitbox);
	}

	public function getCollisionBoxes():Array<FlxRect> {
		return getHitboxRects();
	}

	public function getGraphicBox():FlxRect {
		return FlxRect.get(x + visual.x - visual.offset.x, y + visual.y - visual.offset.y, visual.frameWidth, visual.frameHeight);
	}

	public function getInteractionBox():FlxRect {
		return getInteractionRect("interact_" + direction);
	}

	public function updateDebugBoxes():Void {
		if (debugBoxesGroup == null)
			return;

		if (!drawDebugBoxes) {
			debugBoxesGroup.visible = false;
			return;
		}

		debugBoxesGroup.visible = true;

		for (box in hitboxes) {
			var spr:FlxSprite;
			if (!hitboxSprites.exists(box.name)) {
				spr = new FlxSprite().makeGraphic(1, 1, 0xFFFFFFFF);
				hitboxSprites.set(box.name, spr);
				debugBoxesGroup.add(spr);
			} else {
				spr = hitboxSprites.get(box.name);
			}

			if (box.enabled) {
				spr.visible = true;
				spr.color = 0xFF0000;
				spr.alpha = 0.5;
				spr.scale.set(box.width, box.height);
				spr.updateHitbox();
				spr.x = this.x + box.x;
				spr.y = this.y + box.y;
			} else {
				spr.visible = false;
			}
		}

		var activeName = "interact_" + direction;
		for (box in interactions) {
			var spr:FlxSprite;
			if (!interactionSprites.exists(box.name)) {
				spr = new FlxSprite().makeGraphic(1, 1, 0xFFFFFFFF);
				interactionSprites.set(box.name, spr);
				debugBoxesGroup.add(spr);
			} else {
				spr = interactionSprites.get(box.name);
			}

			if (box.enabled) {
				spr.visible = true;
				spr.color = (box.name == activeName) ? 0x00FF00 : 0x004400;
				spr.alpha = 0.5;
				spr.scale.set(box.width, box.height);
				spr.updateHitbox();
				spr.x = this.x + box.x;
				spr.y = this.y + box.y;
			} else {
				spr.visible = false;
			}
		}
	}

	public function loadEntity(spriteName:String) {
		if (!spriteName.startsWith('${Flags.characterFolder}/'))
			spriteName = '${Flags.characterFolder}/$spriteName';

		var fullPath = spriteName;
		var xmlPath = fullPath + ".xml";

		if (Assets.exists(xmlPath)) {
			var rawXml = Assets.getText(xmlPath);
			if (rawXml.indexOf("<character") != -1) {
				var xml = Xml.parse(StringTools.replace(rawXml, "<!DOCTYPE lily-engine-character>", "")).firstElement();

				if (xml != null && xml.nodeName == "character") {
					var parsed = new Access(xml);
					var defaultSprite = parsed.has.sprite ? parsed.att.sprite : spriteName;

					if (parsed.has.flipX)
						flipH = parsed.att.flipX == "true";
					if (parsed.has.flipY)
						flipV = parsed.att.flipY == "true";

					if (parsed.hasNode.anim) {
						for (animNode in parsed.nodes.anim) {
							var aName = animNode.has.name ? animNode.att.name : "idle";
							var aSprite = animNode.has.sprite ? animNode.att.sprite : defaultSprite;

							animData.set(aName, {
								name: aName,
								prefix: animNode.has.anim ? animNode.att.anim : aName,
								fps: animNode.has.fps ? Std.parseInt(animNode.att.fps) : 24,
								loop: animNode.has.loop && animNode.att.loop == "true",
								offsetX: animNode.has.x ? Std.parseFloat(animNode.att.x) : 0,
								offsetY: animNode.has.y ? Std.parseFloat(animNode.att.y) : 0,
								cameraX: animNode.has.camX ? Std.parseFloat(animNode.att.camX) : 0,
								cameraY: animNode.has.camY ? Std.parseFloat(animNode.att.camY) : 0,
								spritePath: aSprite
							});

							if (!loadedFrames.exists(aSprite)) {
								var atlas = Assets.getSparrowAtlas(aSprite);
								if (atlas != null)
									loadedFrames.set(aSprite, atlas);
							}
						}
					}

					if (loadedFrames.exists(defaultSprite)) {
						visual.frames = loadedFrames.get(defaultSprite);
						currentSpritePath = defaultSprite;
					}

					playAnim(animData.exists(idlePrefix + "DOWN") ? idlePrefix + "DOWN" : idlePrefix);
				}
			}
		} else {
			var baseXmlPath = '${Flags.imageFolder}/$spriteName.xml';

			if (Assets.exists(baseXmlPath))
				visual.frames = Assets.getSparrowAtlas(spriteName);
			else if (Assets.imageExists(spriteName))
				visual.loadGraphic(Assets.getImage(spriteName));

			visual.updateHitbox();
			var boxWidth = visual.width * 0.9;
			var boxHeight = visual.height * 0.9;
			visual.setSize(boxWidth, boxHeight);
			visual.offset.set((visual.width - boxWidth) / 2, visual.height - boxHeight);
		}

		#if FEATURE_HSCRIPT
		if (__script != null) {
			__script.destroy();
			__script = null;
		}

		var scrPath = '$spriteName.hx';
		if (Assets.exists(scrPath)) {
			__script = Script.create(scrPath);
			__script.set("this", this);
			__script.set("char", this);
			__script.load();
			__script.call("create");
		}
		#end
	}

	public function playAnim(animName:String, force:Bool = false, reversed:Bool = false) {
		if (animName == "" && force) {
			if (state == Custom)
				state = Idle;
			return;
		}

		if (force)
			state = Custom;

		var isNewAnim = force || visual.animation.curAnim == null || visual.animation.curAnim.name != animName;

		if (animData.exists(animName)) {
			var data = animData.get(animName);

			if (isNewAnim) {
				if (currentSpritePath != data.spritePath && loadedFrames.exists(data.spritePath)) {
					for (anim in visual.animation.getNameList())
						visual.animation.remove(anim);
					visual.frames = loadedFrames.get(data.spritePath);
					currentSpritePath = data.spritePath;
				}
				if (visual.animation.getByName(animName) == null)
					visual.animation.addByPrefix(animName, data.prefix, data.fps, data.loop);
				visual.animation.play(animName, force, reversed);
			}
			visual.offset.set((visual.frameWidth / 2) - data.offsetX, visual.frameHeight - data.offsetY);
			cameraOffset.set(data.cameraX, data.cameraY);
		} else {
			if (isNewAnim)
				visual.animation.play(animName, force, reversed);
			visual.offset.set(visual.frameWidth / 2, visual.frameHeight);
		}
	}

	public function turn(facing:FacingDirection) {
		this.direction = facing;
	}

	public function moveTo(tx:Float, ty:Float, ?onFinish:Void->Void):Void {
		if (pathTarget == null)
			pathTarget = FlxPoint.get();
		pathTarget.set(tx, ty);
		onPathComplete = onFinish;
		isFollowingPath = true;
	}

	public function teleport(?tx:Float, ?ty:Float):Void {
		isFollowingPath = false;

		if (tx != null && ty != null) {
			x = tx;
			y = ty;
		} else if (pathTarget != null) {
			x = pathTarget.x;
			y = pathTarget.y;
		}

		if (pathTarget != null) {
			pathTarget.put();
			pathTarget = null;
		}

		if (onPathComplete != null) {
			var cb = onPathComplete;
			onPathComplete = null;
			cb();
		}
	}

	function updatePathMovement(elapsed:Float):Void {
		if (pathTarget == null)
			return;

		var dx = pathTarget.x - x;
		var dy = pathTarget.y - y;
		var distSq = dx * dx + dy * dy;
		var step = baseSpeed * elapsed;

		if (distSq <= step * step) {
			x = pathTarget.x;
			y = pathTarget.y;
			isFollowingPath = false;
			pathTarget.put();
			pathTarget = null;

			if (onPathComplete != null) {
				var cb = onPathComplete;
				onPathComplete = null;
				cb();
			}
		} else {
			var dist = Math.sqrt(distSq);
			x += (dx / dist) * step;
			y += (dy / dist) * step;
		}
	}

	public function follow(target:Character, distance:Int = 12, copyAnims:Bool = false):Void {
		followTarget = target;
		followDistance = distance;
		syncAnimations = copyAnims;
		isSolid = false;
	}

	public function stopFollowing():Void {
		followTarget = null;
		isSolid = true;
	}

	function updateFollower(elapsed:Float):Void {
		if (followTarget == null || !followTarget.exists) {
			stopFollowing();
			return;
		}

		var dx = followTarget.x - x;
		var dy = followTarget.y - y;
		var distSq = dx * dx + dy * dy;

		var targetDist:Float = 24.0;
		var targetDistSq = targetDist * targetDist;

		if (distSq > targetDistSq) {
			var dist = Math.sqrt(distSq);
			var followSpeed = followTarget.baseSpeed * (followTarget.state == Running ? followTarget.runMultiplier : 1.0);

			var step = followSpeed * elapsed;
			var moveDist = dist - targetDist;
			if (step > moveDist)
				step = moveDist;

			x += (dx / dist) * step;
			y += (dy / dist) * step;
		}

		if (syncAnimations) {
			direction = followTarget.direction;
			state = followTarget.state;
		}
	}

	override public function update(elapsed:Float) {
		#if FEATURE_HSCRIPT
		if (__script != null)
			__script.call("update", [elapsed]);
		#end

		if (followTarget != null)
			updateFollower(elapsed);
		else if (isFollowingPath)
			updatePathMovement(elapsed);

		super.update(elapsed);

		var dx = x - lastX;
		var dy = y - lastY;
		var speed = computeSpeed(dx, dy, elapsed);

		if (followTarget == null || !syncAnimations)
			updateStateFromMovement(dx, dy, speed);

		if (state != Custom)
			refreshAnimation();

		updateHistory();
		updateDebugBoxes();

		lastX = x;
		lastY = y;
	}

	public function updateHistory():Void {
		if (positionHistory.length > 0) {
			var head = positionHistory[0];
			var dx = x - head.x;
			var dy = y - head.y;
			if (dx * dx + dy * dy > 150 * 150) {
				for (p in positionHistory)
					p.put();
				positionHistory = [];
			}
		}

		if (positionHistory.length == 0) {
			positionHistory.unshift(FlxPoint.get(x, y));
		} else {
			var head = positionHistory[0];
			var dx = x - head.x;
			var dy = y - head.y;
			if (dx * dx + dy * dy >= historySpacing * historySpacing)
				positionHistory.unshift(FlxPoint.get(x, y));
		}

		while (positionHistory.length > maxHistory)
			positionHistory.pop().put();
	}

	public function refreshAnimation():Void {
		var hasData = animData.keys().hasNext();
		var animName:String;

		if (hasData) {
			var suffix = switch (direction) {
				case UP: "UP";
				case LEFT: "LEFT";
				case RIGHT: "RIGHT";
				default: "DOWN";
			};
			var prefix = switch (state) {
				case Walking: walkPrefix;
				case Running: runPrefix;
				default: idlePrefix;
			};
			animName = prefix + suffix;

			if (!animData.exists(animName) && state == Idle)
				animName = animData.exists(idlePrefix) ? idlePrefix : idlePrefix + "DOWN";
		} else {
			var face = switch (direction) {
				case UP: "_up";
				case LEFT: "_left";
				case RIGHT: "_right";
				default: "_down";
			};
			var prefix = switch (state) {
				case Walking: walkPrefix;
				case Running: runPrefix;
				default: idlePrefix;
			};
			animName = prefix + face;
		}

		playAnim(animName);
	}

	inline function computeSpeed(dx:Float, dy:Float, elapsed:Float):Float {
		if (elapsed <= 0)
			return 0;
		var vx = dx / elapsed;
		var vy = dy / elapsed;
		if (Math.abs(vx) > 1500)
			vx = 0;
		if (Math.abs(vy) > 1500)
			vy = 0;
		return Math.sqrt(vx * vx + vy * vy);
	}

	inline function updateStateFromMovement(dx:Float, dy:Float, speed:Float):Void {
		if (speed > 5) {
			state = (speed > runningThreshold) ? Running : Walking;
			var threshold:Float = 0;
			var absDx = Math.abs(dx);
			var absDy = Math.abs(dy);

			if (absDy > absDx + threshold) {
				direction = (dy > 0) ? DOWN : UP;
			} else if (absDx > absDy + threshold) {
				direction = (dx > 0) ? RIGHT : LEFT;
			}
		} else {
			if (state != Custom)
				state = Idle;
		}
	}

	override public function destroy() {
		#if FEATURE_HSCRIPT
		if (__script != null)
			__script.destroy();
		#end

		if (pathTarget != null) {
			pathTarget.put();
			pathTarget = null;
		}

		for (p in positionHistory)
			p.put();
		positionHistory = null;

		if (debugBoxesGroup != null) {
			debugBoxesGroup.destroy();
			debugBoxesGroup = null;
		}
		hitboxSprites = null;
		interactionSprites = null;

		super.destroy();
	}
}
