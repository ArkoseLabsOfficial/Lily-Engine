package engine.backend.game;

import lang.Lang;

typedef DialogSelectionDef = {
	var ?id:String;
	var ?text:String;
}

typedef DialogEntryDef = {
	var ?name:String;
	var ?text:String;
	var ?leftChar:String;
	var ?rightChar:String;
	var ?selections:Array<DialogSelectionDef>;
	var ?close:Bool;
	@:optional @:native("function") var func:String;
	var ?postFunction:String;
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

	var pendingEntryEnd:Bool = false;

	public var isPaused:Bool = false;

	private var lastTypingIndex:Int = -1;

	#if FEATURE_HSCRIPT
	var localDialogScript:engine.scripting.Script = null;
	#end

	public function new(jsonPath:String, startDialogId:String, ?onComplete:Void->Void) {
		super(0x00000000);
		instance = this;
		onCompleteCallback = onComplete;

		if (jsonPath != "") {
			var rawText = LilyAssets.getTextFromFile('${Flags.dialogFolder}$jsonPath.json');
			if (rawText != null) {
				try {
					jsonData = cast Json.parse(rawText);
				} catch (e:Dynamic) {
					FlxG.log.error(e);
				}
			}

			#if FEATURE_HSCRIPT
			localDialogScript = engine.scripting.Script.create('${Flags.dialogFolder}$jsonPath.hx');
			Game.instance.bindToScript(localDialogScript);
			localDialogScript.set("dialog", this);
			localDialogScript.load();
			localDialogScript.call("create");
			#end
		}

		if (jsonData != null && startDialogId != "")
			jumpToDialog(startDialogId);
	}

	override public function create():Void {
		super.create();
		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		Game.mobileC.removeJoyStick();
		#end

		dialogCamera = new FlxCamera();
		dialogCamera.bgColor.alpha = 0;
		FlxG.cameras.add(dialogCamera, false);
		cameras = [dialogCamera];

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
		selectionMenu = new DialogSelection(this);
		add(dialogBox);
		add(selectionMenu);

		#if FEATURE_HSCRIPT
		if (localDialogScript != null) {
			localDialogScript.set("dialogBox", dialogBox);
			localDialogScript.set("selectionMenu", selectionMenu);
			localDialogScript.call("postCreate");
		}
		#end

		if (jsonData != null)
			playCurrentEntry();
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		#if FEATURE_HSCRIPT
		if (dialogBox.isTyping && localDialogScript != null) {
			var curLength:Int = Std.int(Reflect.getProperty(dialogBox,
				"bodyText") != null ? Reflect.getProperty(Reflect.getProperty(dialogBox, "bodyText"), "_typingIndex") : 0);
			var fullLength:Int = Std.int(Reflect.getProperty(dialogBox,
				"bodyText") != null ? Reflect.getProperty(Reflect.getProperty(dialogBox, "bodyText"), "text").length : 0);

			if (curLength != lastTypingIndex) {
				lastTypingIndex = curLength;
				localDialogScript.call("onTalking", [curLength, fullLength]);
			}
		}
		#end

		var ptrPressed = false;
		#if FLX_MOUSE
		if (FlxG.mouse.justPressed)
			ptrPressed = true;
		#end
		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
			if (touch.justPressed)
				ptrPressed = true;
		#end

		if (!isPaused && waitingForInput && !selectionMenu.activeMenu && (Controls.ACCEPT || ptrPressed)) {
			if (dialogBox.advance()) {
				handleEntryEnd(currentEntries[entryIndex]);
			}
		}
	}

	public function pauseText(time:Float):Void {
		if (dialogBox != null)
			dialogBox.pauseTyping(time);
	}

	public function updatePortrait(sprite:FlxSprite, path:String, baseX:Float, baseY:Float):Void {
		if (path == null || path == "") {
			sprite.visible = false;
		} else {
			sprite.loadGraphic(LilyAssets.image(path));
			sprite.updateHitbox();
			sprite.setPosition(baseX, baseY);
			sprite.visible = true;
		}
	}

	public function pause() {
		isPaused = true;
	}

	public function resume() {
		isPaused = false;

		if (pendingEntryEnd) {
			pendingEntryEnd = false;
			handleEntryEnd(currentEntries[entryIndex]);
		} else if (!waitingForInput) {
			playCurrentEntry();
		}
	}

	public function jumpToDialog(id:String):Void {
		entryIndex = 0;
		currentEntries = [];

		if (jsonData == null || !jsonData.exists(id))
			return;
		var arr = jsonData.get(id);
		if (arr != null)
			for (i in 0...arr.length)
				currentEntries.push(arr[i]);
	}

	function formatText(text:String):String {
		var r = new EReg("\\{([^}]+)\\}", "g");
		return r.map(text, function(e:EReg):String {
			var val = Game.save.getVariable(e.matched(1));
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
		lastTypingIndex = -1;

		#if FEATURE_HSCRIPT
		if (Reflect.hasField(entry, "func") && localDialogScript != null) {
			localDialogScript.call(entry.func);
			if (isPaused)
				return;
		}
		#end

		var charName = entry.name != null ? entry.name : "";
		var textKey = entry.text != null ? entry.text : "";

		if (textKey == "" && entry.selections != null) {
			showSelections(entry);
			return;
		}

		var localizedText = Lang.get(textKey);
		localizedText = formatText(localizedText);

		var leftPath = (entry.leftChar != null && entry.leftChar != "none") ? "dialogs/characters/" + entry.leftChar : "";
		var rightPath = (entry.rightChar != null && entry.rightChar != "none") ? "dialogs/characters/" + entry.rightChar : "";

		dialogBox.show(charName, localizedText, leftPath, rightPath);
		waitingForInput = true;
	}

	function handleEntryEnd(entry:DialogEntryDef):Void {
		waitingForInput = false;

		#if FEATURE_HSCRIPT
		if (entry.postFunction != null && localDialogScript != null) {
			localDialogScript.call(entry.postFunction);
		}
		#end

		if (entry.selections != null) {
			showSelections(entry);
			return;
		}

		if (entry.close != null && entry.close == true) {
			closeDialogue();
			return;
		}

		entryIndex++;
		playCurrentEntry();
	}

	function showSelections(entry:DialogEntryDef):Void {
		var options:Array<String> = [];

		for (item in entry.selections) {
			var textKey = item.text != null ? item.text : "";
			var localizedText = Lang.get(textKey);
			options.push(formatText(localizedText));
		}

		selectionMenu.show(options, function(choiceIndex:Int) {
			var chosenItem = entry.selections[choiceIndex];

			#if FEATURE_HSCRIPT
			if (localDialogScript != null) {
				localDialogScript.call("onSelection", [chosenItem.id, choiceIndex]);
			}
			#end

			entryIndex++;
			playCurrentEntry();
		});
	}

	function closeDialogue():Void {
		#if FEATURE_HSCRIPT
		if (localDialogScript != null) {
			localDialogScript.destroy();
			localDialogScript = null;
		}
		#end

		dialogBox.hide(function() {
			if (onCompleteCallback != null)
				onCompleteCallback();
			close();
		});
	}
}
