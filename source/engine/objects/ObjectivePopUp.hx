package engine.objects;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class ObjectivePopUp extends FlxText {
	public function new(status:String, objectiveName:String) {
		super(FlxG.width, 50, 0, "Objective " + status + "!\n" + objectiveName, 32);
		alignment = RIGHT;
		scrollFactor.set(0, 0);

		FlxTween.tween(this, {x: FlxG.width - width - 20}, 0.5, {
			ease: FlxEase.quadOut,
			onComplete: function(_) {
				FlxTween.tween(this, {x: FlxG.width}, 0.5, {
					ease: FlxEase.quadIn,
					startDelay: 2.5,
					onComplete: function(_) {
						this.destroy();
					}
				});
			}
		});
	}
}
