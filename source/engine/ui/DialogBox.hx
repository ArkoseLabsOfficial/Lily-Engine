package engine.ui;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.addons.text.FlxTypeText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import io.LilyAssets;
import engine.backend.game.DialogueManager;

class DialogBox extends FlxSpriteGroup {
	var bg:FlxSprite;
	var nameText:FlxText;
	var nameSeperator:FlxSprite;
	var bodyText:FlxTypeText;
	var continueIcon:FlxSprite;

	public var isTyping:Bool = false;

	public function new() {
		super();

		bg = new FlxSprite(0, 0).loadGraphic(LilyAssets.image("ui/dialogs/dialogue"));
		bg.screenCenter(X);
		bg.y = FlxG.height - bg.height - 20;
		bg.scrollFactor.set(0, 0);
		add(bg);

		nameText = new FlxText(bg.x + 120, bg.y + 45, 400, "", 36);
		nameText.font = LilyAssets.font("AlegreyaSC-Regular");
		nameText.alignment = LEFT;
		nameText.scrollFactor.set(0, 0);
		add(nameText);

		nameSeperator = new FlxSprite(bg.x + 100, bg.y + 80);
		nameSeperator.loadGraphic(LilyAssets.image("ui/dialogs/name_seperator"));
		nameSeperator.scale.set(1.025, 1.025);
		nameSeperator.scrollFactor.set(0, 0);
		add(nameSeperator);

		bodyText = new FlxTypeText(bg.x + 120, bg.y + 105, Std.int(bg.width - 160), "", 33);
		bodyText.font = LilyAssets.font("fonts/AlegreyaSC-Regular.ttf");
		bodyText.eraseDelay = 0;
		bodyText.showCursor = false;
		bodyText.scrollFactor.set(0, 0);
		bodyText.completeCallback = function() {
			isTyping = false;
			continueIcon.visible = true;
			continueIcon.animation.play("blink");
		};
		add(bodyText);

		continueIcon = new FlxSprite(bg.x + bg.width - 200, bg.y + bg.height - 125);
		continueIcon.loadGraphic(LilyAssets.image("ui/dialogs/continue_indicator"), true, 95, 95);
		continueIcon.animation.add("blink", [0, 1, 2, 1], 6, true);
		continueIcon.scrollFactor.set(0, 0);
		add(continueIcon);
	}

	public function show(name:String, text:String, leftPath:String = "", rightPath:String = ""):Void {
		isTyping = true;
		continueIcon.visible = false;

		nameText.text = name;

		if (name == null || name == "") {
			nameText.visible = false;
			nameSeperator.visible = false;
			bodyText.y = bg.y + 55;
		} else {
			nameText.visible = true;
			nameSeperator.visible = true;
			bodyText.y = bg.y + 105;
		}

		var dialog = DialogueManager.instance;
		dialog.updatePortrait(dialog.portraitLeft, leftPath, dialog.leftBaseX, dialog.leftBaseY);
		dialog.updatePortrait(dialog.portraitRight, rightPath, dialog.rightBaseX, dialog.rightBaseY);

		this.visible = true;
		this.active = true;

		bodyText.resetText(text);
		bodyText.start(0.03, true);
	}

	public function pauseTyping(time:Float):Void {
		if (!isTyping || bodyText.paused)
			return;
		bodyText.paused = true;
		new flixel.util.FlxTimer().start(time, function(_) {
			bodyText.paused = false;
		});
	}

	public function hide(onComplete:Void->Void):Void {
		visible = false;
		onComplete();
	}

	public function advance():Bool {
		if (isTyping) {
			bodyText.skip();
			bodyText.paused = false;
			isTyping = false;
			continueIcon.visible = true;
			continueIcon.animation.play("blink");
			return false;
		}
		return true;
	}
}
