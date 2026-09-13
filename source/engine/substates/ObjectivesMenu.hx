package engine.substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import engine.ui.NineNode;
import lang.Lang;
import lang.LangText;

typedef DisplayItem = {
	var obj:Objective;
	var isChild:Bool;
	var status:String;
	var depth:Int;
}

class ObjectivesMenu extends SubStateBackend {
	static inline var MAIN_PANEL_W:Int = 900;
	static inline var MAIN_PANEL_H:Int = 600;
	static inline var DESC_PANEL_W:Int = 546;
	static inline var DESC_PANEL_H:Int = 600;

	var displayItems:Array<DisplayItem> = [];

	var mainNode:NineNode;
	var descNode:NineNode;
	var descText:LangText;

	public var canInput:Bool = false;

	var lastSelected:Int = -1;

	override public function create() {
		super.create();
		camMenu.scroll.set(-230, 230);

		var separation = 20;
		var separationRight = 5;
		var totalWidth = MAIN_PANEL_W + separation + DESC_PANEL_W;
		var startX = (FlxG.width - totalWidth) / 2 + 10;
		var startY = (FlxG.height - MAIN_PANEL_H) / 2;

		var mainData:NineNodeMenuData = {
			width: MAIN_PANEL_W,
			height: MAIN_PANEL_H,
			texture: 'ui/frames/frame_menu_2',
			bgTexture: 'ui/frames/frame_menu_bg',
			margin: {
				left: 50,
				top: 50,
				right: 50,
				bottom: 50
			},
			scaleFactor: 0.75,
			title: "system.menu.objectives",
			titleTexture: "ui/dividers/divider_md",
			itemWidth: MAIN_PANEL_W - 300,
			itemHeight: 46,
			itemFontSize: 36,
			itemSeparation: 60,
			itemAlignment: LEFT,
			maxBeforeScroll: 7
		};

		mainNode = new NineNode(startX, startY, mainData);
		add(mainNode);

		var descX = startX + MAIN_PANEL_W + separationRight;
		var descData:NineNodeMenuData = {
			width: DESC_PANEL_W,
			height: DESC_PANEL_H,
			texture: 'ui/frames/frame_menu_2',
			bgTexture: 'ui/frames/frame_menu_bg',
			titleTexture: "ui/dividers/divider_sm",
			margin: {
				left: 50,
				top: 50,
				right: 50,
				bottom: 50
			},
			scaleFactor: 0.75
		};

		descNode = new NineNode(descX, startY, descData);
		add(descNode);

		descText = new LangText(descX + 40, startY + 140, DESC_PANEL_W - 80, "", null, 28);
		descText.alignment = LEFT;
		add(descText);

		var activeParents = Game.objectives.getCurrentObjectives();
		for (parent in activeParents) {
			displayItems.push({
				obj: parent,
				isChild: false,
				status: "active",
				depth: 0
			});
			buildDisplayList(parent, 1);
		}

		if (displayItems.length == 0) {
			var emptyText = new LangText(startX, startY + 240, MAIN_PANEL_W, "system.menu.objectives.empty", null, 36);
			emptyText.alignment = CENTER;
			emptyText.color = FlxColor.GRAY;
			add(emptyText);
		} else {
			for (item in displayItems) {
				var prefix = "• ";
				var localizedObjName = Lang.get(item.obj.name);
				mainNode.addEntry(prefix + localizedObjName, null);
			}

			mainNode.buildVisualList();

			for (i in 0...displayItems.length) {
				var item = displayItems[i];
				var group = mainNode.visualItems[i];
				var txt:LangText = cast group.members[1];

				if (item.isChild) {
					var indent = item.depth * 25;
					txt.x += indent;
					txt.size = Std.int(Math.max(22, 36 - (item.depth * 5)));
				}

				if (item.status == "failed") {
					txt.color = FlxColor.GRAY;
					txt.text = txt.text;
					txt.strikethrough = true;
					descText.color = FlxColor.GRAY;
					descText.text = descText.text;
					descText.strikethrough = true;
				}
			}
		}

		new FlxTimer().start(0.1, function(_) {
			canInput = true;
		});

		Discord.updatePresence('In the objective menu', 'Mod: ${GamePrefs.currentMod}');
	}

	private function buildDisplayList(parent:Objective, depth:Int):Void {
		if (!parent.hasChildren())
			return;

		for (child in parent.children) {
			if (Game.objectives.isObjectiveCompleted(child.id)) {
				continue;
			}

			var cStatus = "active";
			if (Game.objectives.isObjectiveFailed(child.id)) {
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

		if (mainNode != null) {
			mainNode.canInput = canInput;
		}

		if (!canInput)
			return;

		if (displayItems.length > 0 && mainNode != null) {
			if (mainNode.selection != lastSelected) {
				lastSelected = mainNode.selection;
				highlightSelection();
			}
		}

		if (Controls.BACK) {
			FlxG.sound.play(Flags.CANCEL);
			close();
		}
	}

	function highlightSelection() {
		if (displayItems.length == 0 || mainNode == null)
			return;

		var item = displayItems[mainNode.selection];

		if (descNode != null) {
			descNode.setTitle(item.obj.name);
			descNode.titleText.color = FlxColor.WHITE;
			if (item.status == "failed") {
				descNode.titleText.color = FlxColor.GRAY;
				descNode.titleText.text = descNode.titleText.text;
				descNode.titleText.strikethrough = true;
			}
		}

		if (descText != null) {
			descText.setTranslation(item.obj.description);
			descText.color = FlxColor.WHITE;
			if (item.status == "failed") {
				descText.color = FlxColor.GRAY;
				descText.text = descText.text;
				descText.strikethrough = true;
			}
		}
	}
}
