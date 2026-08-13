package engine.ui;

import engine.scripting.events.DialogEvents;

typedef DialogSelectionDef = {
    var ?id:String;
    var ?text:String;
}

typedef DialogEntryDef = {
    var ?name:String;
    var ?text:String;
    var ?selections:Array<DialogSelectionDef>;
    var ?close:Bool;
}

enum DialogState {
    IDLE;
    TYPING;
    WAITING_INPUT;
    SELECTION;
}

class DialogBox extends SubStateBackend {
    public static var instance:DialogBox;

    var bg:FlxSprite;
    var nameText:FlxText;
    var nameSeperator:FlxSprite;
    var bodyText:FlxTypeText;
    var continueIcon:FlxSprite;
    var selectionMenu:DialogSelection;

    var jsonData:DynamicAccess<Array<DialogEntryDef>>;
    var currentEntries:Array<DialogEntryDef> = [];
    var entryIndex:Int = 0;
    var onCompleteCallback:Void->Void;
    
    var state:DialogState = IDLE;
    var lastTypingIndex:Int = -1;

    #if FEATURE_HSCRIPT
    var localDialogScript:Script = null;
    #end

    public function new(jsonPath:String, startDialogId:String, ?onComplete:Void->Void) {
        super(0x00000000);
        instance = this;
        onCompleteCallback = onComplete;

        if (jsonPath != "") {
            var rawText = Assets.getText('${Flags.dialogFolder}$jsonPath.json');
            if (rawText != null) {
                try {
                    jsonData = cast Json.parse(rawText);
                } catch (e:Dynamic) {
                    FlxG.log.error(e);
                }
            }

            #if FEATURE_HSCRIPT
            localDialogScript = Script.create('${Flags.dialogFolder}$jsonPath.hx');
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

        bg = new FlxSprite(0, 0).loadGraphic(Assets.getImage("ui/dialogs/dialogue"));
        bg.screenCenter(X);
        bg.y = FlxG.height - bg.height - 20;
        bg.scrollFactor.set(0, 0);
        add(bg);

        nameText = new FlxText(bg.x + 120, bg.y + 45, 400, "", 36);
        nameText.alignment = LEFT;
        nameText.scrollFactor.set(0, 0);
        add(nameText);

        nameSeperator = new FlxSprite(bg.x + 100, bg.y + 80);
        nameSeperator.loadGraphic(Assets.getImage("ui/dialogs/name_seperator"));
        nameSeperator.scale.set(1.025, 1.025);
        nameSeperator.scrollFactor.set(0, 0);
        add(nameSeperator);

        bodyText = new FlxTypeText(bg.x + 120, bg.y + 105, Std.int(bg.width - 160), "", 33);
        bodyText.eraseDelay = 0;
        bodyText.showCursor = false;
        bodyText.scrollFactor.set(0, 0);
        bodyText.completeCallback = handleTextComplete;
        add(bodyText);

        continueIcon = new FlxSprite(bg.x + bg.width - 200, bg.y + bg.height - 125);
        continueIcon.loadGraphic(Assets.getImage("ui/dialogs/continue_indicator"), true, 95, 95);
        continueIcon.animation.add("blink", [0, 1, 2, 1], 6, true);
        continueIcon.scrollFactor.set(0, 0);
        continueIcon.visible = false;
        add(continueIcon);

        selectionMenu = new DialogSelection(this);
        add(selectionMenu);

        var openEvt = new CancellableEvent();
        callScript("onOpen", [openEvt]);
        if (!openEvt.cancelled) {
            callScript("onOpenPost", [openEvt]);
            if (jsonData != null) playCurrentEntry();
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (state == TYPING) {
            var curLength:Int = Std.int(Reflect.getProperty(bodyText, "_typingIndex"));
            if (curLength != lastTypingIndex) {
                var charEvt = new DialogCharTypedEvent();
                charEvt.preTextCharNum = lastTypingIndex;
                charEvt.nextTextCharNum = curLength;
                
                callScript("onCharTyped", [charEvt]);
                
                if (charEvt.cancelled) {
                    bodyText.paused = true;
                } else {
                    callScript("onCharTypedPost", [curLength]);
                    lastTypingIndex = curLength;
                }
            }
        }

        var ptrPressed = false;
        #if FLX_MOUSE
        if (FlxG.mouse.justPressed) ptrPressed = true;
        #end
        #if FLX_TOUCH
        for (touch in FlxG.touches.list) {
            if (touch.justPressed) ptrPressed = true;
        }
        #end

        if ((Controls.ACCEPT || ptrPressed) && state != SELECTION) {
            if (state == TYPING) {
                var skipEvt = new CancellableEvent();
                callScript("onSkip", [skipEvt]);
                if (!skipEvt.cancelled) {
                    bodyText.skip();
                    bodyText.paused = false;
                    callScript("onSkipPost", [skipEvt]);
                }
            } else if (state == WAITING_INPUT) {
                var confirmEvt = new CancellableEvent();
                callScript("onConfirm", [confirmEvt]);
                if (!confirmEvt.cancelled) {
                    callScript("onConfirmPost", [confirmEvt]);
                    continueIcon.visible = false;
                    progressDialog();
                }
            }
        }
    }

    function loadDialogSequence(id:String):Void {
        entryIndex = 0;
        currentEntries = [];
        if (jsonData != null && jsonData.exists(id)) {
            currentEntries = jsonData.get(id);
        }
    }

    function formatText(text:String):String {
        var r = new EReg("\\{([^}]+)\\}", "g");
        return r.map(text, function(e:EReg):String {
            var val = Game.save.getVariable(e.matched(1));
            return val != null ? Std.string(val) : "";
        });
    }

    function playCurrentEntry():Void {
        if (entryIndex >= currentEntries.length) {
            shutdownDialog();
            return;
        }

        var entry = currentEntries[entryIndex];
        var textKey = entry.text != null ? entry.text : "";
        
        if (textKey == "" && entry.selections != null) {
            triggerSelections(entry);
            return;
        }

        var textEvt = new DialogEntryEvent();
        textEvt.entry = entry;
        textEvt.text = textKey;
        
        callScript("onTextStart", [textEvt]);
        if (textEvt.cancelled) return;

        var localizedText = formatText(Lang.get(textEvt.text));
        
        var localizedEvt = new DialogEntryEvent();
        localizedEvt.entry = entry;
        localizedEvt.text = localizedText;
        callScript("onTextStartPost", [localizedEvt]);

        nameText.text = entry.name != null ? entry.name : "";
        nameText.visible = nameSeperator.visible = (nameText.text != "");
        bodyText.y = nameText.visible ? (bg.y + 105) : (bg.y + 55);

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
        var entry = currentEntries[entryIndex];
        
        if (entry.selections != null) {
            triggerSelections(entry);
            return;
        }
        
        if (entry.close == true) {
            shutdownDialog();
            return;
        }

        entryIndex++;
        playCurrentEntry();
    }

    function triggerSelections(entry:DialogEntryDef):Void {
        state = SELECTION;
        var options:Array<DialogSelectionDef> = entry.selections;
        selectionMenu.triggerOpen(options, function(choiceIndex:Int) {
            entryIndex++;
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

            if (onCompleteCallback != null) onCompleteCallback();
            close();
        }
    }

    public function callScript(func:String, args:Array<Dynamic>):Void {
        #if FEATURE_HSCRIPT
        localDialogScript.call(func, args);
        #end
    }
}