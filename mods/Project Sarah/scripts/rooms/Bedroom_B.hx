import godot.nodes.PathFollow2D;
import godot.nodes.Sprite;

importScript("GameRoom");
importScript("FakeASync");
importScript("QuickStuff");
class Bedroom_B extends GameRoom {
	public function onRoomLoaded(roomName:String) {
		super.onRoomLoaded(roomName);
		zack_ruffle = Game.scene.getNode("ZackCutscene/zack_ruffle");
		open_door_to_zack = Game.scene.getNode("Points/open_door_to_zack");
		sarah_liedown = Game.scene.getNode("BGObjects/furniture_bed/sarah_liedown");
		player = Game.party[0];
		zack_ruffle.visible = sarah_liedown.visible = false;

		if (!Game.save.getVariable("zack_room_scene_happened")) {
			Game.save.setVariable("zack_room_scene_happened", true);
			setupCutscene();
		}
	}

	var zack_ruffle:Sprite;
	var open_door_to_zack:Path2D;
	var sarah_liedown:Sprite;
	var player:Player;

	function setupCutscene() {
		sarah_liedown.visible = true;
		QuickStuff.disableInteraction();
		QuickStuff.disablePlayer();
		QuickStuff.createBlackBox();
		new FakeASync().await([
			(wait) -> wait(0.1),
			(wait) -> player.setPosition(sarah_liedown.x, sarah_liedown.y),
			(wait) -> wait(0.5),
			(wait) -> FlxG.state.openSubState(new DialogBox("zack_invite", "zack_intro0"))
		]);
	}

	function knockKnockKnock() {
		new FakeASync().await([
			(wait) -> wait(0.3),
			(wait) -> FlxG.sound.play('sounds/sfx/door_2.ogg'),
			(wait) -> wait(0.3),
			(wait) -> FlxG.sound.play('sounds/sfx/door_2.ogg'),
			(wait) -> wait(0.3),
			(wait) -> FlxG.sound.play('sounds/sfx/door_2.ogg'),
			(wait) -> return true
		]);
		return false;
	}

	function sarahWakeUp() {
		new FakeASync().await([
			(wait) -> wait(1.5),
			(wait) -> sarah_liedown.Frame = 1,
			(wait) -> wait(1),
			(wait) -> QuickStuff.blackIn(0.25),
			(wait) -> wait(1),
			(wait) -> QuickStuff.blackOut(0.25),
			(wait) -> wakeUpReally()
		]);
	}

	function zackEnters() {
		QuickStuff.createNPC("Zack", "hiro");
		var zack = QuickStuff.registeredNPCs.get("Zack");
		zack.visible = false;
		zack.direction = "right";
		new FakeASync().await([
			(wait) -> wait(0.25),
			(wait) -> player.moveTo(player.x + 56, player.y,
				function() {
					player.moveTo(player.x - 1, player.y);
				}),
			(wait) -> wait(1),
			(wait) -> zack.setPosition(317, -26),
			(wait) -> zack.visible = true,
			(wait) -> wait(1),
			(wait) -> zack.moveTo(zack_ruffle.x - 14, zack_ruffle.y + 28),
			(wait) -> wait(1.5),
			(wait) -> FlxG.state.openSubState(new DialogBox("zack_invite", "zack_intro2")),
		]);
	}

	function zackAndSarah() {
		zack_ruffle.visible = true;
		player.visible = false;
		var zack = QuickStuff.registeredNPCs.get("Zack");
		zack.visible = false;
		player.movementEnabled = false;
		FlxG.state.persistentUpdate = true;
		zack_ruffle.script.instance.Play();
	}

	function zackAndSarah2() {
		zack_ruffle.visible = false;
		player.visible = true;
		var zack = QuickStuff.registeredNPCs.get("Zack");
		zack.visible = true;
	}

	function zackAndSarah3() {
		var zack = QuickStuff.registeredNPCs.get("Zack");
		zack.moveTo(317, -26, function() {
			zack.visible = false;
			zack.setPosition(-999, -999);
		});
		QuickStuff.blackIn(0.25, function() { FlxG.switchState(new BaseRoom("School_Corridor")); });
	}

	function goAndOpenTheDoor() {
		// Game.room.followPath2D("Points/open_door_to_zack/PathFollow2D", player);
		// player.setPosition(zack_ruffle.x + 15, zack_ruffle.y + 28);
		///player.setPosition(zack_ruffle.x - 40, zack_ruffle.y + 28);
		player.setPosition(zack_ruffle.x + 70, zack_ruffle.y);
		new FakeASync().await([
			(wait) -> wait(0.25),
			(wait) -> player.moveTo(player.x, player.y + 28),
			(wait) -> wait(0.5),
			(wait) -> player.direction = "left",
			(wait) -> wait(0.5),
			(wait) -> player.moveTo(player.x - 110, player.y),
			(wait) -> wait(1.5),
			(wait) -> FlxG.state.openSubState(new DialogBox("zack_invite", "zack_intro1"))
		]);
		player.direction = "down";
		zack_ruffle.visible = false;
		/*
			new FakeASync().await([
				(wait) -> wait(1),
				(wait) -> player.moveSpeed = 100,
				(wait) -> player.moveTo(player.x + 56, player.y, function() {player.moveTo(player.x - 1, player.y, () -> zack_ruffle.visible = true);})
			]);
		 */
	}

	function wakeUpReally() {
		player.y += 50;
		player.direction = "down";
		sarah_liedown.visible = false;
		player.visible = true;
		goAndOpenTheDoor();
	}

	function playCutscene() {}
}
