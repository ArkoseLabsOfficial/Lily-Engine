import engine.backend.game.RoomManager;
import engine.backend.Controls;
import engine.objects.Character.FacingDirection;

class PlayerProps {
	public static var sitting:Bool = false;

	public static function update() {
		if (sitting && Controls.CANCEL) {
			var player = RoomManager.instance.player;
			RoomManager.instance.changeLayer(player, "Main");
			player.canMove = true;
			player.playAnim("", true);
			player.y += 45;
			player.direction = FacingDirection.DOWN;
			sitting = false;
		}
	}

	public static function sit(object, anim, offsetX, offsetY) {
		if (!PlayerProps.sitting) {
			var player = RoomManager.instance.player;
			player.canMove = false;
			player.velocity.set(0, 0);
			player.playAnim(anim, true);
			player.x = object.x + offsetX;
			player.y = object.y + offsetY;
			PlayerProps.sitting = true;
		}
	}
}
