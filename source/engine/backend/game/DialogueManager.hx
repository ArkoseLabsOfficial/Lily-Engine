package engine.backend.game;

import engine.scripting.EventManager;
import engine.scripting.events.DialogEvents;
import haxe.DynamicAccess;

typedef DialogSelectionDef = {
	var ?id:String;
	var ?text:String;
	var ?target:String;
	var ?setFlag:String;
	var ?condIf:String;
	var ?condUnless:String;
	var ?script:String;
}

typedef DialogEntryDef = {
	var ?name:String;
	var ?text:String;
	var ?leftChar:String;
	var ?rightChar:String;
	var ?selections:Array<DialogSelectionDef>;
	var ?close:Bool;
	var ?target:String;
	var ?script:String;
	var ?setFlag:String;
	var ?condIf:String;
	var ?condUnless:String;
}

class DialogueManager extends SubStateBackend {
	public static var instance:DialogueManager;

	var dialogBox:DialogBox;

	public var portraitLeft:FlxSprite;
	public var portraitRight:FlxSprite;
	public var leftBaseX:Float = 0;
	public var leftBaseY:Float = 0;
	public var rightBaseX:Float = 1400;
	public var rightBaseY:Float = 0;

	public var selectionMenu:DialogSelection;
	public var dialogCamera:FlxCamera;

	var jsonData:DynamicAccess<Array<DialogEntryDef>>;
	var currentEntries:Array<DialogEntryDef> = [];
	var entryIndex:Int = 0;
	var onCompleteCallback:Void->Void;

	var waitingForInput:Bool = false;

	public var isPaused:Bool = false;

	var localDialogScript:Script = null;

	public function injectScriptVariables():Void {
		#if FEATURE_HSCRIPT
		function set(name:String, thing:Dynamic) {
			localDialogScript.set(name, thing);
		}
		set("room", RoomManager.instance);
		set("player", RoomManager.instance.player);
		set("parent", engine.states.BaseRoom.instance);
		set("changeLayer", RoomManager.instance.changeLayer);
		set("addItem", Game.itemsData.addItem);
		set("removeItem", Game.itemsData.removeItem);
		set("getOwnedAmount", Game.itemsData.getOwnedAmount);
		set("lockPlayer", function(locked:Bool = true) {
			if (RoomManager.instance.player != null) {
				RoomManager.instance.player.canMove = !locked;
				if (locked)
					RoomManager.instance.player.velocity.set(0, 0);
			}
		});

		set("wait", function(time:Float, cb:Dynamic) {
			new FlxTimer().start(time, function(_) {
				if (cb != null)
					Reflect.callMethod(null, cb, []);
			});
		});

		set("walkEntity", function(id:String, x:Float, y:Float, speed:Float, cb:Dynamic) {
			var ent:engine.objects.CharacterEntity = null;

			if (id == "player" && RoomManager.instance.player != null)
				ent = RoomManager.instance.player;
			else if (RoomManager.instance.characters.exists(id))
				ent = RoomManager.instance.characters.get(id);
			else if (RoomManager.instance.entities.exists(id) && Std.isOfType(RoomManager.instance.entities.get(id), CharacterEntity)) {
				ent = cast RoomManager.instance.entities.get(id);
			}

			if (ent != null) {
				ent.walkTo(x, y, speed, function() {
					if (cb != null)
						cb();
				});
			} else {
				FlxG.log.warn('walkEntity: Character "' + id + '" not found or is not a CharacterEntity.');
				if (cb != null)
					cb();
			}
		});

		set("faceEntity", function(id:String, dir:String) {
			var ent:CharacterEntity = null;

			if (id == "player" && RoomManager.instance.player != null)
				ent = RoomManager.instance.player;
			else if (RoomManager.instance.characters.exists(id))
				ent = RoomManager.instance.characters.get(id);
			else if (RoomManager.instance.entities.exists(id) && Std.isOfType(RoomManager.instance.entities.get(id), CharacterEntity)) {
				ent = cast RoomManager.instance.entities.get(id);
			}

			if (ent != null) {
				var d = CharacterEntity.FacingDirection.DOWN;
				switch (dir.toLowerCase()) {
					case "up":
						d = UP;
					case "down":
						d = DOWN;
					case "left":
						d = LEFT;
					case "right":
						d = RIGHT;
				}
				ent.currentFacing = d;
				ent.updateAnimations();
			}
		});

		set("setCameraTarget", function(id:String) {
			var target:FlxObject = null;

			if (id == "player" && RoomManager.instance.player != null)
				target = RoomManager.instance.player;
			else if (RoomManager.instance.characters.exists(id))
				target = RoomManager.instance.characters.get(id);
			else if (RoomManager.instance.entities.exists(id))
				target = RoomManager.instance.entities.get(id);

			if (target != null) {
				BaseRoom.instance.followTheObject(target, "NO_DEAD_ZONE", 1);
			} else {
				FlxG.log.warn('setCameraTarget: Target "' + id + '" not found.');
			}
		});

		for (key => val in RoomManager.instance.entities)
			set(key, val);
		for (key => val in RoomManager.instance.characters)
			if (!RoomManager.instance.entities.exists(key))
				set(key, val);
		#end
	}

