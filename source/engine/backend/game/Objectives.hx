package engine.backend.game;

import io.FileSystem;
import lang.Lang;

using StringTools;

class Objectives {
	public var objectives:Map<String, Objective>;

	private var _objectivesUpdated:Bool = false;

	private var currentObjectives(get, never):Array<String>;

	private function get_currentObjectives()
		return Game.save.currentObjectives;

	private var completedObjectives(get, never):Array<String>;

	private function get_completedObjectives()
		return Game.save.completedObjectives;

	private var failedObjectives(get, never):Array<String>;

	private function get_failedObjectives()
		return Game.save.failedObjectives;

	public function new() {
		init();
	}

	public function init():Void {
		objectives = new Map<String, Objective>();
		var order:Int = 0;

		var files:Array<String> = [];

		if (Assets.exists(Flags.objectiveFolder) && Assets.isDirectory(Flags.objectiveFolder)) {
			files = Assets.readDirectory(Flags.objectiveFolder);
		}

		for (file in files) {
			if (!file.endsWith(".json"))
				continue;

			var rawJson = Assets.getText(Flags.objectiveFolder + file);

			if (rawJson == null)
				continue;

			var parsedFile:Dynamic = null;
			try {
				parsedFile = Json.parse(rawJson);
			} catch (e:Dynamic) {
				FlxG.log.error("Failed to parse objective JSON: " + file);
				continue;
			}

			if (parsedFile == null || parsedFile.Objectives == null)
				continue;

			var groupName = file.substring(0, file.lastIndexOf("."));

			for (objDto in (parsedFile.Objectives : Array<ObjectiveData>)) {
				parseObjectiveFromDto(objDto, objDto.Id, groupName, null, order);
				order++;
			}
		}
	}

	private function parseObjectiveFromDto(dto:ObjectiveData, id:String, group:String, parent:Objective, currentOrder:Int):Objective {
		var obj = new Objective();
		obj.id = id;
		obj.group = group;
		obj.order = currentOrder;

		// Strictly use language system identifiers instead of parsing strings from JSON
		obj.name = 'objectives.name.${obj.id}';
		obj.description = 'objectives.desc.${obj.id}';

		obj.hidden = dto.Hidden != null ? dto.Hidden : false;
		obj.onComplete = dto.OnComplete != null ? dto.OnComplete : [];
		obj.parent = parent;

		if (dto.Children != null) {
			for (childDto in dto.Children) {
				obj.children.push(parseObjectiveFromDto(childDto, obj.id + "." + childDto.Id, group, obj, currentOrder));
			}
		}

		objectives.set(obj.id, obj);
		return obj;
	}

	public function insterCustomObjective(objective:Objective):Void {
		objectives.set(objective.id, objective);
	}

	public function insertCustomObjective(objective:Objective):Void {
		insterCustomObjective(objective);
	}

	public function addObjective(objectiveId:String):Void {
		if (!isObjectiveValid(objectiveId)) {
			FlxG.log.error("Attempting to add an invalid objective: " + objectiveId);
			return;
		}
		_addObjective(objectives.get(objectiveId), false);
	}

	private function _addObjective(objective:Objective, isChildCall:Bool = false):Void {
		if (objective.hasParent() && !isChildCall) {
			_addObjective(objective.parent, false);
			if (!currentObjectives.contains(objective.parent.id))
				return;
		}
		if (!currentObjectives.contains(objective.id)
			&& !completedObjectives.contains(objective.id)
			&& !failedObjectives.contains(objective.id)) {
			currentObjectives.push(objective.id);
			_objectivesUpdated = true;

			if (!isChildCall) {
				FlxG.state.add(new ObjectivePopUp("Added", Lang.get(objective.name)));
			}

			if (objective.hasChildren()) {
				for (child in objective.children) {
					_addObjective(child, true);
				}
			}
		}
	}

	public function removeObjective(objectiveId:String):Void {
		if (!isObjectiveValid(objectiveId)) {
			FlxG.log.error("Attempting to remove an invalid objective: " + objectiveId);
			return;
		}
		_removeObjective(objectives.get(objectiveId));
	}

