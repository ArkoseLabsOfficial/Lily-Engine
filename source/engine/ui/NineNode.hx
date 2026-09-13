package engine.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import engine.ui.ImprovedNinePatch.MarginData;
import lang.LangText;

typedef NineMenuEntry = {
	var caption:String;
	var action:Void->Void;
}

typedef NineNodeMenuData = {
	@:optional var x:Float;
	@:optional var y:Float;
	@:optional var width:Float;
	@:optional var height:Float;

	@:optional var widthOffset:Float;
	@:optional var heightOffset:Float;

	@:optional var margin:MarginData;
	@:optional var texture:String;
	@:optional var bgTexture:String;
	@:optional var bgMaskTexture:String;
	@:optional var scaleFactor:Float;

	@:optional var title:String;
	@:optional var titleTexture:String;

	@:optional var itemWidth:Float;
	@:optional var itemHeight:Float;
	@:optional var itemFontSize:Int;
	@:optional var itemFont:String;
	@:optional var itemAlignment:GameTextAlign;
	@:optional var itemSeparation:Float;

	@:optional var listAlignment:String;

	@:optional var maxBeforeScroll:Int;
}

class NineNode extends FlxSpriteGroup {
	public var bg:ImprovedNinePatch;
	public var listContainer:FlxSpriteGroup;

	public var selection:Int = 0;
	public var canInput:Bool = true;

	public var itemWidth:Float;
	public var itemHeight:Float;
	public var itemFontSize:Int;
	public var itemAlignment:GameTextAlign;
	public var itemSeparation:Float;
	public var listAlignment:String;

	public var widthOffset:Float = 0;
	public var heightOffset:Float = 0;

	public var entries:Array<NineMenuEntry> = [];
	public var visualItems:Array<FlxSpriteGroup> = [];

	public var titleText:LangText;
	public var divider:FlxSprite;
	public var hasTitle:Bool = false;

	public var maxBeforeScroll:Int = 0;
	public var clipMask:ClipMask;
	public var scrollY:Float = 0;
	public var scrollLerp:Float = 0;
	public var viewHeight:Float = 0;
	public var baseY:Float = 0;

	private var initialData:NineNodeMenuData;

	private static inline var SELECT_COLOR:FlxColor = 0x33EDDEDE;

	public function new(x:Float, y:Float, data:NineNodeMenuData) {
		super(x, y);
		this.initialData = data;

		widthOffset = data.widthOffset ?? 0;
		heightOffset = data.heightOffset ?? 0;

		listAlignment = data.listAlignment ?? "center";

		bg = new ImprovedNinePatch(0, 0);
		bg.texture = data.texture;
		bg.bgTexture = data.bgTexture;
		bg.bgMaskTexture = data.bgMaskTexture;
		if (data.margin == null) {
			data.margin = {
				left: 0,
				right: 0,
				top: 0,
				bottom: 0
			}
		}
		bg.margin = data.margin;
		bg.scaleFactor = data.scaleFactor ?? 1;

		if (data.width != null && data.height != null) {
			bg.resize(data.width + widthOffset, data.height + heightOffset);
		}
		add(bg);

		listContainer = new FlxSpriteGroup();
		add(listContainer);

		itemHeight = data.itemHeight ?? 72;
		itemFontSize = data.itemFontSize ?? 48;
		itemAlignment = data.itemAlignment ?? GameTextAlign.CENTER;
		itemSeparation = data.itemSeparation ?? 72;

		itemWidth = data.itemWidth ?? (data.width != null ? data.width - 70 : 422);
		maxBeforeScroll = data.maxBeforeScroll ?? 0;

		divider = new FlxSprite(0, 90);

		if (data.title != null && data.title.length > 0) {
			setTitle(data.title);
		}
	}

	public function setTitle(textKey:String):Void {
		if (!hasTitle) {
			hasTitle = true;

			var w = (initialData.width ?? 0) + widthOffset;
			titleText = new LangText(0, 30, Std.int(w), "", null, 48);
			titleText.alignment = GameTextAlign.CENTER;

			if (initialData.titleTexture == null)
				initialData.titleTexture = "ui/new/menu_divider";

			divider.loadGraphic(Assets.getImage(initialData.titleTexture));

			add(titleText);
			add(divider);
		}

		if (titleText != null) {
			titleText.setTranslation(textKey);

			var showTitle = (textKey != null && textKey.length > 0);
			titleText.visible = showTitle;
			divider.visible = showTitle;
		}
	}

	public function addEntry(caption:String, action:Void->Void):Void {
		entries.push({caption: caption, action: action});
	}

