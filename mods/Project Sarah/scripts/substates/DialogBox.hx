package substates;

class DialogBoxHelper {
	public static function hideUI(delay:Float = 0.25, ?onFinished:Dynamic = {}) {
		var box = DialogBox.instance.box;
		if (delay == 0) {
			box.y += 100;
			box.alpha = 0;
            onFinished();
		} else {
			FlxTween.tween(box, {y: box.y + 100, alpha: 0}, delay, {
				onComplete: onFinished
			});
		}
	}

	public static function showUI(delay:Float = 0.25, ?onFinished:Dynamic = {}) {
		var box = DialogBox.instance.box;
		if (delay == 0) {
			box.y -= 100;
			box.alpha = 1;
            onFinished();
		} else {
			FlxTween.tween(box, {y: box.y - 100, alpha: 1}, delay, {
				onComplete: onFinished
			});
		}
	}
}
