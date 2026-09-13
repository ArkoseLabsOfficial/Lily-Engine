package engine.substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import engine.ui.NineNode;
import lang.Lang;
import lang.LangText;

class LanguageMenu extends SubStateBackend {
	public var onClose:Void->Void;
	public var languageMenu:NineNode;
	public var canInput:Bool = false;

	public function new(?onClose:Void->Void) {
		super();
		this.onClose = onClose;
	}

	override public function create():Void {
		super.create();

		var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xB3000000);
		add(overlay);

		var langs = Lang.getAvailableLanguages();
		var frameWidth:Float = 900;
		var optionGap:Float = 72;

		var data:NineNodeMenuData = {
			width: frameWidth,
			heightOffset: 36,
			texture: 'ui/frames/frame_menu_2',
			bgTexture: 'ui/frames/frame_menu_bg',
			margin: {
				left: 50,
				top: 50,
				right: 50,
				bottom: 50
			},
			scaleFactor: 0.75,
			title: "system.settings.language.select",
			titleTexture: "ui/dividers/divider_md",
			itemWidth: frameWidth - 108,
			itemHeight: optionGap - 10,
			itemFontSize: 36,
			itemSeparation: optionGap,
			itemAlignment: CENTER,
			listAlignment: "center",
			maxBeforeScroll: 3,
			itemFont: Lang.get("fonts.NotoSansName")
		};

		languageMenu = new NineNode(0, 0, data);
		languageMenu.canInput = false;

		buildEntries(langs);

		languageMenu.screenCenter();
		add(languageMenu);

		new FlxTimer().start(0.1, function(_) {
			canInput = true;
			if (languageMenu != null)
				languageMenu.canInput = true;
		});
	}

	function buildEntries(langs:Array<String>):Void {
		var entryFonts:Array<String> = [];
		for (langItem in langs) {
			var caption = Lang.getSpecific("name", langItem);
			var fontToUse = Lang.getSpecific("fonts.NotoSans", langItem);
			entryFonts.push(fontToUse);

			languageMenu.addEntry(caption, function() {
				Lang.setLanguage(langItem);

				closeMenu();
			});
		}

		languageMenu.buildVisualList();

		for (i in 0...languageMenu.visualItems.length) {
			var rowGroup = languageMenu.visualItems[i];
			var label = Std.downcast(rowGroup.members[1], LangText);
			label.font = '${Flags.fontFolder}/${entryFonts[i]}';
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (languageMenu != null) {
			languageMenu.canInput = this.canInput;
		}

		if (!canInput || languageMenu == null)
			return;

		if (Controls.BACK) {
			FlxG.sound.play(Flags.CANCEL);
			closeMenu();
		}
	}

	public function closeMenu():Void {
		if (onClose != null)
			onClose();

		GamePrefs.saveSettings();
		Flags.fonts.set("NotoSans", '${Flags.fontFolder}/${Lang.get('fonts.NotoSans')}');
		Flags.fonts.set("AlegreyaSC", '${Flags.fontFolder}/${Lang.get('fonts.AlegreyaSC')}');
		FlxAssets.FONT_DEFAULT = Flags.fonts.get("NotoSans");
		LangText.refreshAll();
		LangSprite.refreshAll();
		close();
	}
}
