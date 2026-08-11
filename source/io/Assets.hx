package io;

/**
 * A custom and simplified Assets class that will take LilyAssets's job in the near future.
 * TODO:
 * 1- Implement getContent and readDirectory.
 * 2- Implement Mod System.
 **/
class Assets {
    public static var currentMod:String = '';
    public static function getContent(path:String, type:Types) {
        switch(type) {
            case IMAGE:
                //image stuff.
            case TEXT:
                //text stuff.
            case VIDEO:
                //video stuff.
        }
    }

    public static function readDirectory(path:String) {
        //
    }
}


enum abstract Types(String) {
    var IMAGE = 'image';
    var TEXT = 'text';
    var VIDEO = 'video';
}