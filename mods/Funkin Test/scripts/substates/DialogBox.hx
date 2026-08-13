class DialogBox {
    function createPost() {
        var dialogBG = new FlxSprite(0, 0);
        dialogBG.loadGraphic("images/dialogBG.png");
        
        dialogBG.x = bg.x;
        dialogBG.y = bg.y;
        
        insert(0, dialogBG);
        dialogBG.x *= 2.31;
        dialogBG.scale.x = 13.59;
        dialogBG.y *= 1.185;
        dialogBG.scale.y = 3.65;


        var dialogBorder = new SpecialNinePatch(0, 0);
        dialogBorder.texture = "images/dialogBorder.png";
        dialogBorder.x = bg.x;
        dialogBorder.y = bg.y;
        dialogBorder.patchMarginLeft = 10;
        dialogBorder.patchMarginTop = 10;
        dialogBorder.patchMarginRight = 10;
        dialogBorder.patchMarginBottom = 10;
        dialogBorder.scaleFactor = 2;
        dialogBorder.setSizeEx(1000, 270);
        dialogBorder.x += 75;
        dialogBorder.y += 35;
        insert(1, dialogBorder);

        nameText.font = "fonts/AlegreyaSC-Regular.ttf";
        bodyText.font = "fonts/AlegreyaSC-Regular.ttf";
        remove(bg);
        nameSeperator.y += 5;
    }
}