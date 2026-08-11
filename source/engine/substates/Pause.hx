package engine.substates;

import lang.LangText;

class Pause extends SubStateBackend {
	var pauseMenu:SimpleVerticalMenu;
	var isAnimating:Bool = true;

	public var canInput:Bool = false;

	public function new() {
		super();
	}

	override public function create():Void {
		super.create();

		persistentUpdate = true;
		Game.paused = true;

		var pauseBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
		pauseBG.scrollFactor.set(0, 0);
		pauseBG.alpha = 0;
		add(pauseBG);

		var mainFrame = new MenuFrameNode(10, 10, 450, 600, 1);
		add(mainFrame);

		var chapterFrame = new MenuFrameNode(10, 615, 450, 135, 1);
		chapterFrame.nodeFrame.texture = "ui/frames/frame_menu_2b";
		add(chapterFrame);

		var bottomFrame = new MenuFrameNode(10, 755, 450, 240, 1);
		bottomFrame.nodeFrame.texture = "ui/frames/frame_menu_2b";
		add(bottomFrame);

		pauseMenu = new SimpleVerticalMenu();
		pauseMenu.canInput = false;

		pauseMenu.addEntry("system.menu.inventory", function() {
			openSubState(new Inventory());
		});
		pauseMenu.addEntry("system.menu.objectives", function() {
			openSubState(new Objectives());
		});
		pauseMenu.addEntry("system.menu.settings", function() {
			openSubState(new Settings("main", true));
		});
		pauseMenu.addEntry("system.menu.load", function() {
			openSubState(new SaveLoad(false, false));
		});
		pauseMenu.addEntry("system.menu.quit", function() {
			StateBackend.switchState(new TitleMenu());
		});

		pauseMenu.itemWidth = 440;
		pauseMenu.itemFontSize = 32;
		pauseMenu.buildVisualList(55);
		pauseMenu.x = 20;
		pauseMenu.y = 60;
		add(pauseMenu);

		var chapterText = new LangText(20, 660, 440, "system.menu.pause.text", null, 32);
		chapterText.alignment = CENTER;
		add(chapterText);

		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.addDPad("FULL");
		Game.mobileC.addButton("MENU");
		#end

		var slideOffset:Float = 450.0;
		var duration:Float = 0.15;

		mainFrame.x -= slideOffset;
		pauseMenu.x -= slideOffset;
		chapterFrame.x -= slideOffset;
		chapterText.x -= slideOffset;
		bottomFrame.x -= slideOffset;

		FlxTween.tween(pauseBG, {alpha: 1}, duration);
		FlxTween.tween(mainFrame, {x: mainFrame.x + slideOffset}, duration, {ease: FlxEase.quadOut});
		FlxTween.tween(pauseMenu, {x: pauseMenu.x + slideOffset}, duration, {ease: FlxEase.quadOut});
		FlxTween.tween(chapterFrame, {x: chapterFrame.x + slideOffset}, duration, {ease: FlxEase.quadOut, startDelay: 0.08});
		FlxTween.tween(chapterText, {x: chapterText.x + slideOffset}, duration, {ease: FlxEase.quadOut, startDelay: 0.08});

		FlxTween.tween(bottomFrame, {x: bottomFrame.x + slideOffset}, duration, {
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

	override public function openSubState(SubState:FlxSubState):Void {
		canInput = false;
		if (pauseMenu != null)
			pauseMenu.canInput = false;
		super.openSubState(SubState);
	}

	override public function closeSubState():Void {
		canInput = true;
		if (pauseMenu != null)
			pauseMenu.canInput = true;
		super.closeSubState();
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (isAnimating || !canInput)
			return;

		if (Controls.CANCEL && pauseMenu.canInput) {
			LilyAssets.play(LilyAssets.CANCEL);
			close();
		}
	}

	override public function close():Void {
		Game.paused = false;
		super.close();
	}
}
