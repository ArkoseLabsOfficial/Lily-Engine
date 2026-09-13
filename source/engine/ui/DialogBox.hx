package engine.ui;

import engine.scripting.events.DialogEvents;

typedef DialogSelectionDef = {
	var ?id:String;
	var ?text:String;
	var ?translate:Array<String>;
}

typedef DialogEntryDef = {
	var ?name:String;
	var ?text:String;
	var ?translate:Array<String>;
	var ?selections:Array<DialogSelectionDef>;
}

enum DialogState {
	IDLE;
	TYPING;
	WAITING_INPUT;
	SELECTION;
}

class DialogBox extends SubStateBackend {
	public static var instance:DialogBox;

	var box:FlxSpriteGroup;

	var bg:ImprovedNinePatch;
	var nameText:LangText;
	var nameSeperator:FlxSprite;
	var bodyText:GameTypeText;
	var continueIcon:FlxSprite;
	var selectionMenu:DialogSelection;

	var jsonData:DynamicAccess<Array<DialogEntryDef>>;
	var currentEntries:Array<DialogEntryDef> = [];
	var index:Int = 0;
	var onCompleteCallback:Void->Void;

	var state:DialogState = IDLE;
	var lastTypingIndex:Int = -1;

	#if FEATURE_HSCRIPT
	var localDialogScript:Script = null;
	#end
	var id:String = "start";

	public function new(jsonPath:String, startDialogId:String, ?onComplete:Void->Void) {
		super(0x00000000);
		instance = this;
		id = startDialogId;
		onCompleteCallback = onComplete;

		if (jsonPath != "") {
			var rawText = Assets.getText('${Flags.dialogFolder}/$jsonPath.json');
			if (rawText != null) {
				try {
					jsonData = cast Json.parse(rawText);
				} catch (e:Dynamic) {
					FlxG.log.error(e);
				}
			}

			#if FEATURE_HSCRIPT
			localDialogScript = Script.create('${Flags.dialogFolder}/$jsonPath.hx');
			localDialogScript.setParent(this);
			localDialogScript.set("dialogBox", this);
			localDialogScript.load();
			#end
		}

		if (jsonData != null && startDialogId != "") {
			loadDialogSequence(startDialogId);
		}
	}

