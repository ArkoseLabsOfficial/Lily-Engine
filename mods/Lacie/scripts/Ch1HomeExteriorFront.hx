package subgame.chapter1;

import godot.nodes.Node;
import godot.nodes.Node2D;
import godot.nodes.AnimationPlayer;

importScript("GameRoom");
importScript("Lighting");
importScript("SpawnPoint");
class Ch1HomeExteriorFront extends GameRoom {
	public var lightDay:Lighting;
	public var lightEvening:Lighting;
	public var lightNight:Lighting;
	public var sfxBusIdle:String;

	private var nBus:Node2D;
	private var nLightingLivingroomDoor:Node2D;
	private var nLightingHallwayWindow:Node2D;
	private var nLightingHallwayWindow2:Node2D;
	private var nLightingBedroomAWindow:Node2D;
	private var nLightingNight:Node2D;
	private var nMiscMarkings:Node2D;
	private var nCrow:Node2D;
	private var nCrowEvt:Bool;
	private var nSaveArrow:Node2D;
	private var nSaveArrowAnimation:AnimationPlayer;

	override public function _Ready():Void {
		super._Ready();
		SpawnPoint.loadSpawnPoint("Other/Points/front_gate");
		Game.save.setVariable("general.chapter", 1);

		scene.getNode("Other/TilesCol").visible = false;

		nBus = scene.getNode("Foreground/bus");
		nLightingLivingroomDoor = scene.getNode("Foreground/livingroom_door");
		nLightingHallwayWindow = scene.getNode("Foreground/hallway_window");
		nLightingHallwayWindow2 = scene.getNode("Foreground/hallway_window_2");
		nLightingBedroomAWindow = scene.getNode("Foreground/bedroom_a_window");
		nLightingNight = scene.getNode("Foreground/night");
		nMiscMarkings = scene.getNode("Background/misc_markings");
		nCrow = scene.getNode("Foreground/Crow");
		// nCrowEvt = scene.getNode("Other/Events/misc_save");
		nSaveArrow = scene.getNode("Foreground/Crow/indicator_arrow1");
		nSaveArrowAnimation = scene.getNode("Foreground/Crow/indicator_arrow1/Animation");
	}

	override public function _BeforeFadeIn():Void {
		if (Game.save.getVariable("general.chapter") == 1) {
			var partOfDay:Dynamic = Game.save.getVariable("general.part_of_day");
			if (partOfDay == "evening") {
				SaveLocation = "system.locations.ch1.home";
				SaveImage = "ch1_home_afternoon";
			} else if (partOfDay == "night") {
				SaveLocation = "system.locations.ch1.home_night";
				SaveImage = "ch1_home_night";
			}
		}
	}

	override public function _UpdateRoom():Void {
		// Game.Room.ResetLighting();
		if (nLightingLivingroomDoor != null)
			nLightingLivingroomDoor.visible = false;
		if (nLightingHallwayWindow != null)
			nLightingHallwayWindow.visible = false;
		if (nLightingHallwayWindow2 != null)
			nLightingHallwayWindow2.visible = false;
		if (nLightingBedroomAWindow != null)
			nLightingBedroomAWindow.visible = false;
		if (nLightingNight != null)
			nLightingNight.visible = false;

		var partOfDay:Dynamic = Game.save.getVariable("general.part_of_day");
		if (partOfDay == null)
			partOfDay = "evening";

		if (partOfDay == "day") {
			// if (lightDay != null)
			// lightDay.Apply();
		} else if (partOfDay == "evening") {
			// if (lightEvening != null)
			// lightEvening.Apply();
		} else if (partOfDay == "night") {
			// if (lightNight != null)
			// lightNight.Apply();
			if (nLightingNight != null)
				nLightingNight.visible = true;
			if (Game.save.getVariable("general.lights_home1f_livingroom") && nLightingLivingroomDoor != null) {
				nLightingLivingroomDoor.visible = true;
			}
			if (Game.save.getVariable("general.lights_home_2f_hallway")) {
				if (nLightingHallwayWindow != null)
					nLightingHallwayWindow.visible = true;
				if (nLightingHallwayWindow2 != null)
					nLightingHallwayWindow2.visible = true;
			}
			if (Game.save.getVariable("general.lights_home_2f_bedroom_a") && nLightingBedroomAWindow != null) {
				nLightingBedroomAWindow.visible = true;
			}
		}

		if (Game.save.getVariable("general.chapter") == 1) {
			var ritualBusWaiting:Bool = Game.save.getVariable("ch1.home_ritualbuswaiting");
			var busNotThere:Bool = Game.save.getVariable("ch1.bus_not_there");

			if (ritualBusWaiting && !busNotThere) {
				if (sfxBusIdle != null && sfxBusIdle.length > 0) {
					var cleanPath = sfxBusIdle.replace("assets/", "");
					FlxG.sound.play('sounds/$cleanPath', 0.6, true);
				}
				if (nBus != null)
					nBus.visible = true;
			} else {
				if (nBus != null)
					nBus.visible = false;
			}

			if (busNotThere) {
				if (nCrow != null)
					nCrow.visible = false;
				if (nCrowEvt != null)
					nCrowEvt = false;
			} else {
				if (nCrow != null)
					nCrow.visible = true;
				if (nCrowEvt != null)
					nCrowEvt = true;
			}

			if (Game.save.getVariable("ch1.home_drew_markings") && nMiscMarkings != null) {
				nMiscMarkings.visible = true;
			}

			if (!Game.save.getVariable("ch1.checked_save")) {
				if (nSaveArrow != null)
					nSaveArrow.visible = true;
				nSaveArrowAnimation.play("bounce");
			} else {
				if (nSaveArrow != null)
					nSaveArrow.visible = false;
				if (nSaveArrowAnimation != null)
					nSaveArrowAnimation.stop();
			}
		}
	}

	public function Ch1StopTimer():Void {
		// Haxe/Flixel tabanlı alternatif zamanlayıcı durdurma
		flixel.util.FlxTimer.globalManager.clear();
	}
}
