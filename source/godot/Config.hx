package godot;

import io.File;
import io.FileSystem;

class Config {
    public static function getContent(value:String):Dynamic {
        if (value.startsWith("assets/")) value = value.replace("assets/", "");
        if (value.startsWith("images/")) value = value.replace("images/", "");
        if (value.endsWith(".png")) {
            if (value.endsWith(".png")) value = value.replace(".png", "");
            return LilyAssets.image(value);
        }
        return LilyAssets.getTextFromFile(value);
    }

    public static function exists(value:String) {
        if (value.startsWith("assets/")) value = value.replace("assets/", "");
        if (value.startsWith("images/")) value = value.replace("images/", "");
        return LilyAssets.fileExists(value);
    }

    public static function getBitmapData(value:String) {
        if (value.startsWith("assets/")) value = value.replace("assets/", "");
        if (value.startsWith("images/")) value = value.replace("images/", "");
        if (value.endsWith(".png")) value = value.replace(".png", "");
        return LilyAssets.image(value);
    }
}