import engine.backend.Game;

public static var test:String = "hello";
public static var curRoom:String = null;
public static var targetSpawn:String = "";

function gameResized(w, h)
{
    
}

public static function openDialog(dialog, start, onComplete)
{
    Game.instance.playDialogue(dialog, start, onComplete);
}
