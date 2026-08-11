import flixel.util.FlxTimer;

var image:FlxSprite;
var dialogCamera:FlxCamera;

function create() {
	image = new FlxSprite(0, 0, LilyAssets.image("dialogs/images/hiro_bench"));
	FlxG.state.add(image);
	image.alpha = 0;

	dialogCamera = new FlxCamera();
	dialogCamera.bgColor = FlxColor.TRANSPARENT;
	FlxG.cameras.add(dialogCamera, false);
	dialogCamera.zoom = 1;
	image.cameras = [dialogCamera];
}

function postCreate() {
	dialogBox.alpha = 0;
}

function openImageBoard() {
	FlxTween.tween(image, {alpha: 1}, 0.25);
	FlxTween.tween(dialogBox, {alpha: 1}, 0.25);
}

function hiroLook() {
	image.loadGraphic(LilyAssets.image("dialogs/images/hiro_bench_2"));
}

function hiroTalk() {
	image.loadGraphic(LilyAssets.image("dialogs/images/hiro_bench_3"));
}

function lacieSit() {
	FlxG.state.persistentUpdate = true;
    faceEntity("player", "right");
    walkEntity("player", 300, 150, 60, function() {
		player.y = 147;
		player.playAnim("sitDOWN", true);
		changeLayer("player", "UpperObjects");
	});
}

var boardClosed:Bool = false;

function closeImageBoard() {
	if (boardClosed)
		return;
	boardClosed = true;

	dialog.pause();
	// FlxTween.tween(dialogBox, { alpha:0 }, 0.40);
    FlxTween.tween(dialogBox, {y: dialogBox.y + 500}, 0.30);
	FlxTween.tween(image, {alpha: 0}, 0.25);

	new FlxTimer().start(0.50, function(tmr) {
		FlxTween.tween(dialogBox, {y: dialogBox.y - 500}, 0.30, {
			onComplete: function(twn) {
				new FlxTimer().start(0.50, function(tmr) {
                    dialog.resume();
                });
			}
		});
	});
}

function allow() {
	lockPlayer(false);
}
