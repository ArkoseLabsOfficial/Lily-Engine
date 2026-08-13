package godot;

import io.File;
import io.FileSystem;

class Config {
    public static function getContent(value:String):Dynamic {
        if (value.startsWith("assets/")) value = value.replace("assets/", "");
        if (value.startsWith("images/")) value = value.replace("images/", "");
        if (value.endsWith(".png")) {
            return Assets.getBitmapData(Flags.imageFolder + value);
        }
        return Assets.getText(value);
    }

    public static function exists(value:String) {
        if (value.startsWith("assets/")) value = value.replace("assets/", "");
        if (value.startsWith("images/")) value = value.replace("images/", "");
        return Assets.exists(value);
    }

    public static function getBitmapData(value:String) {
        if (value.startsWith("assets/")) value = value.replace("assets/", "");
        if (value.startsWith("images/")) value = value.replace("images/", "");
        return Assets.getBitmapData(Flags.imageFolder + value);
    }
}