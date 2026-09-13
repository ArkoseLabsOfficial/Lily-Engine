package engine.substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import engine.ui.NineGrid;
import engine.ui.NineNode;
import lang.LangText;

class InventoryMenu extends SubStateBackend {
	static inline var MAIN_PANEL_W:Int = 900;
	static inline var MAIN_PANEL_H:Int = 600;
	static inline var DESC_PANEL_W:Int = 546;
	static inline var DESC_PANEL_H:Int = 600;

	public var canInput:Bool = false;

	var invGrid:NineGrid;
	var descFrame:NineNode;
	var descText:LangText;
	var gridEntries:Array<InventoryMenuEntry> = [];

	override public function create() {
		super.create();
		camMenu.scroll.set(-230, 230);

		var separation = 6;
		var totalWidth = MAIN_PANEL_W + separation + DESC_PANEL_W;
		var startX = (FlxG.width - totalWidth) / 2;
		var startY = (FlxG.height - MAIN_PANEL_H) / 2;

		var gridData:NineGridData = {
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
			title: "system.menu.items",
			titleTexture: "ui/dividers/divider_md",
			columns: 5,
			maxVisibleRows: 3,
			itemWidth: 120,
			itemHeight: 120,
			gapX: 30,
			gapY: 30,
			paddingX: 75,
			paddingY: 120
		};

		invGrid = new NineGrid(startX, startY, gridData);
		add(invGrid);

		var descX = startX + MAIN_PANEL_W + separation;
		var descData:NineNodeMenuData = {
			width: DESC_PANEL_W,
			height: DESC_PANEL_H,
			texture: 'ui/frames/frame_menu_2',
			bgTexture: 'ui/frames/frame_menu_bg',
			margin: {
				left: 50,
				top: 50,
				right: 50,
				bottom: 50
			},
			scaleFactor: 0.75,
			titleTexture: "ui/dividers/divider_sm"
		};
		descFrame = new NineNode(descX, startY, descData);
		descFrame.setTitle("");
		descFrame.divider.x += 65;
		add(descFrame);

		descText = new LangText(descX + 45, startY + 130, DESC_PANEL_W - 90, "", null, 24);
		descText.alignment = LEFT;
		descText.height = DESC_PANEL_H - 150;
		add(descText);

		var ownedItemIDs = [];
		for (id in Game.items.inventory.keys())
			ownedItemIDs.push(id);

		var rawCount = ownedItemIDs.length;
		var totalSlots = Std.int(Math.max(15, 5 * Math.ceil(rawCount / 5.0)));

		for (i in 0...totalSlots) {
			var id = (i < rawCount) ? ownedItemIDs[i] : "";
			var amt = (i < rawCount) ? Game.items.getOwnedAmount(id) : 0;

			var entry = new InventoryMenuEntry(0, 0, id, amt);
			gridEntries.push(entry);

			var action = null;
			if (!entry.isEmpty) {
				action = function() {
					FlxG.sound.play(Flags.CONFIRM);
					var itemData = Game.items.items.get(entry.itemId);
					if (itemData != null && itemData.scriptPath != "") {
						Game.items.runItemScript(itemData.scriptPath);
						Game.items.removeItem(entry.itemId, 1);
					}
					close();
				};
			}
			invGrid.addItem(entry, action);
		}

		invGrid.buildGrid();

		invGrid.onSelectionChanged = function(index:Int) {
			for (e in gridEntries)
				e.deselect();
			descFrame.setTitle("");
			descText.text = "";

			if (index > -1 && index < gridEntries.length) {
				var activeEntry = gridEntries[index];
				activeEntry.select();

				if (!activeEntry.isEmpty) {
					var itemData = Game.items.items.get(activeEntry.itemId);
					descFrame.setTitle(itemData.name);
					descText.setTranslation(itemData.desc);
				}
			}
		};

		invGrid.resetSelection();

		new FlxTimer().start(0.1, function(_) {
			canInput = true;
		});

		Discord.updatePresence('In the inventory menu', 'Mod: ${GamePrefs.currentMod}');
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
		if (invGrid != null) {
			invGrid.canInput = canInput;
		}

		super.update(elapsed);

		if (!canInput)
			return;

		if (Controls.BACK) {
			FlxG.sound.play(Flags.CANCEL);
			close();
		}
	}
}

class InventoryMenuEntry extends FlxSpriteGroup {
	static inline var ICON_SIZE:Int = 120;

	var bgTextureRect:FlxSprite;
	var itemIcon:FlxSprite;
	var nQtyLabel:FlxText;

	public var itemId:String;
	public var amount:Int;
	public var isEmpty:Bool;

	public function new(x:Float, y:Float, id:String, amt:Int) {
		super(x, y);
		itemId = id;
		amount = amt;
		isEmpty = (id == "");

		bgTextureRect = new FlxSprite(0, 0);
		add(bgTextureRect);

		if (!isEmpty) {
			var itemData = Game.items.items.get(id);
			itemIcon = new FlxSprite(0, 0);
			var iconPath = (itemData != null ? itemData.iconPath : id);

			if (Assets.exists(Assets.getImagePath(iconPath)))
				itemIcon.loadGraphic(Assets.getImage(iconPath));
			else
				itemIcon.makeGraphic(ICON_SIZE, ICON_SIZE, FlxColor.TRANSPARENT);

			itemIcon.setGraphicSize(ICON_SIZE, ICON_SIZE);
			itemIcon.updateHitbox();
			add(itemIcon);

			if (amount > 1) {
				nQtyLabel = new FlxText(-10, ICON_SIZE - 35, ICON_SIZE + 20, Std.string(amount) + " ", 24);
				nQtyLabel.alignment = RIGHT;
				nQtyLabel.color = FlxColor.WHITE;
				nQtyLabel.borderColor = 0xFFBD274D;
				nQtyLabel.borderStyle = OUTLINE;
				nQtyLabel.borderSize = 3;
				nQtyLabel.wordWrap = false;
				nQtyLabel.autoSize = false;
				nQtyLabel.height += 20;

				add(nQtyLabel);
			}
		}
		deselect();
	}

	public function select() {
		var tex = isEmpty ? Assets.getImage("ui/items/item_icon_bg_empty_selected") : Assets.getImage("ui/items/item_icon_bg_selected");
		bgTextureRect.loadGraphic(tex);
		bgTextureRect.setGraphicSize(ICON_SIZE, ICON_SIZE);
		bgTextureRect.updateHitbox();
		if (nQtyLabel != null) {
			nQtyLabel.color = 0xFFBD274D;
			nQtyLabel.borderColor = FlxColor.WHITE;
		}
	}

	public function deselect() {
		var tex = isEmpty ? Assets.getImage("ui/items/item_icon_bg_empty") : Assets.getImage("ui/items/item_icon_bg");
		bgTextureRect.loadGraphic(tex);
		bgTextureRect.setGraphicSize(ICON_SIZE, ICON_SIZE);
		bgTextureRect.updateHitbox();
		if (nQtyLabel != null) {
			nQtyLabel.color = FlxColor.WHITE;
			nQtyLabel.borderColor = 0xFFBD274D;
		}
	}
}
