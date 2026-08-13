import engine.objects.Character.FacingDirection;

class PlayerProps {
	public static var sitting:Bool = false;

	public static function update() {
		if (sitting && Controls.CANCEL) {
			var player = Game.party[0];
			Game.room.scene.changeLayer(player, "Main");
			player.canMove = true;
			player.playAnim("", true);
			player.y += 45;
			player.direction = FacingDirection.DOWN;
			sitting = false;
		}
	}

	public static function sit(object, anim, offsetX, offsetY) {
		if (!PlayerProps.sitting) {
			var player = Game.party[0];
			player.canMove = false;
			player.velocity.set(0, 0);
			player.playAnim(anim, true);
			player.x = object.x + offsetX;
			player.y = object.y + offsetY;
			PlayerProps.sitting = true;
		}
	}
}