	public function new(jsonPath:String, startDialogId:String, ?onComplete:Void->Void) {
		super(0x00000000);
		instance = this;
		onCompleteCallback = onComplete;

		if (jsonPath != "") {
			var rawText = LilyAssets.getTextFromFile('dialogues/$jsonPath.json');
			if (rawText != null) {
				try {
					jsonData = cast Json.parse(rawText);
				} catch (e:Dynamic) {
					FlxG.log.error(e);
				}
			}

			localDialogScript = Script.create('dialogues/$jsonPath.hx');
			injectScriptVariables();
			localDialogScript.set("dialog", this);
			localDialogScript.load();
			localDialogScript.call("create");
		}

		if (jsonData != null && startDialogId != "") {
			jumpToDialog(startDialogId);
		}
	}

	override public function create():Void {
		super.create();
		#if FEATURE_TOUCH_CONTROLS
		Main.mobileControls.removeButton();
		Main.mobileControls.removeDPad();
		Main.mobileControls.removeJoyStick();
		#end

		dialogCamera = new FlxCamera();
		dialogCamera.bgColor.alpha = 0;
		FlxG.cameras.add(dialogCamera, false);
		cameras = [dialogCamera];
		dialogCamera.zoom = 1;

		portraitLeft = new FlxSprite(leftBaseX, leftBaseY);
		portraitLeft.antialiasing = true;
		portraitLeft.scrollFactor.set(0, 0);
		add(portraitLeft);

		portraitRight = new FlxSprite(rightBaseX, rightBaseY);
		portraitRight.antialiasing = true;
		portraitRight.flipX = true;
		portraitRight.scrollFactor.set(0, 0);
		add(portraitRight);

		dialogBox = new DialogBox();
		if (localDialogScript != null)
			localDialogScript.set("dialogBox", dialogBox);
		add(dialogBox);

		selectionMenu = new DialogSelection(this);
		if (localDialogScript != null)
			localDialogScript.set("selectionMenu", selectionMenu);
		add(selectionMenu);

		if (localDialogScript != null)
			localDialogScript.call("postCreate");

		if (jsonData != null) {
			playCurrentEntry();
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		var pointerJustPressed = false;
		var touchJustPressed = false;

		#if FLX_MOUSE
		if (FlxG.mouse.justPressed)
			pointerJustPressed = true;
		#end

		#if FLX_TOUCH
		for (touch in FlxG.touches.list) {
			if (touch.justPressed)
				touchJustPressed = true;
		}
		#end

		if (!isPaused && waitingForInput && !selectionMenu.activeMenu && (Controls.ACCEPT || pointerJustPressed || touchJustPressed)) {
			if (dialogBox.advance()) {
				handleEntryEnd(currentEntries[entryIndex]);
			}
		}
	}

	public function updatePortrait(sprite:FlxSprite, path:String, baseX:Float, baseY:Float):Void {
		if (path == null || path == "") {
			sprite.visible = false;
		} else {
			sprite.loadGraphic(LilyAssets.image(path));
			sprite.updateHitbox();
			sprite.x = baseX;
			sprite.y = baseY;
			sprite.visible = true;
		}
	}

	public function pause() {
		isPaused = true;
	}

	public function resume() {
		isPaused = false;
		if (!waitingForInput)
			playCurrentEntry();
	}

	public static function showStandaloneChoices(options:Array<String>, onSelect:Int->Void):Void {
		var menu = new DialogueManager("", "");
		FlxG.state.openSubState(menu);
		menu.selectionMenu.show(options, function(idx) {
			onSelect(idx);
			menu.close();
		});
	}

	function jumpToDialog(id:String):Void {
		entryIndex = 0;
		currentEntries = [];

		if (localDialogScript != null) {
			var evt = EventManager.get(DialogJumpEvent);
			evt.dialogId = id;
			localDialogScript.event("onDialogJump", evt);
			if (evt.cancelled)
				return;
			id = evt.dialogId;
		}

		if (jsonData == null || !jsonData.exists(id))
			return;

		var arr:Array<DialogEntryDef> = jsonData.get(id);
		if (arr != null) {
			for (i in 0...arr.length)
				currentEntries.push(arr[i]);
		}
	}

	function formatText(text:String):String {
		var r = new EReg("\\{([^}]+)\\}", "g");
		return r.map(text, function(e:EReg):String {
			var key = e.matched(1);
			var val = Game.saveData.getVariable(key);
			return val != null ? Std.string(val) : "";
		});
	}

	function playCurrentEntry():Void {
		if (isPaused)
			return;

		if (entryIndex >= currentEntries.length) {
			closeDialogue();
			return;
		}

		var entry = currentEntries[entryIndex];

		if (entry.condIf != null && !evaluateLogic(entry.condIf)) {
			entryIndex++;
			playCurrentEntry();
			return;
		}

		if (entry.condUnless != null && evaluateLogic(entry.condUnless)) {
			entryIndex++;
			playCurrentEntry();
			return;
		}

		if (Reflect.hasField(entry, "function") && localDialogScript != null) {
			injectScriptVariables();
			localDialogScript.call(Reflect.field(entry, "function"));
			if (isPaused)
				return;
		}

		if (entry.setFlag != null)
			applySetFlag(entry.setFlag);

		var charName = entry.name != null ? entry.name : "";
		var textKey = entry.text != null ? entry.text : "";

		if (textKey == "" && entry.selections != null) {
			showSelections(entry);
			return;
		}

		var localizedText = Game.languageData.getCaption(textKey);
		if (Game.languageData.getDialogCaption(textKey)[1] == true) {
			localizedText = Game.languageData.getDialogCaption(textKey)[0];
		}

		localizedText = formatText(localizedText);

		if (localDialogScript != null) {
			var evt = EventManager.get(DialogEntryEvent);
			evt.entry = entry;
			evt.text = localizedText;
			localDialogScript.event("onDialogEntry", evt);
			if (evt.cancelled)
				return;
			entry = cast evt.entry;
			localizedText = evt.text;
		}

		var leftPath = (entry.leftChar != null && entry.leftChar != "none") ? "dialogs/characters/" + entry.leftChar : "";
		var rightPath = (entry.rightChar != null && entry.rightChar != "none") ? "dialogs/characters/" + entry.rightChar : "";

		dialogBox.show(charName, localizedText, leftPath, rightPath);
		waitingForInput = true;
	}

	function handleEntryEnd(entry:DialogEntryDef):Void {
		waitingForInput = false;

		if (entry.selections != null) {
			showSelections(entry);
			return;
		}

		if (entry.close != null && entry.close == true) {
			closeDialogue();
			return;
		}

		if (entry.target != null) {
			jumpToDialog(entry.target);
			playCurrentEntry();
			return;
		}

		entryIndex++;
		playCurrentEntry();
	}

	function showSelections(entry:DialogEntryDef):Void {
		var options:Array<String> = [];
		var validItems:Array<DialogSelectionDef> = [];

		if (entry.selections != null) {
			for (item in entry.selections) {
				if (item.condIf != null && !evaluateLogic(item.condIf))
					continue;
				if (item.condUnless != null && evaluateLogic(item.condUnless))
					continue;
				validItems.push(item);
			}
		}

		if (localDialogScript != null) {
			var evt = EventManager.get(DialogSelectionEvent);
			evt.selections = validItems;
			localDialogScript.event("onBuildSelections", evt);
			if (evt.cancelled)
				return;
			validItems = cast evt.selections;
		}

		for (item in validItems) {
			var textKey = item.text != null ? item.text : "";
			var localizedText = Game.languageData.getCaption(textKey);
			if (Game.languageData.getDialogCaption(textKey)[1] == true) {
				localizedText = Game.languageData.getDialogCaption(textKey)[0];
			}
			localizedText = formatText(localizedText);
			options.push(localizedText);
		}

		selectionMenu.show(options, function(choiceIndex:Int) {
			var chosenItem = validItems[choiceIndex];

			if (chosenItem.id != null) {
				Game.saveData.setFlag(chosenItem.id, true);
				Game.saveData.setVariable(chosenItem.id, options[choiceIndex]);
			}

			if (chosenItem.setFlag != null)
				applySetFlag(chosenItem.setFlag);

			trace(chosenItem.script);
			if (chosenItem.script != null && localDialogScript != null) {
				localDialogScript.call(chosenItem.script);
			}

			if (chosenItem.target != null) {
				jumpToDialog(chosenItem.target);
				playCurrentEntry();
			} else {
				entryIndex++;
				playCurrentEntry();
			}
		});
	}

	function applySetFlag(flagStr:String):Void {
		var parts = flagStr.split("=");
		var key = StringTools.trim(parts[0]);
		var val = true;

		if (parts.length > 1) {
			var valStr = StringTools.trim(parts[1]).toLowerCase();
			if (valStr == "false")
				val = false;
		}

		Game.saveData.setFlag(key, val);
	}

	function closeDialogue():Void {
		if (localDialogScript != null) {
			localDialogScript.destroy();
			localDialogScript = null;
		}

		dialogBox.hide(function() {
			if (onCompleteCallback != null)
				onCompleteCallback();
			close();
		});
	}

	function evaluateLogic(condition:String):Bool {
		if (condition == null || condition == "")
			return true;
		condition = StringTools.replace(condition, " ", "");
		if (condition.indexOf("||") != -1) {
			var parts = condition.split("||");
			for (p in parts)
				if (evalSingle(p))
					return true;
			return false;
		}
		if (condition.indexOf("&&") != -1) {
			var parts = condition.split("&&");
			for (p in parts)
				if (!evalSingle(p))
					return false;
			return true;
		}
		return evalSingle(condition);
	}

	function evalSingle(cond:String):Bool {
		var invert = StringTools.startsWith(cond, "!");
		if (invert)
			cond = cond.substring(1);
		var val = Game.saveData.getFlag(cond);
		return invert ? !val : val;
	}
}
