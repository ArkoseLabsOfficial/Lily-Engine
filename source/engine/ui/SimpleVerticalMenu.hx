package engine.ui;

import flixel.group.FlxSpriteGroup;
import flixel.FlxG;
import flixel.util.FlxColor;
import engine.backend.Game;

class SimpleVerticalMenu extends FlxSpriteGroup {
	public var selection:Int = 0;
	public var canInput:Bool = true;

	public var itemWidth:Float = 492;
	public var itemFontSize:Int = 48;
	public var itemAlignment:FlxTextAlign = CENTER;

	public var entries:Array<{caption:String, action:Void->Void}> = [];
	public var visualItems:Array<MenuVisualEntry> = [];

	public function new() {
		super();
	}

	public function drawContent():Void {}

	public function addEntry(caption:String, action:Void->Void):Void {
		entries.push({caption: caption, action: action});
	}

	public function buildVisualList(separation:Float = 72):Void {
		clearItems();

		for (i in 0...entries.length) {
			var item = createVisualEntry(i, entries[i].caption, separation);
			visualItems.push(item);
			add(item);
		}
		highlightSelection();
	}

	public function clearItems():Void {
		for (vis in visualItems) {
			remove(vis, true);
			vis.destroy();
		}
		visualItems = [];
	}

	public function createVisualEntry(index:Int, textKey:String, separation:Float):MenuVisualEntry {
		var item = new MenuVisualEntry(0, index * separation, textKey, itemWidth, Std.int(separation), itemFontSize, itemAlignment);
		item.bg.makeGraphic(Std.int(itemWidth - 70), Std.int(separation), FlxColor.TRANSPARENT);
		item.bg.x += 35;
		return item;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		if (canInput)
			handleInput();
	}

	public function handleInput():Void {
		if (entries.length == 0 && visualItems.length == 0)
			return;

		if (Controls.UP_P) {
			FlxG.sound.play(Flags.NAVIGATE);
			changeSelection(-1);
		} else if (Controls.DOWN_P) {
			FlxG.sound.play(Flags.NAVIGATE);
			changeSelection(1);
		} else if (Controls.ACCEPT) {
			acceptSelection();
		}
	}

	public function changeSelection(change:Int):Void {
		selection += change;
		if (selection < 0)
			selection = getListLength() - 1;
		if (selection >= getListLength())
			selection = 0;
		highlightSelection();
	}

	public function getListLength():Int {
		return entries.length > 0 ? entries.length : visualItems.length;
	}

	public function acceptSelection():Void {
		if (entries[selection] != null && entries[selection].action != null) {

			FlxG.sound.play(Flags.CONFIRM);
			entries[selection].action();
		}
	}

	public function highlightSelection():Void {
		for (i in 0...visualItems.length)
			visualItems[i].setHighlight(i == selection);
	}

	public function resetSelection():Void {
		selection = 0;
		highlightSelection();
	}
}
