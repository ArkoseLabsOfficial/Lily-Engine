import engine.objects.Character.FacingDirection;

class SpawnPoint {
    public var Direction:String = "Down";
    public var Layer:Int = 1;

    public static function loadSpawnPoint(point:String) {
        var entrance = Game.room.scene.getNode(point);
        if (entrance != null) {
            Game.party[0].direction = FacingDirection.UP;
            Game.party[0].x = entrance.x;
            Game.party[0].y = entrance.y;
        }
    }

    public function onRoomLoaded(roomName:String) {
        // Since GameRoom.hx resolves these via Game.room.scene.getNode(), 
        // no static dictionary caching is needed here anymore. The Node inherently
        // exists on the scene tree with this script attached.
        var entrance = Game.room.scene.getNode("Points/entrance");
        if (entrance != null) {
            Game.party[0].direction = FacingDirection.UP;
            Game.party[0].x = entrance.x;
            Game.party[0].y = entrance.y;
        }
    }
}