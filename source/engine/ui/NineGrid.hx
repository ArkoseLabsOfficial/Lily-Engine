package engine.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import engine.ui.ImprovedNinePatch.MarginData;
import lang.LangText;

typedef NineGridData = {
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

    // Grid specific
    @:optional var columns:Int;
    @:optional var itemWidth:Float;
    @:optional var itemHeight:Float;
    @:optional var gapX:Float;
    @:optional var gapY:Float;
    @:optional var paddingX:Float;
    @:optional var paddingY:Float;

    @:optional var maxVisibleRows:Int;
}

typedef NineGridEntry = {
    var item:FlxSpriteGroup;
    var action:Void->Void;
}

class NineGrid extends FlxSpriteGroup {
    public var bg:ImprovedNinePatch;
    public var gridContainer:FlxSpriteGroup;
    
    public var selection:Int = 0;
    public var canInput:Bool = true;

    public var maxCols:Int;
    public var itemWidth:Float;
    public var itemHeight:Float;
    public var gapX:Float;
    public var gapY:Float;
    public var paddingX:Float;
    public var paddingY:Float;

    public var widthOffset:Float = 0;
    public var heightOffset:Float = 0;

    public var entries:Array<NineGridEntry> = [];

    public var titleText:LangText;
    public var divider:FlxSprite;
    public var hasTitle:Bool = false;

    public var maxVisibleRows:Int = 0;
    public var clipMask:ClipMask; 
    public var scrollY:Float = 0;
    public var scrollLerp:Float = 0;
    public var viewHeight:Float = 0;
    public var baseY:Float = 0;

    public var onSelectionChanged:Int->Void;

    private var initialData:NineGridData;

    public function new(x:Float, y:Float, data:NineGridData) {
        super(x, y);
        this.initialData = data;

        widthOffset = data.widthOffset ?? 0;
        heightOffset = data.heightOffset ?? 0;

        bg = new ImprovedNinePatch(0, 0);
        bg.texture = data.texture;
        bg.bgTexture = data.bgTexture;
        bg.bgMaskTexture = data.bgMaskTexture;
        if (data.margin == null) {
            data.margin = {left: 0, right: 0, top: 0, bottom: 0};
        }
        bg.margin = data.margin;
        bg.scaleFactor = data.scaleFactor ?? 1;

        if (data.width != null && data.height != null) {
            bg.resize(data.width + widthOffset, data.height + heightOffset);
        }
        add(bg);

        gridContainer = new FlxSpriteGroup();
        add(gridContainer);

        maxCols = data.columns ?? 5;
        itemWidth = data.itemWidth ?? 120;
        itemHeight = data.itemHeight ?? 120;
        gapX = data.gapX ?? 20;
        gapY = data.gapY ?? 20;
        
        divider = new FlxSprite(0, 90);

        if (data.title != null && data.title.length > 0) {
            setTitle(data.title);
        }
        
        paddingX = data.paddingX ?? 50;
        paddingY = data.paddingY ?? (hasTitle ? 130 : 50);
        maxVisibleRows = data.maxVisibleRows ?? 0;
    }

