class PauseMenu {
    function create() {
        isAnimating = true;
    }
    function createPost() {
        pauseMenu.x += 1445;
        members[1].x += 1450;
        members[2].x += 1450;
        members[3].x += 1450;
        members[5].x += 1450;


        isAnimating = true;
		canInput = true;
		if (pauseMenu != null)
			pauseMenu.canInput = true;

        var slideOffset:Float = 450.0;
		var duration:Float = 0.15;

        members[1].x += slideOffset;
		members[4].x += slideOffset;
		members[2].x += slideOffset;
		members[5].x += slideOffset;
		members[3].x += slideOffset;

		FlxTween.tween(members[0], {alpha: 1}, duration);
		FlxTween.tween(members[1], {x: members[1].x - slideOffset}, duration, {ease: FlxEase.quadOut});
		FlxTween.tween(members[4], {x: members[4].x - slideOffset}, duration, {ease: FlxEase.quadOut});
		FlxTween.tween(members[2], {x: members[2].x - slideOffset}, duration, {ease: FlxEase.quadOut, startDelay: 0.08});
		FlxTween.tween(members[5], {x: members[5].x - slideOffset}, duration, {ease: FlxEase.quadOut, startDelay: 0.08});

		FlxTween.tween(members[3], {x: members[3].x - slideOffset}, duration, {
			ease: FlxEase.quadOut,
			startDelay: 0.16,
			onComplete: function(twn:FlxTween) {
				isAnimating = false;
				canInput = true;
				if (pauseMenu != null)
					pauseMenu.canInput = true;
			}
		});
    }

    function onAnimating(event) {
        event.cancelled = true;
    }
}