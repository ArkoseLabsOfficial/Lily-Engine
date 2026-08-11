import engine.backend.game.RoomManager;
import engine.states.BaseRoom;
import engine.objects.Character.FacingDirection;

public var Direction:Int = 0;
public var Layer:Int = 1;
public var Default:Bool = false;
public var targetSpawn:String = "";

public function onRoomLoaded() {
    if (obj.nodeName != targetSpawn && !Default)
        return;

    var room = RoomManager.instance;
    switch (Direction) {
        case 1: room.player.direction = FacingDirection.DOWN;
        case 2: room.player.direction = FacingDirection.LEFT;
        case 3: room.player.direction = FacingDirection.UP;
        case 4: room.player.direction = FacingDirection.RIGHT;
    }
    room.player.x = obj.x;
    room.player.y = obj.y;
}