	override public function create():Void {
		super.create();

		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		Game.mobileC.removeJoyStick();
		#end

		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;
		FlxG.cameras.add(camMenu, false);
		cameras = [camMenu];

		box = new FlxSpriteGroup();
		add(box);

		bg = new ImprovedNinePatch(0, 0);
		bg.texture = 'ui/new/border';
		bg.bgTexture = 'ui/frames/frame_default_bg';
		bg.margin = {
			left: 10,
			right: 10,
			top: 10,
			bottom: 10
		}
		bg.scaleFactor = 2;
		bg.resize(1000, 270);
		bg.screenCenter(X);
		bg.y = FlxG.height - bg.height - 20;
		bg.scrollFactor.set(0, 0);
		box.add(bg);

		nameText = new LangText(bg.x + 20, bg.y - 5, 400, "", 50);
		nameText.setFont('AlegreyaSC');
		nameText.alignment = LEFT;
		nameText.scrollFactor.set(0, 0);
		box.add(nameText);

		nameSeperator = new FlxSprite(bg.x + 15, bg.y + 50);
		nameSeperator.loadGraphic(Assets.getImage("ui/dialogs/name_seperator"));
		nameSeperator.scale.set(1.025, 1.025);
		nameSeperator.scrollFactor.set(0, 0);
		box.add(nameSeperator);

		bodyText = new GameTypeText(bg.x + 20, bg.y + 65, "", 33);
		bodyText.maxWidth = Std.int(bg.width - 40);
		bodyText.wordWrap = true;
		bodyText.eraseDelay = 0;
		bodyText.showCursor = false;
		bodyText.scrollFactor.set(0, 0);
		bodyText.completeCallback = handleTextComplete;
		box.add(bodyText);

		// text sound lol
		var sound = new FlxSound();
		sound.loadEmbedded(Flags.TEXT_TYPING, false);
		bodyText.sounds = [sound];

		continueIcon = new FlxSprite(bg.x + bg.width - 120, bg.y + bg.height - 105);
		continueIcon.loadGraphic(Assets.getImage("ui/dialogs/continue_indicator"), true, 95, 95);
		continueIcon.animation.add("blink", [0, 1, 2, 1], 6, true);
		continueIcon.scrollFactor.set(0, 0);
		continueIcon.visible = false;
		box.add(continueIcon);

		selectionMenu = new DialogSelection(this);
		add(selectionMenu);

		var openEvt = new CancellableEvent();
		callScript("onOpen", [openEvt, id]);
		if (!openEvt.cancelled) {
			callScript("onOpenPost", [openEvt, id]);
			if (jsonData != null)
				playCurrentEntry();
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (state == TYPING) {
			var curLength:Int = Std.int(Reflect.getProperty(bodyText, "_typingIndex"));

			while (lastTypingIndex < curLength) {
				var nextIndex = lastTypingIndex + 1;
				var charEvt = new DialogCharTypedEvent();
				charEvt.preTextCharNum = lastTypingIndex;
				charEvt.nextTextCharNum = nextIndex;

				callScript("onCharTyped", [charEvt]);

				if (charEvt.cancelled) {
					bodyText.paused = true;
					break;
				} else {
					callScript("onCharTypedPost", [nextIndex]);
					lastTypingIndex = nextIndex;
				}
			}
		}

		var ptrPressed = false;
		#if FLX_MOUSE
		if (FlxG.mouse.justPressed)
			ptrPressed = true;
		#end
		#if FLX_TOUCH
		for (touch in FlxG.touches.list) {
			if (touch.justPressed)
				ptrPressed = true;
		}
		#end

		if ((Controls.BACK || ptrPressed) && state == TYPING) {
			var skipEvt = new CancellableEvent();
			callScript("onSkip", [skipEvt]);
			if (!skipEvt.cancelled) {
				bodyText.skip();
				bodyText.paused = false;
				callScript("onSkipPost", [skipEvt]);
			}
		} else if ((Controls.ACCEPT || ptrPressed) && state == WAITING_INPUT) {
			var confirmEvt = new CancellableEvent();
			callScript("onConfirm", [confirmEvt]);
			if (!confirmEvt.cancelled) {
				callScript("onConfirmPost", [confirmEvt]);
				continueIcon.visible = false;
				progressDialog();
			}
		}
	}

	function loadDialogSequence(id:String):Void {
		this.id = id;
		index = 0;
		currentEntries = [];
		if (jsonData != null && jsonData.exists(id)) {
			currentEntries = jsonData.get(id);
		}
	}

	public function formatText(text:String, ?translate:Array<String>):String {
		var r = new EReg("\\$\\{([^}]+)\\}", "g");
		var transReg = new EReg("^translate\\[(\\d+)\\]$", "");

		return r.map(text, function(e:EReg):String {
			var match = e.matched(1);

			if (translate != null && transReg.match(match)) {
				var idx = Std.parseInt(transReg.matched(1));
				if (idx != null && idx >= 0 && idx < translate.length) {
					return Lang.get(translate[idx]);
				}
			}

			var val = Game.save.getVariable(match);
			return val != null ? Std.string(val) : "";
		});
	}

	function playCurrentEntry():Void {
		if (index >= currentEntries.length) {
			shutdownDialog();
			return;
		}

		var entry = currentEntries[index];
		var textKey = entry.text != null ? entry.text : "";

		if (textKey == "" && entry.selections != null) {
			triggerSelections(entry);
			return;
		}

		var textEvt = new DialogEntryEvent();
		textEvt.entry = entry;
		textEvt.text = textKey;

		callScript("onTextStart", [textEvt]);
		if (textEvt.cancelled)
			return;

		var localizedText = formatText(Lang.get(textEvt.text), entry.translate);
		var localizedName = Lang.get(entry.name);

		var localizedEvt = new DialogEntryEvent();
		localizedEvt.entry = entry;
		localizedEvt.entry.name = localizedName;
		localizedEvt.text = localizedText;
		callScript("onTextStartPost", [localizedEvt]);

		nameText.text = localizedEvt.entry.name != null ? localizedEvt.entry.name : "";
		nameText.visible = nameSeperator.visible = (nameText.text != "");
		bodyText.y = nameText.visible ? (bg.y + 65) : (bg.y + 15);

		state = TYPING;
		lastTypingIndex = -1;
		continueIcon.visible = false;

		bodyText.resetText(localizedEvt.text);
		bodyText.start(0.03, true);
	}

	function handleTextComplete():Void {
		state = WAITING_INPUT;
		continueIcon.visible = true;
		continueIcon.animation.play("blink");

		var compEvt = new CancellableEvent();
		callScript("onTextComplete", [compEvt]);
		if (!compEvt.cancelled) {
			callScript("onTextCompletePost", [compEvt]);
		}
	}

	function progressDialog():Void {
		var entry = currentEntries[index];

		if (entry.selections != null) {
			triggerSelections(entry);
			return;
		}

		index++;
		playCurrentEntry();
	}

	function triggerSelections(entry:DialogEntryDef):Void {
		state = SELECTION;
		var options:Array<DialogSelectionDef> = entry.selections;
		selectionMenu.triggerOpen(options, function(choiceIndex:Int) {
			index++;
			playCurrentEntry();
		});
	}

	function shutdownDialog():Void {
		var closeEvt = new CancellableEvent();
		callScript("onClose", [closeEvt]);

		if (!closeEvt.cancelled) {
			callScript("onClosePost", [closeEvt]);

			#if FEATURE_HSCRIPT
			if (localDialogScript != null) {
				localDialogScript.destroy();
				localDialogScript = null;
			}
			#end

			if (onCompleteCallback != null)
				onCompleteCallback();
			close();
		}
	}

	public function callScript(func:String, args:Array<Dynamic>):Void {
		#if FEATURE_HSCRIPT
		if (localDialogScript != null)
			localDialogScript.call(func, args);
		#end
	}
}
