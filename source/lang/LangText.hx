package lang;

import flixel.FlxG;

class LangText extends GameText {
    private static var instances:Array<LangText> = [];
    private var translationKey:String;
    private var translationVars:Array<Dynamic>;
    private var fontKey:String;

    public function new(x:Float = 0, y:Float = 0, maxWidth:Float = 0, key:String = "", ?vars:Array<Dynamic>, size:Int = 16, ?font:String) {
        super(x, y, "", size, font);
        this.maxWidth = maxWidth;
        instances.push(this);
        setTranslation(key, vars);
    }

    public function setTranslation(key:String, ?vars:Array<Dynamic>):Void {
        translationKey = key;
        translationVars = vars;
        updateText();
    }

    public function getTranslation(key:String, ?vars:Array<Dynamic>):String {
        translationKey = key;
        translationVars = vars;
        if (translationKey != null && translationKey.length > 0) {
            return Lang.get(translationKey, translationVars);
        }
        return translationKey;
    }

    public function updateVars(vars:Array<Dynamic>):Void {
        translationVars = vars;
        updateText();
    }

    public function setFont(newFontKey:String):Void {
        fontKey = newFontKey;
        applyFont();
    }

    private function applyFont():Void {
        if (fontKey == null) fontKey = "NotoSans";

        if (Flags.fonts != null && Flags.fonts.exists(fontKey)) {
            font = Flags.fonts.get(fontKey);
        }
    }

    public function refresh():Void {
        updateText();
        applyFont();
    }

    public static function refreshAll():Void {
        var i:Int = instances.length;
        while (i-- > 0) {
            var instance = instances[i];
            if (instance == null || !instance.exists) {
                instances.splice(i, 1);
            } else {
                instance.refresh();
            }
        }
    }

    private function updateText():Void {
        if (translationKey != null && translationKey.length > 0) {
            text = Lang.get(translationKey, translationVars);
        }
    }

    override public function destroy():Void {
        instances.remove(this);
        super.destroy();
    }
}