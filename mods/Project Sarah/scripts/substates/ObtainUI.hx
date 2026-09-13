import flixel.FlxG;
import flixel.FlxSprite;
import engine.ui.NineNode;
import openfl.Assets;

/**
 * HScript UI Example.
 * @author KralOyuncu
**/
class ObtainUI {
	var itemQueue:Array<{id:String, amount:Int}> = [];
	var currentIndex:Int = 0;
	var currentItemData:ItemData;
	var currentAmount:Int = 1;
	var itemIcon:FlxSprite;

	public function create() {
		if (data != null) {
			if (data.items != null) {
				if (data.items is Array) {
					for (entry in data.items) {
						if (entry is String) {
							itemQueue.push({id: entry, amount: 1});
						} else if (Reflect.hasField(entry, "id")) {
							var id = Reflect.field(entry, "id");
							var amt = Reflect.hasField(entry, "amount") ? Reflect.field(entry, "amount") : 1;
							itemQueue.push({id: id, amount: amt});
						}
					}
				} else if (data.items is Map) {
					for (id in data.items.keys()) {
						itemQueue.push({id: id, amount: data.items.get(id)});
					}
				}
			} else if (Reflect.hasField(data, "item")) {
				var id = Reflect.field(data, "item");
				var amt = Reflect.hasField(data, "amount") ? Reflect.field(data, "amount") : 1;
				itemQueue.push({id: id, amount: amt});
			}
		}

		menu = new NineNode(0, 0, {
			width: 600,
			height: 200,
			texture: 'ui/frames/frame_menu_2b',
			bgTexture: 'ui/frames/frame_menu_bg',
			margin: {
				left: 50,
				top: 50,
				right: 50,
				bottom: 50
			},
			scaleFactor: 0.75
		});
		add(menu);
		menu.screenCenter();
		menu.selection = -1;
		menu.highlightSelection();
		menu.canInput = false;

		itemIcon = new FlxSprite(0, 0);
		itemIcon.scale.set(3, 3);
		add(itemIcon);

		visible = false;
		showNextItem();

        if (data.call == "event.School_Classroom_B.get_scissors") {
            var black = new FlxSprite(0, 0);
            black.makeGraphic(1920, 1080, FlxColor.BLACK);
            insert(0, black);
            Game.room.scene.getNode("Events/get_scissors").script.instance.changeToRitual();
        }
	}

	function showNextItem() {
		if (currentIndex >= itemQueue.length) {
			close();
			return;
		}

		visible = false;

		var queueEntry = itemQueue[currentIndex];
		var itemId = queueEntry.id;
		currentAmount = queueEntry.amount;

		currentItemData = Game.items.items.get(itemId);

		var itemName = (currentItemData != null) ? currentItemData.name : itemId;
		var iconPath = (currentItemData != null && currentItemData.iconPath != null) ? currentItemData.iconPath : "ui/item_icon_bg_empty";

		if (Assets.exists(Assets.getImagePath(iconPath))) {
			itemIcon.loadGraphic(Assets.getImage(iconPath));
		} else {
			itemIcon.loadGraphic(Assets.getImage("ui/item_icon_bg_empty"));
		}

		itemIcon.x = menu.x + 65;
		itemIcon.y = menu.y + (menu.bg.height - itemIcon.height) / 2;

		menu.entries = [];
		var displayText = (currentAmount > 1) ? 'Obtained Item x${currentAmount}' : 'Obtained ${Lang.get(itemName)}';

		switch (Lang.getCurrentLanguage()) {
			case "tr":
				displayText = (currentAmount > 1) ? '${Lang.get(itemName)} x${currentAmount} Alındı' : '${Lang.get(itemName)} ${Lang.get("system.menu.obtained")}';
			default:
				displayText = (currentAmount > 1) ? 'Obtained Item x${currentAmount}' : 'Obtained ${Lang.get(itemName)}';
		}

		menu.addEntry(displayText, function() {});
		menu.buildVisualList();
		if (menu.visualItems.length > 0) {
			menu.visualItems[0].members[1].maxWidth = 500;
			menu.visualItems[0].x += 45;
		}

		FlxG.sound.play("sounds/sfx/ui_item.ogg");
		visible = true;
		canConfirm = false;
		new FlxTimer().start(0.25, function() {
			canConfirm = true;
		});
	}

	var canConfirm:Bool = false;

	public function update(elapsed:Float) {
		if (Controls.BACK)
			close();
		if (Controls.ACCEPT && canConfirm) {
			if (currentItemData != null) {
				Game.items.addItem(currentItemData.id, currentAmount);
			}

			currentIndex++;
			showNextItem();
		}
	}
}
