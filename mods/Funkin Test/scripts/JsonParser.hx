import haxe.format.JsonParser as Parser;

class JsonParser {
    public static function parse(str:String) {
        return new Parser(str).doParse();
    }
}