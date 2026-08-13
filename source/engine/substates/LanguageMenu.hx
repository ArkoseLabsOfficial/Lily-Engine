package engine.substates;

import lang.Lang;
import lang.LangText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

class LanguageMenu extends SubStateBackend {
	public var frame:MenuFrameNode;
	public var onClose:Void->Void;

	var frameWidth:Float = 900;
	var baseFrameHeight:Float = 550;
	var optionGap:Float = 72;
	var headerOffset:Float = 180;

	public var languageMenu:SimpleLanguageMenu;

	public function new(?onClose:Void->Void) {
		super();
		this.onClose = onClose;
	}

	override public function create():Void {
		super.create();

		var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xB3000000);
		add(overlay);

		var langs = Lang.getAvailableLanguages();
		var contentHeight = langs.length * optionGap;

		var targetHeight = Math.min(contentHeight + headerOffset, baseFrameHeight);
		var viewHeight = targetHeight - headerOffset;

		var px = (FlxG.width - frameWidth) / 2;
		var py = (FlxG.height - targetHeight) / 2;

		frame = new MenuFrameNode(px, py, frameWidth, targetHeight, 2);
		frame.setTitle("system.settings.language.select");
		frame.divider = new FlxSprite(0, 0, Assets.getImage("ui/dividers/divider_md"));
		add(frame);

		var entryWidth = frameWidth - 108;
		var menuBaseY = Math.floor(frame.y + (targetHeight - viewHeight) / 2 + 15);

		languageMenu = new SimpleLanguageMenu(this);
		languageMenu.itemWidth = entryWidth;
		languageMenu.itemFontSize = 36;
		languageMenu.optionGap = optionGap;
		languageMenu.baseY = menuBaseY;
		languageMenu.viewHeight = viewHeight;
		languageMenu.x = Math.floor(frame.x + (frameWidth - entryWidth) / 2);
		languageMenu.y = menuBaseY;

		languageMenu.clipMask = new ClipMask(frame.x, menuBaseY, frameWidth, viewHeight);

		frame.addMenu(languageMenu);

		buildEntries(langs);

		new FlxTimer().start(0.1, function(_) {
			if (languageMenu != null)
				languageMenu.canInput = true;
		});
	}

	function buildEntries(langs:Array<String>):Void {
		if (languageMenu == null)
			return;

		languageMenu.entries = [];

		for (langItem in langs) {
			var language = langItem;
			var caption = language;

			var rawText:String = null;
			if (Assets.exists(Flags.languageFolder + language + ".json")) {
				rawText = Assets.getText(Flags.languageFolder + language + ".json");
			}

			if (rawText != null) {
				try {
					var parsed = haxe.Json.parse(rawText);
					if (parsed != null && parsed.name != null) {
						caption = parsed.name;
					}
				} catch (e:Dynamic) {
					FlxG.log.error("Failed to parse language json for: " + language);
				}
			}

			languageMenu.addEntry(caption, function() {
				Lang.setLanguage(language);
				closeMenu();
			});
		}

		languageMenu.buildVisualList(optionGap);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (languageMenu == null || !languageMenu.canInput)
			return;

		if (Controls.CANCEL) {
			FlxG.sound.play(Flags.CANCEL);
			closeMenu();
		}
	}

	public function closeMenu():Void {
		if (onClose != null)
			onClose();

		LangText.refreshAll();
		GamePrefs.saveSettings();
		close();
	}
}

class SimpleLanguageMenu extends SimpleVerticalMenu {
	public var optionGap:Float = 72;
	public var clipMask:ClipMask;
	public var baseY:Float = 0;
	public var viewHeight:Float = 0;
	public var scrollY:Float = 0;
	public var scrollLerp:Float = 0;
	public var parentState:LanguageMenu;

	public function new(parent:LanguageMenu) {
		super();
		this.parentState = parent;
		this.canInput = false;
	}

	override public function highlightSelection():Void {
		super.highlightSelection();

		if (viewHeight > 0) {
			var selectedY = selection * optionGap;
			if (selectedY < scrollY) {
				scrollY = selectedY;
			} else if (selectedY + optionGap > scrollY + viewHeight) {
				scrollY = selectedY + optionGap - viewHeight;
			}

			var maxScroll = Math.max(0, visualItems.length * optionGap - viewHeight);
			if (scrollY > maxScroll)
				scrollY = maxScroll;
			if (scrollY < 0)
				scrollY = 0;
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (viewHeight > 0 && baseY != 0) {
			scrollLerp += (scrollY - scrollLerp) * (elapsed * 10);
			this.y = baseY - scrollLerp;

			if (clipMask != null) {
				clipMask.apply(this);
			}
		}
	}
}
