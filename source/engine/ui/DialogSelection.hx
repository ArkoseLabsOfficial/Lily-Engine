package engine.ui;

import engine.scripting.events.DialogEvents;
import engine.ui.DialogBox;

class DialogSelection extends FlxTypedGroup<FlxSprite> {
    var menuFrame:MenuFrameNode;
    var selector:FlxSprite;
    var options:Array<DialogSelectionDef>;
    var optionTexts:Array<FlxText> = [];
    var selectedIndex:Int = 0;

    public var onSelect:Int->Void;

    var optionSpacing:Float = 35;
    var boxPaddingX:Float = 60;
    public var customBoxWidth:Float = 0;
    public var customBoxHeight:Float = 0;

    var parentBox:DialogBox;

    public function new(parent:DialogBox) {
        super();
        this.parentBox = parent;

        selector = new FlxSprite(0, 0).makeGraphic(1, 1, 0xFF4A4A4A);
        selector.alpha = 0.4;
        selector.scrollFactor.set(0, 0);

        visible = false;
    }

    public function triggerOpen(optionsList:Array<DialogSelectionDef>, callback:Int->Void):Void {
        var selEvt = new DialogSelectionEvent();
        selEvt.selections = cast optionsList;
        parentBox.callScript("onSelectionOpen", [selEvt]);
        
        if (selEvt.cancelled) return;
        
        options = cast selEvt.selections;
        onSelect = callback;

        for (txt in optionTexts) {
            remove(txt, true);
            txt.destroy();
        }
        optionTexts = [];

        remove(selector, true);
        if (menuFrame != null) {
            remove(menuFrame, true);
            menuFrame.destroy();
        }

        var maxTextWidth:Float = 200;
        var textHeight:Float = 20;

        for (opt in options) {
            var rawText = opt.text != null ? opt.text : "";
            var tempText = new FlxText(0, 0, 0, Lang.get(rawText), 40);
            tempText.scale.set(0.6, 0.6);
            tempText.updateHitbox();

            if (tempText.width > maxTextWidth) maxTextWidth = tempText.width;
            textHeight = tempText.height;
            tempText.destroy();
        }

        var totalTextHeight:Float = ((options.length - 1) * optionSpacing) + textHeight;
        var finalBoxWidth = (customBoxWidth > 0) ? customBoxWidth : (maxTextWidth + boxPaddingX);
        var finalBoxHeight = (customBoxHeight > 0) ? customBoxHeight : (totalTextHeight + 80);

        menuFrame = new MenuFrameNode(0, 0, finalBoxWidth, finalBoxHeight, 0);
        menuFrame.scrollFactor.set(0, 0);
        menuFrame.screenCenter();
        add(menuFrame);

        selector.setGraphicSize(Std.int(finalBoxWidth - 20), 30);
        selector.updateHitbox();
        selector.x = menuFrame.x + 10;
        add(selector);

        var layoutY = menuFrame.y + ((finalBoxHeight - totalTextHeight) / 2);

        for (i in 0...options.length) {
            var rawText = options[i].text != null ? options[i].text : "";
            var txt = new FlxText(0, layoutY, 0, Lang.get(rawText), 40);
            txt.scale.set(0.6, 0.6);
            txt.updateHitbox();
            txt.x = menuFrame.x + ((finalBoxWidth - txt.width) / 2);
            txt.scrollFactor.set(0, 0);
            txt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);

            add(txt);
            optionTexts.push(txt);
            layoutY += optionSpacing;
        }

        visible = true;
        changeSelection(0);
        
        parentBox.callScript("onSelectionOpenPost", [options]);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (!visible) return;

        var pointerMoved = false;
        var pointerJustPressed = false;

        #if FLX_MOUSE
        if (FlxG.mouse.justMoved) pointerMoved = true;
        if (FlxG.mouse.justPressed) pointerJustPressed = true;
        #end

        var touchJustPressed = false;
        #if FLX_TOUCH
        for (touch in FlxG.touches.list) {
            pointerMoved = true;
            if (touch.justPressed) touchJustPressed = true;
        }
        #end

        if (pointerMoved || pointerJustPressed || touchJustPressed) {
            for (i in 0...optionTexts.length) {
                var txt = optionTexts[i];
                var overlap = false;
                @:privateAccess
                var cam = parentBox.camMenu != null ? parentBox.camMenu : FlxG.camera;

                #if FLX_MOUSE
                if (FlxG.mouse.overlaps(txt, cam)) overlap = true;
                #end

                #if FLX_TOUCH
                for (touch in FlxG.touches.list) {
                    if (touch.overlaps(txt, cam)) overlap = true;
                }
                #end

                if (overlap) {
                    if (selectedIndex != i) {
						FlxG.sound.play(Flags.NAVIGATE);
                        changeSelection(i - selectedIndex);
                    }
                    if (pointerJustPressed || touchJustPressed) {
                        executeSelection();
                        return;
                    }
                }
            }
        }

        if (Controls.UP_P) {
			FlxG.sound.play(Flags.NAVIGATE);
            changeSelection(-1);
        }
        if (Controls.DOWN_P) {
            FlxG.sound.play(Flags.NAVIGATE);
            changeSelection(1);
        }
        if (Controls.ACCEPT) {
            executeSelection();
        }
    }

    function executeSelection():Void {
        var optId = options[selectedIndex].id != null ? options[selectedIndex].id : "";
        
        var selEvt = new DialogOptionSelectedEvent();
        selEvt.index = selectedIndex;
        selEvt.optionId = optId;
        
        parentBox.callScript("onOptionSelected", [selEvt]);
        if (selEvt.cancelled) return;
        
        FlxG.sound.play(Flags.CONFIRM);
        
        var closeEvt = new CancellableEvent();
        parentBox.callScript("onSelectionClose", [closeEvt]);
        
        if (!closeEvt.cancelled) {
            visible = false;
            parentBox.callScript("onSelectionClosePost", [closeEvt]);
            parentBox.callScript("onOptionSelectedPost", [selectedIndex, optId]);
            
            if (onSelect != null) onSelect(selectedIndex);
        }
    }

    function changeSelection(change:Int):Void {
        selectedIndex += change;

        if (selectedIndex < 0) selectedIndex = options.length - 1;
        if (selectedIndex >= options.length) selectedIndex = 0;

        if (optionTexts.length > 0) {
            var targetText = optionTexts[selectedIndex];
            selector.y = targetText.y + (targetText.height / 2) - (selector.height / 2);
        }
    }
}