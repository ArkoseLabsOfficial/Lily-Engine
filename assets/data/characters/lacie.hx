importScript("PlayerProps");
var idleTimer:Float = 0;
var idleDelay:Float = 5.0;
var isPlayingSpecialIdle:Bool = false;

using StringTools;

class lacie {
	function create() {
		idleTimer = 0;
		isPlayingSpecialIdle = false;
	}

	function update(elapsed:Float) {
		if (PlayerProps.sitting)
			return;

		if (isPlayingSpecialIdle && (Controls.UP_P || Controls.DOWN_P || Controls.LEFT_P || Controls.RIGHT_P)) {
			isPlayingSpecialIdle = false;
			idleTimer = 0;
			char.state = 0;
		}

		var vx = char.isFollowingPath ? char.pathVelocity.x : char.velocity.x;
		var vy = char.isFollowingPath ? char.pathVelocity.y : char.velocity.y;
		var speed = Math.sqrt((vx * vx) + (vy * vy));

		if (speed > 5) {
			idleTimer = 0;
			isPlayingSpecialIdle = false;
			return;
		}

		if (!isPlayingSpecialIdle) {
			idleTimer += elapsed;

			if (idleTimer >= idleDelay) {
				var specialAnim = "standing_" + char.direction;

				if (char.animData.exists(specialAnim)) {
					isPlayingSpecialIdle = true;
					char.playAnim(specialAnim, true);
				} else {
					idleTimer = 0;
				}
			}
		} else {
			if (char.visual.animation.curAnim == null || char.visual.animation.finished) {
				isPlayingSpecialIdle = false;
				idleTimer = 0;
				char.state = 0;
			}
		}
	}
}
