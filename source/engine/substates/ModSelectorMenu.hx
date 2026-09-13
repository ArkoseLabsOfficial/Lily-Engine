package engine.substates;

class ModSelectorMenu extends SubStateBackend {
	var onSelect:Void->Void;

	public function new(onSelect:Void->Void) {
		super(0xBB000000);
		this.onSelect = onSelect;
	}

	override public function create():Void {
		super.create();

		menu = new NineNode(0, 0, {
			texture: 'ui/new/border',
			bgTexture: 'ui/frames/frame_default_bg',

			scaleFactor: 3,
			width: 900,
			heightOffset: 36,

			margin: {
				left: 10,
				top: 10,
				right: 10,
				bottom: 10
			},

			itemWidth: 792,
			itemHeight: 62,
			itemFontSize: 36,
			itemSeparation: 62,
			itemAlignment: CENTER,
			listAlignment: "center",
			maxBeforeScroll: 8,

			title: "system.mods.ui.title",
		});
		add(menu);		

		if (Assets.exists("mods/")) {
			var folders = Assets.readDirectory("mods/");
			trace(folders);
			for (folder in folders) {
				trace(folder);
				if (Assets.isDirectory("mods/" + folder) && !Flags.ignoredModFolders.contains(folder)) {
					menu.addEntry(folder, function() {
						GamePrefs.currentMod = folder;
						applySelection();
					});
				}
			}
		}

		menu.addEntry("system.mods.ui.disable", function() {
			GamePrefs.currentMod = "";
			applySelection();
		});

		menu.buildVisualList();
		for (i in 0...menu.entries.length) {
            var visualGroup = menu.visualItems[i];
            var labelText:LangText = cast visualGroup.members[1];
			if (labelText.text == GamePrefs.currentMod) {
				labelText.color = FlxColor.GREEN;
			}
		}
		menu.screenCenter();
		menu.y += 50;
		add(menu);
	}

	function applySelection():Void {
		close();
		if (onSelect != null)
			onSelect();
		GamePrefs.saveSettings();
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (Controls.BACK) {
			FlxG.sound.play(Flags.CANCEL);
			close();
		}
	}
}
