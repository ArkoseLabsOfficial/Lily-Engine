import flixel.math.FlxRect;
import lime.math.Vector2;

importScript("GDUtil");
importScript("EventTrigger");
importScript("GameProperties");
importScript("QuickStuff");
using StringTools;

/**
 * A experimental EventTrigger that will get seperated Event Scripts when switched to hxScript.
 * @:Author: Zack Everett
 **/
class EventTriggerRect extends EventTrigger {
	var player = Game.party[0];

	public var Area:Vector2 = new Vector2(32, 32);
	public var Offset:Vector2 = new Vector2(0, 0);

	var hasTriggeredTouch:Bool = false;
	var _shapeNode:Dynamic = null;

	public var triggers = [
		"Global" => function(eventName, args) {
			switch (eventName) {
				case "open_save_screen":
					FlxG.state.openSubState(new SaveLoadMenu(true, true));
				case "moveTo":
					GameProperties.spawnLocation = args[1];
					FlxG.switchState(new BaseRoom(args[0]));
			}
		},
		"School_Corridor" => function(eventName, args) {
			switch (eventName) {
				case "move_classroom_b":
					FlxG.switchState(new BaseRoom("School_Classroom_B"));
				case "move_classroom_a":
					FlxG.switchState(new BaseRoom("School_Classroom_A"));
			}
		},
		"School_Classroom_B" => function(eventName, args) {
			switch (eventName) {
				case "move_exit":
					GameProperties.spawnLocation = "classroom_b_door";
					FlxG.switchState(new BaseRoom("School_Corridor"));
				case "get_scissors":
					FlxG.state.openSubState(new ScriptedSubState("ObtainUI", {
						items: [{id: "ch1_scissors"}],
						call: "event.School_Classroom_B.get_scissors"
					}));
			}
		}
	];

	function getRootInstance() {
		return Game.room.scene.root.script.instance;
	}

	function changeToRitual() {
		Game.room.scene.root.script.instance.set_DarknessEnabled(false);
		Game.room.scene.getNode("Main/Desks").visible = false;
		Game.room.scene.getNode("Main/Desks").y += 900;
		Game.room.scene.getNode("Main/Unorginzed_Desks").visible = true;
		Game.room.scene.getNode("Main/Unorginzed_Desks").y += 500;
		Game.room.scene.getNode("Main/Candles").visible = true;
		Game.room.scene.getNode("Main/Candles/off").visible = false;
		Game.room.scene.getNode("Main/Candles/on").visible = true;
		Game.party[0].x = 440;
		Game.party[0].y = 500;
		obj.script.instance.triggerEnabled = false;
	}

	function onRoomLoaded() {
		_shapeNode = GDUtil.makeCollisionRect(Area, Offset);
		_shapeNode.name = obj.name + "_shape";
		obj.addChild(_shapeNode.name, _shapeNode);

		QuickStuff.createPartyChar("girl1", Game.party[0]);
		QuickStuff.createPartyChar("girl2", Game.party[1]);
		QuickStuff.createPartyChar("girl3", Game.party[2]);
	}

	function update(elapsed:Float) {
		if (FlxG.keys.justPressed.M)
			FlxG.state.openSubState(new ScriptedSubState("PhoneUI"));

		if (_shapeNode != null) {
			if (_solid && _enabled) {
				_shapeNode.x = (obj.x - (Area.x / 2.0) + Offset.x) / obj.scale.y;
				_shapeNode.y = (obj.y - (Area.y / 2.0) + Offset.y) / obj.scale.y;
				_shapeNode.width = Area.x;
				_shapeNode.height = Area.y;
				_shapeNode.offset.set(0, 0);
			} else {
				_shapeNode.width = 0;
				_shapeNode.height = 0;
			}
		}

		if (!_enabled)
			return;

		if (Game.party != null && Game.party.length > 0) {
			var player = Game.party[0];

			var iBox = player.getInteractionBox();
			var px:Float = obj.x;
			var py:Float = obj.y;
			var rectX:Float = px - (Area.x / 2.0) + Offset.x / obj.scale.y;
			var rectY:Float = py - (Area.y / 2.0) + Offset.y / obj.scale.y;
			var rect:FlxRect = FlxRect.get(rectX, rectY, Area.x, Area.y);

			var directionMatch:Bool = false;
			if (_directions == 0) {
				directionMatch = true;
			} else {
				switch (player.direction) {
					case "left":
						directionMatch = (_directions & 1) != 0;
					case "up":
						directionMatch = (_directions & 2) != 0;
					case "right":
						directionMatch = (_directions & 4) != 0;
					case "down":
						directionMatch = (_directions & 8) != 0;
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
	}

	function fireEvent() {
		var rawEvent:String = obj.name;
		if (_event != null && _event != "")
			rawEvent = _event;

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
		} else if (_args != null && _args != "") {
			var rawArgs:Array<String> = _args.split(",");
			for (arg in rawArgs)
				args.push(arg.trim());
		}

		if (cmdName == "moveTo")
			cmdName = 'Global.$cmdName';

		if (triggers.exists(Game.baseRoom.roomName) || triggers.exists("Global")) {
			var action:Dynamic;
			if (cmdName.startsWith("Global.")) {
				cmdName = cmdName.replace("Global.", "");
				action = triggers["Global"];
			} else
				action = triggers[Game.baseRoom.roomName];

			trace('Warning: Command "$cmdName" Argument "$args" triggered!');
			if (action != null)
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
