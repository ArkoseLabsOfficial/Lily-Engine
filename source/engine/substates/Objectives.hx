package engine.substates;

import lang.Lang;
import lang.LangText;

typedef DisplayItem = {
	var obj:Objective;
	var isChild:Bool;
	var status:String;
	var depth:Int;
}

class Objectives extends SubStateBackend {
	static inline var MAIN_PANEL_W:Int = 900;
	static inline var MAIN_PANEL_H:Int = 600;
	static inline var DESC_PANEL_W:Int = 546;
	static inline var DESC_PANEL_H:Int = 600;

	var curSelected:Int = 0;
	var displayItems:Array<DisplayItem> = [];
	var objectiveTexts:Array<FlxText> = [];

	public var canInput:Bool = false;

	var descFrame:MenuFrameNode;
	var descText:LangText;
	var highlightBox:FlxSprite;

	override public function create() {
		super.create();
		camMenu.scroll.set(-230, 230);

		var separation = 20;
		var separationRight = 5;
		var totalWidth = MAIN_PANEL_W + separation + DESC_PANEL_W;
		var startX = (FlxG.width - totalWidth) / 2 + 10;
		var startY = (FlxG.height - MAIN_PANEL_H) / 2;

		var mainFrame = new MenuFrameNode(startX, startY, MAIN_PANEL_W, MAIN_PANEL_H, 2);
		mainFrame.setTitle("system.menu.objectives");
		mainFrame.divider = new FlxSprite(0, 0, LilyAssets.image("ui/dividers/divider_md"));
		add(mainFrame);

		var descX = startX + MAIN_PANEL_W + separationRight;
		descFrame = new MenuFrameNode(descX, startY, DESC_PANEL_W, DESC_PANEL_H, 1);
		descFrame.divider = new FlxSprite(0, 0, LilyAssets.image("ui/dividers/divider_sm"));
		descFrame.nodeFrame.decorBgTexture = "ui/decors/menu_bg_decor";
		add(descFrame);

		descText = new LangText(descX + 30, startY + 40, DESC_PANEL_W - 60, "", null, 28);
		descText.alignment = LEFT;
		add(descText);

		highlightBox = new FlxSprite(startX + 150, 0).makeGraphic(MAIN_PANEL_W - 300, 46, 0xFF4A4A4A);
		highlightBox.alpha = 0.6;
		add(highlightBox);

		var activeParents = BaseRoom.instance.objectives.getCurrentObjectives();
		for (parent in activeParents) {
			displayItems.push({
				obj: parent,
				isChild: false,
				status: "active",
				depth: 0
			});
			buildDisplayList(parent, 1);
		}

		var listStartY = startY + 140;

		if (displayItems.length == 0) {
			var emptyText = new LangText(startX, listStartY + 100, MAIN_PANEL_W, "system.menu.objectives.empty", null, 36);
			emptyText.alignment = CENTER;
			emptyText.color = FlxColor.GRAY;
			add(emptyText);
			highlightBox.visible = false;
		} else {
			for (i in 0...displayItems.length) {
				var item = displayItems[i];
				var prefix = "• ";
				var itemX = startX + 155;
				var fontSize = 36;

				if (item.isChild) {
					itemX = startX + 155 + (item.depth * 25);
					fontSize = Std.int(Math.max(22, 36 - (item.depth * 5)));
				}

				var localizedObjName = Lang.get(item.obj.name);
				var itemTxt = new FlxText(itemX, listStartY + (i * 60), MAIN_PANEL_W - (itemX - startX) - 35, prefix + localizedObjName, fontSize);
				itemTxt.alignment = LEFT;

				if (item.status == "failed") {
					itemTxt.color = FlxColor.GRAY;

					var tw = itemTxt.textField.textWidth;
					if (tw == 0)
						tw = itemTxt.text.length * (fontSize * 0.55);

					var strikeY = itemTxt.y + (itemTxt.height / 2) + 2;
					var strikeLine = new FlxSprite(itemX, strikeY).makeGraphic(Std.int(tw + 12), Math.floor(fontSize / 10) + 1, FlxColor.GRAY);
					add(strikeLine);
				}

				objectiveTexts.push(itemTxt);
				add(itemTxt);
			}
			highlightSelection();
		}

		new FlxTimer().start(0.1, function(_) {
			canInput = true;
		});
	}

	private function buildDisplayList(parent:Objective, depth:Int):Void {
		if (!parent.hasChildren())
			return;

		for (child in parent.children) {
			if (BaseRoom.instance.objectives.isObjectiveCompleted(child.id)) {
				continue;
			}

			var cStatus = "active";
			if (BaseRoom.instance.objectives.isObjectiveFailed(child.id)) {
				cStatus = "failed";
			}

			displayItems.push({
				obj: child,
				isChild: true,
				status: cStatus,
				depth: depth
			});

			buildDisplayList(child, depth + 1);
		}
	}

	override public function openSubState(SubState:FlxSubState):Void {
		canInput = false;
		super.openSubState(SubState);
	}

	override public function closeSubState():Void {
		canInput = true;
		super.closeSubState();
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (!canInput)
			return;

		if (displayItems.length > 0) {
			if (Controls.UP_P)
				moveSelection(-1);
			if (Controls.DOWN_P)
				moveSelection(1);
		}

		if (Controls.CANCEL) {
			LilyAssets.play(LilyAssets.CANCEL);
			close();
		}
	}

	function moveSelection(change:Int) {
		LilyAssets.play(LilyAssets.NAVIGATE);
		curSelected += change;
		if (curSelected < 0)
			curSelected = displayItems.length - 1;
		if (curSelected >= displayItems.length)
			curSelected = 0;
		highlightSelection();
	}

	function highlightSelection() {
		if (displayItems.length == 0)
			return;

		var activeText = objectiveTexts[curSelected];
		highlightBox.y = activeText.y + (activeText.height / 2) - (highlightBox.height / 2);

		var item = displayItems[curSelected];

		if (descFrame.titleText != null) {
			descFrame.setTitle(item.obj.name);
		}

		descText.setTranslation(item.obj.description);
	}
}
