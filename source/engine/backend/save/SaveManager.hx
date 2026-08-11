package engine.backend.save;

import flixel.util.FlxSave;
import flixel.FlxG;
import haxe.Timer;
import engine.backend.Game;
import engine.backend.save.GamePrefs;
import engine.backend.game.RoomManager;

typedef SavedItem = {id:String, amount:Int}
typedef Position = {x:Float, y:Float}

typedef SaveSlotData = {
	var id:String;
	var slotNum:Int;
	var location:String;
	var chapterName:String;
	var playtime:Float;
	var party:Array<String>;
	var partyPositions:Array<Position>;
	var room:String;
	var inventory:Array<SavedItem>;
	var currentObjectives:Array<String>;
	var completedObjectives:Array<String>;
	var failedObjectives:Array<String>;
	var variables:Dynamic;
	var isEmpty:Bool;
}

class SaveManager {
	public static var instance:SaveManager = new SaveManager();

	public var chapterName:String;
	public var location:String;

	public var variables:Map<String, Dynamic>;
	public var party:Array<String>;

	public var room:String;
	public var partyPositions:Array<Position>;

	public var currentObjectives:Array<String>;
	public var completedObjectives:Array<String>;
	public var failedObjectives:Array<String>;

	public var playtime:Float;

	private var sessionStartTime:Float;

	public function new() {
		variables = new Map();
		party = ["lacie"];
		partyPositions = [{x: 0, y: 0}];
		currentObjectives = [];
		completedObjectives = [];
		failedObjectives = [];
		reset();
	}

	public function initSession():Void {
		sessionStartTime = Timer.stamp();
	}

	public function reset():Void {
		chapterName = "Chapter 1";
		location = "Unknown";
		room = "room";
		playtime = 0;
		sessionStartTime = Timer.stamp();
		party = ["lacie"];
		partyPositions = [{x: 0, y: 0}];
		variables.clear();
		currentObjectives = [];
		completedObjectives = [];
		failedObjectives = [];
	}

	public function getSlotInfo(slot:Int):SaveSlotData {
		var save = new FlxSave();
		save.bind("LilyEngine_Slot_" + slot);

		if (save.data.location == null)
			return getEmptySlot(slot);

		var d = save.data;
		return {
			id: "slot" + slot,
			slotNum: slot,
			location: d.location,
			chapterName: d.chapterName != null ? d.chapterName : "Chapter 1",
			playtime: d.playtime != null ? d.playtime : 0,
			party: d.party != null ? d.party : ["lacie"],
			partyPositions: d.partyPositions != null ? d.partyPositions : [
				{
					x: 0,
					y: 0
				}
			],
			room: d.room != null ? d.room : "room",
			inventory: d.inventory != null ? d.inventory : [],
			currentObjectives: d.currentObjectives != null ? d.currentObjectives : [],
			completedObjectives: d.completedObjectives != null ? d.completedObjectives : [],
			failedObjectives: d.failedObjectives != null ? d.failedObjectives : [],
			variables: d.variables != null ? d.variables : {},
			isEmpty: false
		};
	}

	private function getEmptySlot(slot:Int):SaveSlotData {
		return {
			id: "slot" + slot,
			slotNum: slot,
			location: "",
			chapterName: "",
			playtime: 0,
			party: ["lacie"],
			partyPositions: [{x: 0, y: 0}],
			room: "",
			inventory: [],
			currentObjectives: [],
			completedObjectives: [],
			failedObjectives: [],
			variables: {},
			isEmpty: true
		};
	}

	public function saveGame(slot:Int):Void {
		var save = new FlxSave();
		save.bind("LilyEngine_Slot_" + slot);

		var currentPlaytime = playtime + (Timer.stamp() - sessionStartTime);
		var currentRoom = RoomManager.currentRoomName != null ? RoomManager.currentRoomName : room;

		var currentPositions:Array<Position> = [];
		if (RoomManager.instance != null && RoomManager.instance.player != null) {
			currentPositions.push({x: RoomManager.instance.player.x, y: RoomManager.instance.player.y});
			for (member in RoomManager.instance.partyMembers) {
				currentPositions.push({x: member.x, y: member.y});
			}
		} else {
			currentPositions = partyPositions;
		}

		save.data.location = location;
		save.data.chapterName = chapterName;
		save.data.playtime = currentPlaytime;
		save.data.party = party;
		save.data.partyPositions = currentPositions;
		save.data.room = currentRoom;

		save.data.currentObjectives = currentObjectives;
		save.data.completedObjectives = completedObjectives;
		save.data.failedObjectives = failedObjectives;

		var savedVars:Dynamic = {};
		for (k in variables.keys())
			Reflect.setField(savedVars, k, variables.get(k));
		save.data.variables = savedVars;

		var savedInv:Array<SavedItem> = [];
		if (Game.instance != null) {
			for (id => amount in Game.items.inventory)
				savedInv.push({id: id, amount: amount});
		}
		save.data.inventory = savedInv;

		save.flush();

		playtime = currentPlaytime;
		sessionStartTime = Timer.stamp();
	}

	public function loadGame(slot:Int):Bool {
		var info = getSlotInfo(slot);
		if (info.isEmpty)
			return false;

		location = info.location;
		chapterName = info.chapterName;
		playtime = info.playtime;
		sessionStartTime = Timer.stamp();

		party = info.party;
		partyPositions = info.partyPositions;
		room = info.room;

		currentObjectives = info.currentObjectives;
		completedObjectives = info.completedObjectives;
		failedObjectives = info.failedObjectives;

		variables.clear();
		if (info.variables != null) {
			for (f in Reflect.fields(info.variables))
				variables.set(f, Reflect.field(info.variables, f));
		}

		if (Game.instance != null) {
			Game.items.inventory.clear();
			for (item in info.inventory)
				Game.items.inventory.set(item.id, item.amount);
		}

		return true;
	}

	public function setVariable(key:String, value:Dynamic):Void {
		variables.set(key, value);
	}

	public function getVariable(key:String):Dynamic {
		return variables.exists(key) ? variables.get(key) : null;
	}

	public function init(saveName:String) {
		FlxG.save.bind(saveName);
	}
}
