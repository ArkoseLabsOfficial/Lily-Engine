package lang;

import flixel.text.FlxText;

/**
 * Extended FlxText that automatically updates when language changes
 */
class LangText extends FlxText {
    private static var instances:Array<LangText> = [];
    private var translationKey:String;
    private var translationVars:Array<Dynamic>;

    /**
     * Create a new LangText
     * @param x X position
     * @param y Y position
     * @param fieldWidth Width of the text field
     * @param key Translation key
     * @param vars Optional variables for translation
     * @param size Font size
     */
    public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, key:String = "", ?vars:Array<Dynamic>, size:Int = 8) {
        var text = getTranslation(key, vars);
        super(x, y, fieldWidth, text, size);
        instances.push(this);
    }

    /**
     * Set or update the translation key
     * @param key Translation key
     * @param vars Optional variables for translation
     */
    public function setTranslation(key:String, ?vars:Array<Dynamic>):Void {
        translationKey = key;
        translationVars = vars;
        updateText();
    }

    /**
     * Set or update the translation key
     * @param key Translation key
     * @param vars Optional variables for translation
     */
    public function getTranslation(key:String, ?vars:Array<Dynamic>):String {
        translationKey = key;
        translationVars = vars;
        if (translationKey != null && translationKey.length > 0) {
            return Lang.get(translationKey, translationVars);
        }
        return translationKey;
    }

    /**
     * Update variables without changing the key
     * @param vars New variables for translation
     */
    public function updateVars(vars:Array<Dynamic>):Void {
        translationVars = vars;
        updateText();
    }

    /**
     * Refresh the translation (useful after language change)
     */
    public function refresh():Void {
        updateText();
    }

    /**
     * Reloads all currently active LangText instances
     */
    public static function refreshAll():Void {
        var i:Int = instances.length;
        while (i-- > 0) {
            var instance = instances[i];
            if (instance == null || instance.exists == false) {
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

    override function update(elapsed:Float):Void {
        super.update(elapsed);
    }

    override public function destroy():Void {
        instances.remove(this);
        super.destroy();
    }
}