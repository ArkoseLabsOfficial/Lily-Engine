import flixel.math.FlxRect;
import flixel.FlxG;
import engine.backend.game.RoomManager;
import engine.objects.Character;
import engine.objects.Character.FacingDirection;

public var CharacterName:String = "lacie";
public var Direction:Int = 1; // Custom=0, Down=1, Left=2, Up=3, Right=4
public var AnimationName:String = "";
public var Layer:Int = 1;
public var Event:String = "";

var characterInstance:Character = null;

function create() {
    trace("worked");
    var px = obj.x;
    var py = obj.y;

    characterInstance = new Character(px, py, Layer, obj.nodeName);
    characterInstance.loadEntity("", CharacterName);

    var targetNode:Dynamic = RoomManager.instance.currentScene.getNode("Main");
    if (targetNode == null)
        targetNode = RoomManager.instance.currentScene.root;

    if (targetNode != null)
        targetNode.add(characterInstance);

    switch (Direction) {
        case 1: characterInstance.direction = FacingDirection.DOWN;
        case 2: characterInstance.direction = FacingDirection.LEFT;
        case 3: characterInstance.direction = FacingDirection.UP;
        case 4: characterInstance.direction = FacingDirection.RIGHT;
    }

    if (AnimationName != null && AnimationName != "") {
        trace(AnimationName);
        characterInstance.playAnim(AnimationName, true);
    }
}

function update(elapsed:Float) {
    if (characterInstance == null) return;

    var player = RoomManager.instance.player;
    var isOverlapping = false;

    if (player != null && player.canMove) {
        var iBox = player.getInteractionBox();
        var eBox = characterInstance.getCollisionBox();

        if (iBox != null && eBox != null) {
            isOverlapping = iBox.overlaps(eBox);
            iBox.put();
            eBox.put();
        } else {
            if (iBox != null) iBox.put();
            if (eBox != null) eBox.put();
        }
    }

    var confirmPressed = Controls.ACCEPT || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z;
    if (isOverlapping && confirmPressed)
        fireEvent();
}

function fireEvent() {
    var evtName = (Event != null && Event != "") ? Event : obj.nodeName;
    trace("Character Interaction Triggered: " + evtName);

    switch (evtName) {
        case "open_hiro_dialog":
            Global.openDialog("hiro_sitting", "start", null);
        case "open_dead_lacie_dialog":
            Global.openDialog("lacie_dead", "start", null);
    }
}