	public function buildVisualList():Void {
		clearItems();

		var computedWidth = initialData.width;

		if (computedWidth == null) {
			computedWidth = itemWidth + 90;
		}

		computedWidth += widthOffset;

		var topPadding:Float = 10;
		var bottomPadding:Float = 10;

		if (hasTitle && titleText != null && titleText.visible) {
			topPadding = 130;

			titleText.maxWidth = computedWidth;

			var maxDividerWidth = computedWidth;
			if (divider.graphic != null && divider.graphic.width > 0) {
				var targetScale = Math.min(1, maxDividerWidth / divider.graphic.width);
				divider.scale.set(targetScale, 1);
				divider.updateHitbox();
			}
			divider.x = this.x + ((computedWidth - divider.width) / 2);
		}

		var computedHeight = initialData.height;
		var totalListHeight = 0.0;

		var shownItemsCount = entries.length;
		if (maxBeforeScroll > 0 && entries.length > maxBeforeScroll) {
			shownItemsCount = maxBeforeScroll;
		}

		if (entries.length > 0) {
			totalListHeight = (shownItemsCount * itemSeparation) - (itemSeparation - itemHeight) + 10;
		}

		if (computedHeight == null) {
			computedHeight = totalListHeight + topPadding + bottomPadding;
		}

		computedHeight += heightOffset;

		bg.resize(computedWidth, computedHeight);

		var startY:Float;
		if (initialData.height != null) {
			var availableHeight = computedHeight - topPadding - bottomPadding;
			if (listAlignment == "top") {
				startY = topPadding;
			} else if (listAlignment == "bottom") {
				startY = topPadding + availableHeight - totalListHeight;
			} else {
				startY = topPadding + (availableHeight - totalListHeight) / 2;
			}
		} else {
			startY = topPadding;
		}

		baseY = startY;

		listContainer.x = this.x;
		listContainer.y = this.y;

		var startX = (computedWidth - itemWidth) / 2;

		for (i in 0...entries.length) {
			var itemY = baseY + (i * itemSeparation) + 5;
			var group = new FlxSpriteGroup(startX, itemY);

			var spriteBg = new FlxSprite(0, 0);
			spriteBg.makeGraphic(Std.int(itemWidth), Std.int(itemHeight), FlxColor.TRANSPARENT);
			group.add(spriteBg);

			var label = new LangText(0, 0, itemWidth, entries[i].caption, null, itemFontSize);
			if (initialData.itemFont != null)
				label.setFont(initialData.itemFont);
			label.alignment = itemAlignment;
			label.y = (itemHeight - label.textHeight) / 2;
			group.add(label);

			visualItems.push(group);
			listContainer.add(group);
		}

		if (maxBeforeScroll > 0 && entries.length > maxBeforeScroll) {
			viewHeight = totalListHeight;
			clipMask = new ClipMask(this.x, this.y + startY, computedWidth, viewHeight);
			clipMask.apply(listContainer);
		} else {
			viewHeight = 0;
			clipMask = null;
			listContainer.clipRect = null;
		}

		highlightSelection();
	}

	public function clearItems():Void {
		for (vis in visualItems) {
			listContainer.remove(vis, true);
			vis.destroy();
		}
		visualItems = [];
		scrollY = 0;
		scrollLerp = 0;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (viewHeight > 0) {
			scrollLerp += (scrollY - scrollLerp) * (elapsed * 10);

			listContainer.x = this.x;
			listContainer.y = this.y - scrollLerp;

			if (clipMask != null) {
				clipMask.clipX = this.x;
				clipMask.clipY = this.y + baseY;
				clipMask.apply(listContainer);
			}
		} else {
			listContainer.x = this.x;
			listContainer.y = this.y;
			if (listContainer.clipRect != null) {
				listContainer.clipRect = null;
			}
		}

		if (canInput && entries.length > 0)
			handleInput();
	}

	public function handleInput():Void {
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
		if (selection < 0)
			selection = (change > 0) ? 0 : entries.length - 1;
		else
			selection = FlxMath.wrap(selection + change, 0, entries.length - 1);
		highlightSelection();
	}

	public function acceptSelection():Void {
		if (entries[selection]?.action != null) {
			FlxG.sound.play(Flags.CONFIRM);
			entries[selection].action();
		}
	}

	public function highlightSelection():Void {
		for (i in 0...visualItems.length) {
			var bgSprite:FlxSprite = cast visualItems[i].members[0];
			bgSprite.makeGraphic(Std.int(bgSprite.width), Std.int(bgSprite.height), (i == selection) ? SELECT_COLOR : FlxColor.TRANSPARENT);
		}

		if (viewHeight > 0) {
			var itemTop = (selection * itemSeparation) + 5;
			var itemBottom = itemTop + itemHeight;

			if (itemTop < scrollY + 5) {
				scrollY = itemTop - 5;
			} else if (itemBottom > scrollY + viewHeight - 5) {
				scrollY = itemBottom + 5 - viewHeight;
			}

			var fullHeight = (entries.length * itemSeparation) - (itemSeparation - itemHeight) + 10;
			var maxScroll = Math.max(0, fullHeight - viewHeight);

			if (scrollY > maxScroll)
				scrollY = maxScroll;
			if (scrollY < 0)
				scrollY = 0;
		}
	}

	public function resetSelection():Void {
		selection = 0;
		scrollY = 0;
		scrollLerp = 0;
		highlightSelection();
	}
}
