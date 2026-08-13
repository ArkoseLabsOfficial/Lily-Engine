package engine.objects;

import godot.nodes.Sprite;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
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

enum FacingDirection {
	UP;
	DOWN;
	LEFT;
	RIGHT;
}

enum CharacterState {
	Standing;
	Walking;
	Running;
	Custom;
}

class Character extends Sprite {
	public var solidCollision:Bool = true;
	public var canMove:Bool = true;
	public var direction:FacingDirection = DOWN;
	public var state:CharacterState = Standing;

	public var isFollowingPath:Bool = false;
	public var pathVelocity:FlxPoint = FlxPoint.get();

	private var _lastFrameX:Float = 0;
	private var _lastFrameY:Float = 0;

	public var idlePrefix:String = "idle";
	public var walkPrefix:String = "walk";
	public var runPrefix:String = "run";

	public var positionHistory:Array<FlxPoint> = [];
	public var maxHistory:Int = 40;
	public var historySpacing:Float = 2.0;

	public var animData:Map<String, CharAnimData> = new Map();
	public var loadedFrames:Map<String, FlxAtlasFrames> = new Map();
	public var currentSpritePath:String = "";
	public var cameraOffset:FlxPoint = FlxPoint.get();

	#if FEATURE_HSCRIPT
	public var __script:Script;
	#end

	public function new(x:Float, y:Float, zIndex:Int, name:String) {
		super();
		this.x = x;
		this.y = y;
		this.zIndex = zIndex;
		this.nodeName = name;
		this.ySort = true;
		this.centered = false;
		visual.antialiasing = false;

		_lastFrameX = x;
		_lastFrameY = y;
	}

	public function loadEntity(spriteName:String) {
		if (!spriteName.startsWith(Flags.characterFolder))
			spriteName = Flags.characterFolder + spriteName;

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
			var baseXmlPath = '${Flags.imageFolder}$spriteName.xml';

			if (Assets.exists(baseXmlPath))
				visual.frames = Assets.getSparrowAtlas(spriteName);
			else if (Assets.imageExists(spriteName))
				visual.loadGraphic(Assets.getImage(spriteName));

			visual.updateHitbox();
			var boxWidth = visual.width * 0.9;
			var boxHeight = visual.height * 0.9;
			visual.setSize(boxWidth, boxHeight);
			visual.offset.set((visual.width - boxWidth) / 2, visual.height - boxHeight);

			setupDefaultAnimations();
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

	function setupDefaultAnimations() {
		visual.animation.addByPrefix("idle_down", "idle_down", 1, false);
		visual.animation.addByPrefix("walk_down", "walk_down", 6, true);
		visual.animation.addByPrefix("run_down", "run_down", 10, true);
		visual.animation.play("idle_down");
	}

	public function playAnim(animName:String, force:Bool = false, reversed:Bool = false) {
		if (animName == "" && force) {
			if (state == Custom)
				state = Standing;
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

	override public function update(elapsed:Float) {
		#if FEATURE_HSCRIPT
		if (__script != null)
			__script.call("update", [elapsed]);
		#end

		if (elapsed > 0) {
			var calcVx = (x - _lastFrameX) / elapsed;
			var calcVy = (y - _lastFrameY) / elapsed;

			if (Math.abs(calcVx) > 1500 || Math.abs(calcVy) > 1500) {
				calcVx = 0;
				calcVy = 0;
			}
			pathVelocity.set(calcVx, calcVy);
		}

		super.update(elapsed);
		recordHistory();
		updateAnimations();

		_lastFrameX = x;
		_lastFrameY = y;
	}

	public function recordHistory() {
		if (positionHistory.length > 0) {
			var dist = Math.sqrt(Math.pow(x - positionHistory[0].x, 2) + Math.pow(y - positionHistory[0].y, 2));
			if (dist > 150) {
				for (p in positionHistory)
					p.put();
				positionHistory = [];
			}
		}

		if (positionHistory.length == 0
			|| Math.sqrt(Math.pow(x - positionHistory[0].x, 2) + Math.pow(y - positionHistory[0].y, 2)) >= historySpacing) {
			positionHistory.unshift(FlxPoint.get(x, y));
			while (positionHistory.length > maxHistory)
				positionHistory.pop().put();
		}
	}

	public function updateAnimations():Void {
		if (state == Custom)
			return;

		var vx = isFollowingPath ? pathVelocity.x : velocity.x;
		var vy = isFollowingPath ? pathVelocity.y : velocity.y;

		var speed = Math.sqrt((vx * vx) + (vy * vy));

		if (speed > 5) {
			state = speed > 200 ? Running : Walking;
			if (Math.abs(vx) > Math.abs(vy))
				direction = vx > 0 ? RIGHT : LEFT;
			else
				direction = vy > 0 ? DOWN : UP;
		} else {
			state = Standing;
		}

		var currentPrefix = switch (state) {
			case Walking: walkPrefix;
			case Running: runPrefix;
			case Custom: "";
			default: idlePrefix;
		};

		var faceStr = switch (direction) {
			case UP: "UP";
			case LEFT: "LEFT";
			case RIGHT: "RIGHT";
			default: "DOWN";
		};

		var animName = currentPrefix + faceStr;

		if (animData.keys().hasNext()) {
			if (!animData.exists(animName) && state == Standing)
				animName = animData.exists(idlePrefix) ? idlePrefix : idlePrefix + "DOWN";

			playAnim(animName);
		} else {
			var lFace = switch (direction) {
				case UP: "_up";
				case LEFT: "_left";
				case RIGHT: "_right";
				default: "_down";
			};
			playAnim(currentPrefix + lFace);
		}
	}

	public function getCollisionBox():FlxRect {
		return FlxRect.get(x - 12, y - 12, 24, 12);
	}

	public function getGraphicBox():FlxRect {
		return FlxRect.get(x + visual.x - visual.offset.x, y + visual.y - visual.offset.y, visual.frameWidth, visual.frameHeight);
	}

	public function getInteractionBox():FlxRect {
		var box = getCollisionBox();
		box.setSize(12, 12);

		switch (direction) {
			case UP:
				box.y -= 12;
				box.x += 6;
			case DOWN:
				box.y += 14;
				box.x += 6;
			case LEFT:
				box.x -= 12;
				box.y += 3;
			case RIGHT:
				box.x += 24;
				box.y += 3;
		}
		return box;
	}

	override public function destroy() {
		#if FEATURE_HSCRIPT
		if (__script != null)
			__script.destroy();
		#end
		super.destroy();
	}
}
