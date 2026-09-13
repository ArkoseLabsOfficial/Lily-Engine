package engine.ui;

import engine.scripting.events.DialogEvents;
import engine.ui.DialogBox;

class DialogSelection extends FlxTypedGroup<FlxSprite> {
	var nineNode:NineNode;
	var options:Array<DialogSelectionDef>;
	var selectedIndex:Int = -1;

	public var onSelect:Int->Void;

	var optionSpacing:Float = 35;
	var boxPaddingX:Float = 60;

	public var customBoxWidth:Float = 0;
	public var customBoxHeight:Float = 0;

	var parentBox:DialogBox;

	public function new(parent:DialogBox) {
		super();
		this.parentBox = parent;
		visible = false;
	}

	public function triggerOpen(optionsList:Array<DialogSelectionDef>, callback:Int->Void):Void {
		var selEvt = new DialogSelectionEvent();
		selEvt.selections = cast optionsList;
		parentBox.callScript("onSelectionOpen", [selEvt]);

		if (selEvt.cancelled)
			return;

		options = cast selEvt.selections;
		onSelect = callback;

		if (nineNode != null) {
			remove(nineNode, true);
			nineNode.destroy();
		}

		var maxTextWidth:Float = 200;
		var textHeight:Float = 24;

		for (opt in options) {
			var rawText = opt.text != null ? opt.text : "";
			var formattedText = parentBox.formatText(Lang.get(rawText), opt.translate);
			var tempText = new FlxText(0, 0, 0, formattedText, 24);
			tempText.updateHitbox();

			if (tempText.width > maxTextWidth)
				maxTextWidth = tempText.width;
			textHeight = tempText.height;
			tempText.destroy();
		}

		var finalBoxWidth:Float = (customBoxWidth > 0) ? customBoxWidth : (maxTextWidth + boxPaddingX);
		var finalBoxHeight:Null<Float> = (customBoxHeight > 0) ? customBoxHeight : null;

		nineNode = new NineNode(0, 0, {
			texture: 'ui/new/border',
			bgTexture: 'ui/frames/frame_default_bg',
			scaleFactor: 2,
			margin: {
				left: 10,
				top: 10,
				right: 10,
				bottom: 10
			},
			width: finalBoxWidth,
			height: finalBoxHeight,
			itemWidth: finalBoxWidth - 20,
			itemHeight: textHeight + 10,
			itemFontSize: 24,
			itemSeparation: textHeight + 10,
			itemAlignment: CENTER
		});

		for (i in 0...options.length) {
			var opt = options[i];
			var rawText = opt.text != null ? opt.text : "";
			var formattedText = parentBox.formatText(Lang.get(rawText), opt.translate);

			nineNode.addEntry(formattedText, () -> {
				selectedIndex = i;
				executeSelection();
			});
		}

		nineNode.buildVisualList();

		for (vis in nineNode.visualItems) {
			var txt:FlxText = cast vis.members[1];
			if (txt != null) {
				txt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
			}
		}

		nineNode.screenCenter();
		add(nineNode);

		visible = true;
		nineNode.selection = -1;
		nineNode.highlightSelection();

		parentBox.callScript("onSelectionOpenPost", [options]);
	}

	override public function update(elapsed:Float):Void {
		if (nineNode != null) {
			nineNode.canInput = visible;
		}

		super.update(elapsed);

		if (!visible || nineNode == null)
			return;

		var pointerMoved = false;
		var pointerJustPressed = false;

		#if FLX_MOUSE
		if (FlxG.mouse.justMoved)
			pointerMoved = true;
		if (FlxG.mouse.justPressed)
			pointerJustPressed = true;
		#end

		var touchJustPressed = false;
		#if FLX_TOUCH
		for (touch in FlxG.touches.list) {
			pointerMoved = true;
			if (touch.justPressed)
				touchJustPressed = true;
		}
		#end

		if (pointerMoved || pointerJustPressed || touchJustPressed) {
			for (i in 0...nineNode.visualItems.length) {
				var vis = nineNode.visualItems[i];
				var overlap = false;

				@:privateAccess
				var cam = parentBox.camMenu != null ? parentBox.camMenu : FlxG.camera;

				#if FLX_MOUSE
				if (FlxG.mouse.overlaps(vis, cam))
					overlap = true;
				#end

				#if FLX_TOUCH
				for (touch in FlxG.touches.list) {
					if (touch.overlaps(vis, cam))
						overlap = true;
				}
				#end

				if (overlap) {
					if (nineNode.selection != i) {
						FlxG.sound.play(Flags.NAVIGATE);
						nineNode.selection = i;
						if (nineNode.selection >= 0 && nineNode.selection < nineNode.visualItems.length) {
							nineNode.highlightSelection();
						}
					}
					if (pointerJustPressed || touchJustPressed) {
						nineNode.acceptSelection();
						return;
					}
				}
			}
		}
	}

	function executeSelection():Void {
		var optId = options[selectedIndex].id != null ? options[selectedIndex].id : "";

		var selEvt = new DialogOptionSelectedEvent();
		selEvt.index = selectedIndex;
		selEvt.optionId = optId;

		parentBox.callScript("onOptionSelected", [selEvt]);
		if (selEvt.cancelled)
			return;

		var closeEvt = new CancellableEvent();
		parentBox.callScript("onSelectionClose", [closeEvt]);

		if (!closeEvt.cancelled) {
			visible = false;
			parentBox.callScript("onSelectionClosePost", [closeEvt]);
			parentBox.callScript("onOptionSelectedPost", [selectedIndex, optId]);

			if (onSelect != null)
				onSelect(selectedIndex);
		}
	}
}
