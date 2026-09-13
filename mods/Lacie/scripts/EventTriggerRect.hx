import flixel.math.FlxRect;
import flixel.FlxG;
import lime.math.Vector2;

importScript("GDUtil");
importScript("GameProperties");
importScript("EventTrigger");
using StringTools;

class EventTriggerRect extends EventTrigger {
	var player = Game.party[0];

	public var Area:Vector2 = new Vector2(32, 32);
	public var Offset:Vector2 = new Vector2(0, 0);

	var hasTriggeredTouch:Bool = false;
	var _shapeNode:Dynamic = null;

	public var triggers = [
		"Ch1_Home_Exterior_Front" => function(eventName, args) {
			switch (eventName) {
				case "misc_save":
					FlxG.state.openSubState(new SaveLoadMenu(true, true));
					Game.save.setVariable("ch1.checked_save", true);
					Game.room.scene.root.script.instance._UpdateRoom();
				case "move_exit":
					FlxG.switchState(new TitleMenu());
			}
		}
	];

	function onRoomLoaded() {
		_shapeNode = GDUtil.MakeCollisionRect(Area, Offset);
		_shapeNode.name = obj.name + "_shape";

		var scene:Dynamic = Game.room.scene;
		if (scene != null)
			scene.add(_shapeNode);
		GameProperties.sitting = false;
	}

	function update(elapsed:Float) {
		if (_shapeNode != null) {
			if (_solid && Enabled) {
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

		if (Game.party != null && Game.party.length > 0) {
			var player = Game.party[0];

			var iBox = player.getInteractionBox();
			var px:Float = obj.x;
			var py:Float = obj.y;
			var rectX:Float = px - (Area.x / 2.0) + Offset.x;
			var rectY:Float = py - (Area.y / 2.0) + Offset.y;
			var rect:FlxRect = FlxRect.get(rectX, rectY, Area.x, Area.y);
			var directionMatch:Bool = false;
			if (Directions == 0) {
                directionMatch = true;
            } else {
                switch (player.direction) {
                    case "left":
                        directionMatch = (Directions & 1) != 0;
                    case "up":
                        directionMatch = (Directions & 2) != 0;
                    case "right":
                        directionMatch = (Directions & 4) != 0;
                    case "down":
                        directionMatch = (Directions & 8) != 0;
                }
            }
			if (iBox.overlaps(rect) && directionMatch) {
				if (_trigger == 1 && !hasTriggeredTouch) {
					hasTriggeredTouch = true;
					fireEvent();
				} else if (_trigger == 0 && Controls.ACCEPT) {
					fireEvent();
				}
			} else {
				if (_trigger == 1) {
					hasTriggeredTouch = false;
				}
			}
		}

		GameProperties.sit_update();
	}

	function fireEvent() {
		var rawEvent:String = (_event != null && _event != "") ? _event : obj.name;

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

		if (triggers.exists(Game.baseRoom.roomName)) {
			var action = triggers[Game.baseRoom.roomName];
			trace('Warning: Command "$cmdName" triggered!');
			action(cmdName, args);
			return;
		} else {
			trace('Warning: Command "$cmdName" not found in triggers!');
		}
	}

	function teleportPlayerToRoom(roomPath:String, targetSpawnPointName:String) {
		trace("Teleporting to room: " + roomPath + " spawn: " + targetSpawnPointName);
		targetSpawn = targetSpawnPointName;
		FlxG.switchState(new BaseRoom(roomPath));
	}
}
