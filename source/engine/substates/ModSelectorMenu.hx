package engine.substates;

class ModSelectorMenu extends SubStateBackend {
	var menuFrame:MenuFrameNode;
	var onSelect:Void->Void;

	public function new(onSelect:Void->Void) {
		super(0xBB000000);
		this.onSelect = onSelect;
	}

	override public function create():Void {
		super.create();

		var frameW:Float = 600;
		var frameH:Float = 600;
		menuFrame = new MenuFrameNode(0, 0, frameW, frameH, 2);
		menuFrame.setTitle("system.mods.ui.title");
		menuFrame.screenCenter();
		add(menuFrame);

		simpleMenu = new SimpleVerticalMenu();
		simpleMenu.itemWidth = 500;
		simpleMenu.itemFontSize = 36;

		if (Assets.exists("mods/")) {
			var folders = Assets.readDirectory("mods/");
			trace(folders);
			for (folder in folders) {
				trace(folder);
				if (Assets.isDirectory("mods/" + folder) && !Flags.ignoredModFolders.contains(folder)) {
					simpleMenu.addEntry(folder, function() {
						GamePrefs.currentMod = folder;
						applySelection();
					});
				}
			}
		}

		simpleMenu.addEntry("system.mods.ui.disable", function() {
			GamePrefs.currentMod = "";
			applySelection();
		});

		simpleMenu.buildVisualList(60);
		simpleMenu.x = menuFrame.x + 50;
		simpleMenu.y = menuFrame.y + 130;
		add(simpleMenu);
	}

	function applySelection():Void {
		close();
		if (onSelect != null)
			onSelect();
		GamePrefs.saveSettings();
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		for (i in 0...simpleMenu.visualItems.length) {
			var entry = simpleMenu.entries[i];
			var vis = simpleMenu.visualItems[i];

			if (entry.caption == GamePrefs.currentMod && GamePrefs.currentMod != "") {
				vis.label.color = FlxColor.GREEN;
			} else {
				vis.label.color = FlxColor.WHITE;
			}
		}

		if (Controls.CANCEL) {
			FlxG.sound.play(Flags.CANCEL);
			close();
		}
	}
}
