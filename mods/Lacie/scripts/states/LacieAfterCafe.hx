import flixel.FlxSprite;
import flixel.util.FlxTimer;

class LacieAfterCafe {
	var image:FlxSprite;
	var text:FlxText;

	function create() {
		FlxG.state.openSubState(new DialogBox("void", "cantGet"));
		FlxG.state.persistentUpdate = false;
		image = new FlxSprite(0, 0, "images/img/cg/ch1/intermission.png");
		image.antialiasing = true;
		add(image);
		text = new FlxText(100, 200, 0, "Lacie leaves the cafe and heads home\nas she enters through the front yard gate, she sees...", 50);
		text.font = "fonts/Ammys Handwriting.ttf";
		add(text);
		text.alpha = 0;
		image.alpha = 0;

		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeDPad();
		Game.mobileC.removeButton();
		#end
	}

	function showImage() {
		FlxG.sound.play("sounds/bgm/intermission.ogg");
		new FlxTimer().start(2, function() {
			FlxTween.tween(image, {alpha: 1}, 2);
			FlxTween.tween(text, {alpha: 1}, 2);
			new FlxTimer().start(5, function() {
				var black:FlxSprite = new FlxSprite(0, 0);
				black.makeGraphic(1920, 1080, FlxColor.BLACK);
				black.alpha = 0;
				add(black);
				FlxTween.tween(black, {alpha: 1}, 1, {
					onComplete: function() {
						FlxG.switchState(new TitleMenu());
					}
				});
			});
		});
	}
}
