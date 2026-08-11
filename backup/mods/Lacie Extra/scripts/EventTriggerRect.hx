import flixel.math.FlxRect;
import flixel.FlxG;
import lime.math.Vector2;
import engine.backend.game.RoomManager;
import engine.substates.SaveLoad;
import engine.states.BaseRoom;
import engine.backend.Game;
importScript("GDUtil");
importScript("PlayerProps");

using StringTools;

var player = room.player;

var triggerAnswers:Map<String, Void->Void> = [
	"get_knife" => function(args) {
		Game.items.addItem("ch1_knife");
	},
	"Sign1" => function(args) {
		playDialogue("signs", "Sign1");
	},
	"Sign2" => function(args) {
		playDialogue("signs", "Sign2");
	},
	"Sign3" => function(args) {
		playDialogue("signs", "Sign3");
	},
	"Sign4" => function(args) {
		var path = room.currentScene.getNode("Paths/Hiro/PathFollow2D");
		path._offset = 0;
		room.followPath2D("Paths/Hiro/PathFollow2D", player, 50, false, function() {
			var hiroAnim = room.currentScene.getNode("Main/HiroAnim");
			var hiroNpc = room.currentScene.getNode("Main/HiroNpc");
			path._target = null;
			hiroAnim.visible = true;
			hiroNpc.visible = false;
			player.visible = false;
			hiroAnim.visual.animation.add("karsilasma", [0, 1, 2, 3, 4, 5, 6], 6, false);
			hiroAnim.visual.animation.finishCallback = function(name:String) {
				if (name == "karsilasma") {
					hiroAnim.visible = false;
					hiroNpc.visible = true;
					player.visible = true;

					hiroAnim.visual.animation.finishCallback = null;
				}
			};
			hiroAnim.visual.animation.play("karsilasma");
		});
	},
	"Sign5" => function(args) {
		playDialogue("signs", "Sign5");
	},
	"Sign6" => function(args) {
		playDialogue("signs", "Sign6");
	},
	"Bench" => function(args) {
		room.changeLayer(player, "Main/Bench");
		PlayerProps.sit(obj, "sitDOWN", 0, -3);
	},
	"DoubleChairTable_SitLeft" => function(args) {
		PlayerProps.sit(obj, "sitRIGHT", 10, -6);
	},
	"DoubleChairTable_SitRight" => function(args) {
		PlayerProps.sit(obj, "sitLEFT", -10, -6);
	},
	"openSave" => function(args) {
		openSubState(new SaveLoad(true, true));
	},
	"Open_Door" => function(args) {
        var closeValue:Int = Std.int(args[1]);
        var openValue:Int = Std.int(args[2]);
		var door = obj.parentNode;
		if (door.Frame == closeValue) {
			door.Frame = openValue;
			Solid = false;
		} else if (door.Frame == openValue) {
			door.Frame = closeValue;
			Solid = true;
		}
	},
	"Exit" => function() {
		if (args.length >= 2)
			teleportPlayerToRoom(args[0], args[1]);
		else
			trace("Exit event requires 2 args: Exit(room, spawn)");
	},
];

public var Event:String = "";
public var Enabled:Bool = true;
public var Solid:Bool = false;
public var Trigger:Int = 0; // 0 = confirm press, 1 = touch
public var Directions:Int = 0;
public var Area:Vector2 = new Vector2(32, 32);
public var Offset:Vector2 = new Vector2(0, 0);
var hasTriggeredTouch:Bool = false;
var _shapeNode:Dynamic = null;

function onRoomLoaded() {
	_shapeNode = GDUtil.MakeCollisionRect(Area, Offset);
	_shapeNode.nodeName = obj.nodeName + "_shape";

	var scene:Dynamic = RoomManager.instance.currentScene;
	if (scene != null)
		scene.add(_shapeNode);
	PlayerProps.sitting = false;
}

function update(elapsed:Float) {
	if (_shapeNode != null) {
		if (Solid && Enabled) {
			_shapeNode.x = obj.x - (Area.x / 2.0) + Offset.x;
			_shapeNode.y = obj.y - (Area.y / 2.0) + Offset.y;
			_shapeNode.width = Area.x;
			_shapeNode.height = Area.y;
			_shapeNode.offset.set(0, 0);
		} else {
			_shapeNode.width = 0;
			_shapeNode.height = 0;
		}
	}

	if (!Enabled)
		return;

	var isOverlapping:Bool = false;
	if (player != null && player.canMove) {
		if (Trigger == 0) {
			var px:Float = obj.x;
			var py:Float = obj.y;
			var rectX:Float = px - (Area.x / 2.0) + Offset.x;
			var rectY:Float = py - (Area.y / 2.0) + Offset.y;
			var rect:FlxRect = FlxRect.get(rectX, rectY, Area.x, Area.y);

			var iBox:FlxRect = player.getInteractionBox();
			if (iBox != null) {
				isOverlapping = iBox.overlaps(rect);
				iBox.put();
			}
			rect.put();
		} else {
			isOverlapping = player.checkCollisionObject(_shapeNode);
		}
	}

	if (Trigger == 0) {
		if (isOverlapping && Controls.ACCEPT)
			fireEvent();
	} else if (Trigger == 1) {
		if (isOverlapping && !hasTriggeredTouch) {
			hasTriggeredTouch = true;
			fireEvent();
		} else if (!isOverlapping) {
			hasTriggeredTouch = false;
		}
	}

	PlayerProps.update();
}

function fireEvent() {
	var rawEvent:String = (Event != null && Event != "") ? Event : obj.nodeName;

	var cmdName:String = rawEvent;
	var args:Array<String> = [];

	var openIndex:Int = rawEvent.indexOf("(");
	var closeIndex:Int = rawEvent.indexOf(")");

	if (openIndex != -1 && closeIndex != -1 && closeIndex > openIndex) {
		cmdName = rawEvent.substring(0, openIndex).trim();
		var argsContent:String = rawEvent.substring(openIndex + 1, closeIndex);
		var rawArgs:Array<String> = argsContent.split(",");
		for (arg in rawArgs)
			args.push(arg.trim());
	}

	if (triggerAnswers.exists(cmdName)) {
		var action = triggerAnswers[cmdName];
		action(args);
		return;
	} else {
		trace('Warning: Command "$cmdName" not found in triggerAnswers!');
	}
}

function teleportPlayerToRoom(roomPath:String, targetSpawnPointName:String) {
	trace("Teleporting to room: " + roomPath + " spawn: " + targetSpawnPointName);
	targetSpawn = targetSpawnPointName;
	FlxG.switchState(new BaseRoom(roomPath));
}
