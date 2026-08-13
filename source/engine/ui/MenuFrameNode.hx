package engine.ui;

import lang.LangText;

class MenuFrameNode extends FlxSpriteGroup {
    public var nodeFrame:SpecialNinePatch;

    public var titleText:LangText;
    public var divider:FlxSprite;
    public var hasTitle:Bool = false;

    public function new(X:Float = 0, Y:Float = 0, targetWidth:Float, targetHeight:Float, mode:Int = 0) {
        super(X, Y);
        hasTitle = mode == 2;

        nodeFrame = new SpecialNinePatch();

        if (mode == 1 || mode == 2) {
            nodeFrame.texture = '${Flags.imageFolder}ui/frames/frame_menu_2.png';
            nodeFrame.bgTexture = '${Flags.imageFolder}ui/frames/frame_menu_bg.png';
            nodeFrame.bgMaskTexture = null;
            nodeFrame.patchMarginLeft = 50;
            nodeFrame.patchMarginTop = 50;
            nodeFrame.patchMarginRight = 50;
            nodeFrame.patchMarginBottom = 50;
            nodeFrame.scaleFactor = 0.75;

            if (mode == 2) {
                titleText = new LangText(0, 30, Std.int(targetWidth), "", null, 48);
                titleText.alignment = CENTER;

                divider = new FlxSprite(0, 90);
                divider.loadGraphic(Assets.getImage('ui/dividers/divider_md'));
                divider.scale.set(0.75, 0.75);
                divider.updateHitbox();
                divider.x = (targetWidth - divider.width) / 2;
            }
        } else {
            nodeFrame.texture = '${Flags.imageFolder}ui/frames/frame_default.png';
            nodeFrame.bgTexture = '${Flags.imageFolder}ui/frames/frame_default_bg.png';
            nodeFrame.bgMaskTexture = '${Flags.imageFolder}ui/masks/frame_default_bg_mask.png';
            nodeFrame.patchMarginLeft = 123;
            nodeFrame.patchMarginTop = 142;
            nodeFrame.patchMarginRight = 123;
            nodeFrame.patchMarginBottom = 120;
            nodeFrame.scaleFactor = 0.45;
        }

        nodeFrame.setSizeEx(targetWidth, targetHeight);
        add(nodeFrame);

        if (mode == 2) {
            add(titleText);
            add(divider);
        }
    }

    public function setTitle(textKey:String):Void {
        if (hasTitle && titleText != null) {
            titleText.setTranslation(textKey);

            var showTitle = (textKey != null && textKey.length > 0);
            titleText.visible = showTitle;
            divider.visible = showTitle;
        }
    }

    public function addMenu(menu:FlxSpriteGroup):Void {
        menu.x = 54;
        menu.y = hasTitle && titleText.visible ? 130 : 36;
        add(menu);
    }
}