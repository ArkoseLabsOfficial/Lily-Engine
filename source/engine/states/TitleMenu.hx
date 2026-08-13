package engine.states;

class TitleMenu extends StateBackend {
	var bg:FlxSprite;
	var titleLogo:FlxSprite;
	var extraInfoText:FlxText;
	var versionInfoText:FlxText;

	var menuFrame:MenuFrameNode;

	var hasSaveFile:Bool = false;

	override public function create():Void {
		super.create();

		for (slotNum in 0...31) {
			var info = Game.save.getSlotInfo(slotNum);
			if (!hasSaveFile && !info.isEmpty)
				hasSaveFile = true;
		}

		bg = new FlxSprite(0, 0).loadGraphic(Assets.getImage('ui/titleBG'));
		bg.setGraphicSize(1920, 1080);
		bg.updateHitbox();
		add(bg);

		titleLogo = new FlxSprite(1134, 282, Assets.getImage('ui/titleLogo'));
		add(titleLogo);

		extraInfoText = new FlxText(0, FlxG.height - 65, FlxG.width - 15, "", 24);
		extraInfoText.alignment = RIGHT;
		add(extraInfoText);

		versionInfoText = new FlxText(0, FlxG.height - 35, FlxG.width - 15, "v1.1.6 Debug © Leef 6010 2024", 24);
		versionInfoText.alignment = RIGHT;
		add(versionInfoText);

		simpleMenu = new SimpleVerticalMenu();

		if (hasSaveFile) {
			simpleMenu.addEntry("system.menu.loadgame", function() {
				openSubState(new SaveLoadMenu(false, true));
			});
		}
		simpleMenu.addEntry("system.menu.newgame", function() {
			startNewGame(new BaseRoom(Assets.getText('${Flags.roomFolder}start_room.txt').trim()));
		});
		simpleMenu.addEntry("system.menu.mods", function() {
			openSubState(new ModSelectorMenu(function() {
				StateBackend.switchState(new MainState());
			}));
		});
		simpleMenu.addEntry("system.menu.debugroom", function() {
			startNewGame(new BaseRoom("DebugRoom"));
		});
		simpleMenu.addEntry("system.menu.settings", function() {
			openSubState(new SettingsMenu());
		});
		simpleMenu.addEntry("system.menu.website.translator", function() {});
		simpleMenu.addEntry("system.menu.quit", function() {
			System.exit(0);
		});

		var frameX:Float = 1300;
		var frameY:Float = 561;
		var layoutSpacing:Float = 50;

		menuFrame = new MenuFrameNode(frameX, frameY, 400, (simpleMenu.entries.length * layoutSpacing) + 60, 0);
		add(menuFrame);

		simpleMenu.x = frameX;
		simpleMenu.y = frameY + 30;
		simpleMenu.itemWidth = 400;
		simpleMenu.itemFontSize = 25;
		simpleMenu.buildVisualList(layoutSpacing);
		add(simpleMenu);

		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.addDPad("FULL");
		Game.mobileC.addButton("MENU");
		#end
	}

	public function startNewGame(state:Dynamic) {
		Game.save.reset();
		Game.items.reset();
		StateBackend.switchState(new BaseRoom("DebugRoom"));
	}
}