    public function setTitle(textKey:String):Void {
        if (!hasTitle) {
            hasTitle = true;
            var w = (initialData.width ?? 0) + widthOffset;
            titleText = new LangText(0, 30, Std.int(w), "", null, 48);
            titleText.alignment = CENTER;

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

    public function addItem(visualItem:FlxSpriteGroup, action:Void->Void = null):Void {
        entries.push({item: visualItem, action: action});
    }

    public function buildGrid():Void {
        for (e in entries) {
            gridContainer.remove(e.item, true);
        }

        var computedWidth = initialData.width ?? (paddingX * 2) + (maxCols * itemWidth) + ((maxCols - 1) * gapX);
        computedWidth += widthOffset;

        if (hasTitle && titleText != null && titleText.visible) {
            if (divider.graphic != null && divider.graphic.width > 0) {
                var targetScale = Math.min(1, computedWidth / divider.graphic.width);
                divider.scale.set(targetScale, 1);
                divider.updateHitbox();
            }
            divider.x = this.x + ((computedWidth - divider.width) / 2);
        }

        var totalRows = Math.ceil(entries.length / maxCols);
        if (totalRows == 0) totalRows = 1;

        var computedHeight = initialData.height ?? paddingY + 50 + (totalRows * itemHeight) + ((totalRows - 1) * gapY);
        computedHeight += heightOffset;

        bg.resize(computedWidth, computedHeight);

        baseY = paddingY;
        gridContainer.x = this.x;
        gridContainer.y = this.y;

        for (i in 0...entries.length) {
            var col = i % maxCols;
            var row = Math.floor(i / maxCols);

            var e = entries[i];
            e.item.x = paddingX + (col * (itemWidth + gapX));
            e.item.y = baseY + (row * (itemHeight + gapY));
            gridContainer.add(e.item);
        }

        if (maxVisibleRows > 0 && totalRows > maxVisibleRows) {
            viewHeight = (maxVisibleRows * itemHeight) + ((maxVisibleRows - 1) * gapY);
            clipMask = new ClipMask(this.x, this.y + baseY, computedWidth, viewHeight);
            clipMask.apply(gridContainer);
        } else {
            viewHeight = 0;
            clipMask = null;
            gridContainer.clipRect = null;
        }

        highlightSelection();
    }

    public function clearGrid():Void {
        for (e in entries) {
            gridContainer.remove(e.item, true);
            e.item.destroy();
        }
        entries = [];
        scrollY = 0;
        scrollLerp = 0;
        selection = 0;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (viewHeight > 0) {
            scrollLerp += (scrollY - scrollLerp) * (elapsed * 10);
            gridContainer.x = this.x;
            gridContainer.y = this.y - scrollLerp;

            if (clipMask != null) {
                clipMask.clipX = this.x;
                clipMask.clipY = this.y + baseY;
                clipMask.apply(gridContainer);
            }
        } else {
            gridContainer.x = this.x;
            gridContainer.y = this.y;
            if (gridContainer.clipRect != null) gridContainer.clipRect = null;
        }

        if (canInput && entries.length > 0) handleInput();
    }

    public function handleInput():Void {
        if (Controls.UP_P) changeSelection(-maxCols, false);
        else if (Controls.DOWN_P) changeSelection(maxCols, false);
        else if (Controls.LEFT_P) changeSelection(-1, true);
        else if (Controls.RIGHT_P) changeSelection(1, true);
        else if (Controls.ACCEPT) acceptSelection();
    }

    public function changeSelection(change:Int, isHorizontal:Bool):Void {
        FlxG.sound.play(Flags.NAVIGATE);
        
        if (isHorizontal) {
            var oldCol = selection % maxCols;
            selection += change;
            if (change == -1 && oldCol == 0) selection += maxCols;
            else if (change == 1 && oldCol == maxCols - 1) selection -= maxCols;
        } else {
            selection += change;
            if (selection < 0) selection += entries.length;
            if (selection >= entries.length) selection %= maxCols;
        }

        if (selection >= entries.length) selection = entries.length - 1;
        if (selection < 0) selection = 0;

        highlightSelection();
    }

    public function acceptSelection():Void {
        if (entries[selection]?.action != null) {
            entries[selection].action();
        } else {
            FlxG.sound.play(Flags.ERROR);
        }
    }

    public function highlightSelection():Void {
        if (viewHeight > 0) {
            var row = Math.floor(selection / maxCols);
            var itemTop = (row * (itemHeight + gapY));
            var itemBottom = itemTop + itemHeight;

            if (itemTop < scrollY) {
                scrollY = itemTop;
            } else if (itemBottom > scrollY + viewHeight) {
                scrollY = itemBottom - viewHeight;
            }

            var totalRows = Math.ceil(entries.length / maxCols);
            var fullHeight = (totalRows * itemHeight) + ((totalRows - 1) * gapY);
            var maxScroll = Math.max(0, fullHeight - viewHeight);
            
            if (scrollY > maxScroll) scrollY = maxScroll;
            if (scrollY < 0) scrollY = 0;
        }

        if (onSelectionChanged != null) {
            onSelectionChanged(selection);
        }
    }

    public function resetSelection():Void {
        selection = 0;
        scrollY = 0;
        scrollLerp = 0;
        highlightSelection();
    }
}