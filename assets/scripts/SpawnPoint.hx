import engine.objects.Character.FacingDirection;

importScript("GameProperties");
class SpawnPoint {
	public var direction:Int = 1;
	public var layer:Int = 1;
	public var defaultSpawn:Bool = false;

	public function loadSpawnPoint(point:String) {
		var entrance = Game.room.scene.getNode('Points/$point');
		if (entrance != null) {
			Game.party[0].direction = toDirection(direction);
			Game.party[0].x = entrance.x;
			Game.party[0].y = entrance.y;
		}
	}

	public function onRoomLoaded(roomName:String) {

		if (GameProperties.spawnLocation != null && GameProperties.spawnLocation != "" && GameProperties.spawnLocation == obj.name) {
			loadSpawnPoint(GameProperties.spawnLocation);
			GameProperties.spawnLocation = "";
		} else if (defaultSpawn && GameProperties.spawnLocation == "") {
			GameProperties.spawnLocation = null;
		} else if (defaultSpawn) {
			if (toDirection(direction) != "none")
				Game.party[0].direction = toDirection(direction);

			Game.party[0].x = obj.x;
			Game.party[0].y = obj.y;
		}
	}

	public function toDirection(number:Int):String {
		return switch (number) {
			case 0: "none";
			case 1: "down";
			case 2: "left";
			case 3: "up";
			case 4: "right";
		};
	}
}
