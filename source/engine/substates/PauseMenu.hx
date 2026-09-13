package engine.substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import engine.ui.NineNode;
import lang.LangText;

class PauseMenu extends SubStateBackend {
	var pauseMenu:NineNode;
	var chapterFrame:NineNode;
	var bottomFrame:NineNode;
	var chapterText:LangText;

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

		var mainData:NineNodeMenuData = {
			width: 450,
			height: 600,
			texture: 'ui/frames/frame_menu_2',
			bgTexture: 'ui/frames/frame_menu_bg',
			margin: {
				left: 50,
				top: 50,
				right: 50,
				bottom: 50
			},
			scaleFactor: 0.75,
			itemWidth: 340,
			itemHeight: 50,
			itemFontSize: 32,
			itemSeparation: 50,
			itemAlignment: CENTER,
			listAlignment: "top"
		};
		pauseMenu = new NineNode(10, 10, mainData);
		pauseMenu.canInput = false;

		pauseMenu.addEntry("system.menu.inventory", function() {
			openSubState(new InventoryMenu());
		});
		pauseMenu.addEntry("system.menu.objectives", function() {
			openSubState(new ObjectivesMenu());
		});
		pauseMenu.addEntry("system.menu.settings", function() {
			openSubState(new SettingsMenu(true));
		});
		pauseMenu.addEntry("system.menu.load", function() {
			openSubState(new SaveLoadMenu(false, false));
		});
		pauseMenu.addEntry("system.menu.quit", function() {
			FlxG.switchState(new TitleMenu());
		});

		pauseMenu.buildVisualList();
		add(pauseMenu);

		var chapterData:NineNodeMenuData = {
			width: 450,
			height: 135,
			texture: 'ui/frames/frame_menu_2b',
			bgTexture: 'ui/frames/frame_menu_bg',
			margin: {
				left: 50,
				top: 50,
				right: 50,
				bottom: 50
			},
			scaleFactor: 0.75
		};
		chapterFrame = new NineNode(10, 615, chapterData);
		add(chapterFrame);

		chapterText = new LangText(10, 660, 450, "system.menu.pause.text", null, 32);
		chapterText.alignment = CENTER;
		add(chapterText);

		var bottomData:NineNodeMenuData = {
			width: 450,
			height: 240,
			texture: 'ui/frames/frame_menu_2b',
			bgTexture: 'ui/frames/frame_menu_bg',
			margin: {
				left: 50,
				top: 50,
				right: 50,
				bottom: 50
			},
			scaleFactor: 0.75
		};
		bottomFrame = new NineNode(10, 755, bottomData);
		add(bottomFrame);

		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.addDPad("FULL");
		Game.mobileC.addButton("MENU");
		#end

		var slideOffset:Float = 450.0;
		var duration:Float = 0.15;

		var event = event("onAnimating", new CancellableEvent());
		if (event.cancelled) {
			isAnimating = false;
			canInput = true;
			if (pauseMenu != null)
				pauseMenu.canInput = true;
		} else {
			pauseMenu.x -= slideOffset;
			chapterFrame.x -= slideOffset;
			chapterText.x -= slideOffset;
			bottomFrame.x -= slideOffset;

			FlxTween.tween(pauseBG, {alpha: 1}, duration);
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
		Discord.updatePresence('In the pause menu', 'Mod: ${GamePrefs.currentMod}');
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (isAnimating || !canInput)
			return;

		if (Controls.BACK && pauseMenu.canInput) {
			FlxG.sound.play(Flags.CANCEL);
			close();
		}
	}

	override public function close():Void {
		Game.paused = false;
		super.close();
	}
}
