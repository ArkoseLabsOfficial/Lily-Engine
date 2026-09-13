import StringTools;

using StringTools;

class NPCStaticTurnable {
	public var DefaultDirection:String = "Down";
	public var TurningEnabled:Bool = true;

	public function onRoomLoaded(roomName:String) {
		turnToDefault();
	}

	public function turn(dirName:String) {
		var object = obj.getNode("Sprite");
		if (!TurningEnabled || object == null)
			return;

		var lowerDir:String = dirName.toLowerCase();
        switch(lowerDir) {
            case "left":
                object.Frame = 0;
            case "up":
                object.Frame = 1;
            case "right":
                object.Frame = 2;
            case "down", "downright":
                object.Frame = 3;
            case "none":
                object.Frame = 0;
        }
	}

    var direction:Array<String> = [
		"none",
		"left",
		"up",
		"upLeft",
		"right",
		"upRight",
		"down",
		"downLeft",
		"downRight"
	];

	public function turnToDefault() {
		if (TurningEnabled) {
			turn(direction[DefaultDirection]);
		}
	}   
    
}