	private function _removeObjective(objective:Objective):Void {
		currentObjectives.remove(objective.id);
		if (objective.hasChildren()) {
			for (child in objective.children) {
				if (currentObjectives.contains(child.id))
					_removeObjective(child);
			}
		}
		if (objective.hasParent() && !objectiveHasPendingChildren(objective.parent)) {
			_removeObjective(objective.parent);
		}
	}

	public function completeObjective(objectiveId:String):Void {
		if (!isObjectiveValid(objectiveId)) {
			FlxG.log.error("Attempting to complete an invalid objective: " + objectiveId);
			return;
		}
		_completeObjective(objectives.get(objectiveId));
	}

	private function _completeObjective(objective:Objective):Void {
		if (completedObjectives.contains(objective.id) || failedObjectives.contains(objective.id))
			return;

		currentObjectives.remove(objective.id);
		completedObjectives.push(objective.id);

		FlxG.state.add(new ObjectivePopUp("Completed", Lang.get(objective.name)));

		if (objective.hasChildren()) {
			for (child in objective.children) {
				if (currentObjectives.contains(child.id))
					_completeObjective(child);
			}
		}
		if (objective.hasParent() && !objectiveHasPendingChildren(objective.parent)) {
			_completeObjective(objective.parent);
		}
		for (triggeredId in objective.onComplete) {
			addObjective(triggeredId);
		}
	}

	public function failObjective(objectiveId:String):Void {
		if (!isObjectiveValid(objectiveId)) {
			trace("Attempting to fail an invalid objective: " + objectiveId);
			return;
		}
		_failObjective(objectives.get(objectiveId));
	}

	private function _failObjective(objective:Objective):Void {
		if (completedObjectives.contains(objective.id) || failedObjectives.contains(objective.id))
			return;

		currentObjectives.remove(objective.id);
		failedObjectives.push(objective.id);

		FlxG.state.add(new ObjectivePopUp("Failed", Lang.get(objective.name)));

		if (objective.hasChildren()) {
			for (child in objective.children) {
				if (currentObjectives.contains(child.id))
					_failObjective(child);
			}
		}
		if (objective.hasParent() && !objectiveHasPendingChildren(objective.parent)) {
			_failObjective(objective.parent);
		}
	}

	public function getCurrentObjectives():Array<Objective> {
		var activeList:Array<Objective> = [];
		for (objId in currentObjectives) {
			if (objectives.exists(objId)) {
				var obj = objectives.get(objId);
				if (!obj.hidden && !obj.hasParent()) {
					activeList.push(obj);
				}
			}
		}
		activeList.sort(function(x, y) return x.order - y.order);
		return activeList;
	}

	public function getCompletedObjectives():Array<Objective> {
		var list:Array<Objective> = [];
		for (objId in completedObjectives) {
			if (objectives.exists(objId)) {
				list.push(objectives.get(objId));
			}
		}
		list.sort(function(x, y) return x.order - y.order);
		return list;
	}

	public function getFailedObjectives():Array<Objective> {
		var list:Array<Objective> = [];
		for (objId in failedObjectives) {
			if (objectives.exists(objId)) {
				list.push(objectives.get(objId));
			}
		}
		list.sort(function(x, y) return x.order - y.order);
		return list;
	}

	public function getAllObjectives():Array<Objective> {
		var list:Array<Objective> = [];
		for (obj in objectives)
			list.push(obj);
		list.sort(function(x, y) return x.order - y.order);
		return list;
	}

	public function clearObjectives():Void {
		while (currentObjectives.length > 0)
			currentObjectives.pop();
	}

	public function silenceNotifications():Void {
		_objectivesUpdated = false;
	}

	public function isObjectiveInProgress(objectiveId:String):Bool {
		return currentObjectives.contains(objectiveId);
	}

	public function isObjectiveCompleted(objectiveId:String):Bool {
		return completedObjectives.contains(objectiveId);
	}

	public function isObjectiveFailed(objectiveId:String):Bool {
		return failedObjectives.contains(objectiveId);
	}

	public function isObjectiveValid(objectiveId:String):Bool {
		return objectives.exists(objectiveId);
	}

	public function objectiveHasPendingChildren(objective:Objective):Bool {
		if (objective.hasChildren()) {
			for (child in objective.children) {
				if (!isObjectiveCompleted(child.id) && !isObjectiveFailed(child.id)) {
					return true;
				}
				if (objectiveHasPendingChildren(child)) {
					return true;
				}
			}
		}
		return false;
	}
}
