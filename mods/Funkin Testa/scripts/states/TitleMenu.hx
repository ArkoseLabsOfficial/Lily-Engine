import flixel.text.FlxTextBorderStyle;

class TitleMenu {
    function createPost() {
        bg.loadGraphic("images/MainBG.jpg");
        bg.x = 0;
        bg.y = 0;
        bg.setGraphicSize(1920, 1180);
        bg.antialiasing = true;
        bg.updateHitbox();
        add(bg);

        titleLogo.visible = false;
        var text = new FlxText(1100, 400, 1000, "Neverness To Everness", 70);
        text.borderStyle = FlxTextBorderStyle.OUTLINE;
        text.borderSize = 2;
        add(text);
    }
}