package engine.states;

class TitleMenu extends StateBackend {
	var bg:LangSprite;

	var hasSaveFile:Bool = false;

	override public function create() {
		super.create();
		for (slotNum in 0...31) {
			var info = Game.save.getSlotInfo(slotNum);
			if (!hasSaveFile && !info.isEmpty)
				hasSaveFile = true;
		}

		bg = new LangSprite(320, 180, Assets.getImagePath('ui/titleBG'));
		bg.antialiasing = true;
		bg.scale.set(1.5, 1.5);
		add(bg);

		menu = new NineNode(1300, 550, {
			texture: 'ui/new/border',
			bgTexture: 'ui/frames/frame_default_bg',
			scaleFactor: 2,
			widthOffset: -50,

			margin: {
				left: 10,
				top: 10,
				right: 10,
				bottom: 10
			},

			itemWidth: 300,
			itemHeight: 45,
			itemFontSize: 28,
			itemSeparation: 45,
			itemFont: 'AlegreyaSC',
			maxBeforeScroll: 0,
		});
		add(menu);

		if (hasSaveFile) {
			menu.addEntry("system.menu.loadgame", function() {
				openSubState(new SaveLoadMenu(false, true));
			});
		}
		menu.addEntry("system.menu.newgame", function() {
			startNewGame(new BaseRoom(Assets.getText('${Flags.roomFolder}/start_room.txt').trim()));
		});
		menu.addEntry("system.menu.mods", function() {
			openSubState(new ModSelectorMenu(function() {
				FlxG.switchState(new MainState());
			}));
		});
		menu.addEntry("system.menu.debugroom", function() {
			startNewGame(new BaseRoom("DebugRoom"));
		});
		menu.addEntry("system.menu.settings", function() {
			openSubState(new SettingsMenu());
		});
		menu.addEntry("system.menu.website.translator", function() {});
		menu.addEntry("Title Menu", function() {
			FlxG.switchState(new TitleMenu());
		});
		menu.addEntry("system.menu.quit", function() {
			System.exit(0);
		});

		menu.buildVisualList();

		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.addDPad("FULL");
		Game.mobileC.addButton("MENU");
		#end

		Discord.updatePresence('In the title menu', 'Mod: ${GamePrefs.currentMod}');
	}

	public override function closeSubState() {
		super.closeSubState();
		Discord.updatePresence('In the title menu', 'Mod: ${GamePrefs.currentMod}');
	}

	public function startNewGame(state:Dynamic) {
		Game.save.reset();
		Game.items.reset();
		var event = event("onStartingNewGame", new CancellableEvent());
		if (!event.cancelled)
			FlxG.switchState(state);
	}
}
