package engine.substates;

#if FEATURE_HSCRIPT
import engine.scripting.HScript;
#end
import lang.LangText;
import lang.Lang;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxTimer;
import haxe.xml.Access;

typedef XmlOption = {
	var label:String;
	var type:String;
	@:optional var target:String;
	@:optional var variable:String;
	@:optional var values:Array<String>;
	@:optional var defaultValue:Dynamic;
	@:optional var keyPath:String;
	@:optional var min:Float;
	@:optional var max:Float;
	@:optional var step:Float;
	@:optional var scrollSpeed:Float;
	@:optional var onChanged:Dynamic->Void;
	@:optional var onClicked:Void->Void;
	@:optional var curArrayIdx:Int;
}

class SettingsMenu extends SubStateBackend {
	public var uiScale:Float = 1.0;
	public var optionGap:Float = 80;
	public var fromPause:Bool = false;

	public var menuFrame:MenuFrameNode;
	public var settingsMenu:SimpleSettingsMenu;

	public var options:Array<XmlOption> = [];
	public var currentMenuId:String;

	public var xmlMenuWidth:Null<Float> = null;
	public var xmlMenuHeight:Null<Float> = null;

	public var canInput:Bool = false;

	public function new(menuId:String = "main", fromPause:Bool = false) {
		super(0x99000000);
		currentMenuId = menuId;
		this.fromPause = fromPause;
	}

	override public function create():Void {
		super.create();

		if (fromPause)
			camMenu.scroll.set(-230, 40);

		parseXML(currentMenuId);

		var textScale = 1.0;
		var frameScale = fromPause ? 1.3 : 1.0;

		var useTitle = currentMenuId != "main";

		optionGap *= textScale;
		var numItems = options.length;
		if (useTitle) {
			numItems += 1;
		}

		var contentHeight = numItems * optionGap;

		var targetWidth = fromPause ? 1452.0 : (xmlMenuWidth != null ? xmlMenuWidth * frameScale : (600.0 * frameScale));
		var targetHeight = fromPause ? 985.0 : (xmlMenuHeight != null ? xmlMenuHeight * frameScale : Math.min(contentHeight, 550.0 * frameScale)
			+ ((useTitle ? 180.0 : 120.0) * frameScale));
		var viewHeight = targetHeight - ((useTitle ? 180.0 : 120.0) * frameScale);

		var entryWidth = targetWidth * 0.85;

		menuFrame = new MenuFrameNode(0, 0, targetWidth, targetHeight, useTitle ? 2 : 0);

		menuFrame.screenCenter();
		menuFrame.x = Math.floor(menuFrame.x);
		menuFrame.y = Math.floor(menuFrame.y);

		if (fromPause)
			menuFrame.y += 2;

		if (useTitle) {
			menuFrame.setTitle(options[0] != null ? "system.settings.ui." + currentMenuId : "Settings");
		}

		add(menuFrame);

		settingsMenu = new SimpleSettingsMenu(this);
		settingsMenu.buildOptions(options, entryWidth, textScale, optionGap, currentMenuId);

		menuFrame.addMenu(settingsMenu);

		var menuBaseY = Math.floor(menuFrame.y + (targetHeight - viewHeight) / 2);

		if (useTitle) {
			menuBaseY += Math.floor(35 * frameScale);
		}

		settingsMenu.baseY = menuBaseY;
		settingsMenu.viewHeight = viewHeight;

		settingsMenu.x = Math.floor(menuFrame.x + (targetWidth - entryWidth) / 2);
		settingsMenu.y = menuBaseY;

		settingsMenu.clipMask = new ClipMask(menuFrame.x, menuBaseY, targetWidth, viewHeight);

		new FlxTimer().start(0.1, function(_) {
			canInput = true;
		});
	}

	override public function openSubState(SubState:FlxSubState):Void {
		canInput = false;
		super.openSubState(SubState);
	}

	override public function closeSubState():Void {
		canInput = true;
		super.closeSubState();
	}

	override public function update(elapsed:Float):Void {
		if (settingsMenu != null) {
			settingsMenu.canInput = this.canInput;
		}
		super.update(elapsed);
	}

	public function adjustOption(opt:XmlOption, dir:Int, ?visualItem:SettingsVisualEntry):Void {
		var curVal:Dynamic = getData(opt.variable);
		switch (opt.type) {
			case "bool":
				saveData(opt.variable, !(curVal == true));
			case "array":
				opt.curArrayIdx += dir;
				if (opt.curArrayIdx < 0)
					opt.curArrayIdx = opt.values.length - 1;
				if (opt.curArrayIdx >= opt.values.length)
					opt.curArrayIdx = 0;
				saveData(opt.variable, opt.values[opt.curArrayIdx]);
			case "int", "float", "percent":
				var numVal:Float = Std.parseFloat(Std.string(curVal));

				var minVal:Float = opt.min != null ? opt.min : 0;
				var maxVal:Float = opt.max != null ? opt.max : 100;
				var stepVal:Float = opt.step != null ? opt.step : (opt.type == "float" ? 0.1 : 1);

				if (Math.isNaN(numVal))
					numVal = minVal;

				numVal += (stepVal * dir);

				if (numVal < minVal)
					numVal = minVal;
				if (numVal > maxVal)
					numVal = maxVal;

				if (opt.type != "int")
					numVal = Math.round(numVal * 100) / 100;

				saveData(opt.variable, opt.type == "int" ? Std.int(numVal) : numVal);
		}

		var newVal = getData(opt.variable);
		if (opt.onChanged != null)
			opt.onChanged(newVal);
	}

	public function saveData(variable:String, value:Dynamic):Void {
		if (variable == null || variable == "")
			return;
		GamePrefs.setOption(variable, value);
	}

	public function getData(variable:String):Dynamic {
		if (variable == null || variable == "")
			return null;
		return GamePrefs.getOption(variable);
	}

	public function ensureDefaultData(opt:XmlOption):Void {
		if (opt.type == "keybind")
			return;

		if (getData(opt.variable) == null) {
			var defVal:Dynamic = opt.defaultValue;
			switch (opt.type) {
				case "bool":
					var boolVal = defVal != null ? (defVal == "true" || defVal == true) : false;
					saveData(opt.variable, boolVal);
				case "array":
					var strVal = defVal != null ? Std.string(defVal) : (opt.values != null ? opt.values[0] : "");
					saveData(opt.variable, strVal);
					opt.curArrayIdx = opt.values != null ? opt.values.indexOf(strVal) : 0;
					if (opt.curArrayIdx == -1)
						opt.curArrayIdx = 0;
				case "int":
					var intVal = defVal != null ? Std.parseInt(Std.string(defVal)) : (opt.min != null ? Std.int(opt.min) : 0);
					saveData(opt.variable, intVal);
				case "float", "percent":
					var floatVal = defVal != null ? Std.parseFloat(Std.string(defVal)) : (opt.min != null ? opt.min : 0);
					saveData(opt.variable, floatVal);
			}
		} else {
			if (opt.type == "array" && opt.values != null) {
				opt.curArrayIdx = opt.values.indexOf(Std.string(getData(opt.variable)));
				if (opt.curArrayIdx == -1)
					opt.curArrayIdx = 0;
			}
		}
	}

	function parseXML(menuId:String):Void {
		var xmlString = Assets.getText(Flags.settingsFile);
		var xml = new Access(Xml.parse(xmlString).firstElement());
		for (menuNode in xml.nodes.menu) {
			if (menuNode.att.id == menuId) {
				if (menuNode.has.width)
					xmlMenuWidth = Std.parseFloat(menuNode.att.width);
				if (menuNode.has.height)
					xmlMenuHeight = Std.parseFloat(menuNode.att.height);

				if (menuId == "main") {
					for (cat in menuNode.nodes.category) {
						if (cat.att.label == "system.settings.ui.language" && fromPause)
							continue;
						options.push({label: cat.att.label, target: cat.att.target, type: "category"});
					}
				} else {
					for (opt in menuNode.nodes.option) {
						var newOpt:XmlOption = {
							label: opt.att.label,
							type: opt.att.type,
							variable: opt.has.variable ? opt.att.variable : ""
						};

						if (opt.has.resolve("default"))
							newOpt.defaultValue = opt.att.resolve("default");
						if (opt.has.values)
							newOpt.values = opt.att.values.split(",");
						if (opt.has.min)
							newOpt.min = Std.parseFloat(opt.att.min);
						if (opt.has.max)
							newOpt.max = Std.parseFloat(opt.att.max);
						if (opt.has.step)
							newOpt.step = Std.parseFloat(opt.att.step);
						if (opt.has.scrollSpeed)
							newOpt.scrollSpeed = Std.parseFloat(opt.att.scrollSpeed);
						if (newOpt.type == "keybind" && newOpt.variable != "") {
							if (opt.has.keyPath)
								newOpt.keyPath = opt.att.keyPath;
						}

						var scriptCode = "";
						for (node in opt.x.iterator()) {
							if (node.nodeType == Xml.PCData || node.nodeType == Xml.CData) {
								scriptCode += node.nodeValue;
							}
						}

						scriptCode = StringTools.trim(scriptCode);

						if (scriptCode != "") {
							var runner = function(?val:Dynamic) {
								#if FEATURE_HSCRIPT
								var sName = (newOpt.variable != "" ? newOpt.variable : "option") + "_script.hx";
								var script = new HScript(sName);
								script.loadFromString(scriptCode);
								script.set("value", val);
								script.load();
								#else
								FlxG.log.warn("HScript is not enabled! Script for " + newOpt.label + " won't run.");
								#end
							};

							if (newOpt.type == "button") {
								newOpt.onClicked = function() runner();
							} else {
								newOpt.onChanged = function(v) runner(v);
							}
						}

						options.push(newOpt);
					}
				}
				break;
			}
		}
	}
}

class SimpleSettingsMenu extends SimpleVerticalMenu {
	public var options:Array<XmlOption> = [];
	public var uiScale:Float = 1.0;
	public var optionGap:Float = 72;
	public var currentMenuId:String = "main";
	public var isListening:Bool = false;
	public var parentState:SettingsMenu;

	public var typedVisualItems:Array<SettingsVisualEntry> = [];
	public var clipMask:ClipMask;

	public var baseY:Float = 0;
	public var viewHeight:Float = 0;
	public var scrollY:Float = 0;
	public var scrollLerp:Float = 0;

	private var holdTime:Float = 0;
	private var holdDir:Int = 0;
	private var currentScrollTimer:Float = 0;

	public function new(parent:SettingsMenu) {
		super();
		this.parentState = parent;
	}

	public function buildOptions(opts:Array<XmlOption>, entryWidth:Float, scale:Float, gap:Float, menuId:String):Void {
		this.options = opts;
		this.uiScale = scale;
		this.optionGap = gap;
		this.itemWidth = entryWidth;
		this.currentMenuId = menuId;

		clearItems();
		typedVisualItems = [];

		for (i in 0...options.length) {
			var opt = options[i];
			var entry = new SettingsVisualEntry(0, i * optionGap, opt, entryWidth, optionGap, uiScale);

			typedVisualItems.push(entry);
			visualItems.push(entry);
			add(entry);

			if (currentMenuId != "main" && opt.type != "category" && opt.type != "button") {
				parentState.ensureDefaultData(opt);
			}
		}

		if (currentMenuId != "main") {
			var backOpt:XmlOption = {label: "system.settings.ui.back", type: "button", variable: ""};
			var backEntry = new SettingsVisualEntry(0, options.length * optionGap, backOpt, entryWidth, optionGap, uiScale);
			typedVisualItems.push(backEntry);
			visualItems.push(backEntry);
			add(backEntry);
		}

		highlightSelection();
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

			var maxScroll = Math.max(0, typedVisualItems.length * optionGap - viewHeight);
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

	override public function getListLength():Int {
		return typedVisualItems.length;
	}

	override public function handleInput():Void {
		if (isListening) {
			handleKeybindListening();
			return;
		}

		super.handleInput();

		if (selection < options.length && currentMenuId != "main") {
			var opt = options[selection];

			var leftP = Controls.LEFT_P;
			var rightP = Controls.RIGHT_P;
			var left = Controls.LEFT;
			var right = Controls.RIGHT;

			var speedScrollDelay = 0.4;

			if (leftP || rightP) {
				holdDir = leftP ? -1 : 1;
				holdTime = 0;
				currentScrollTimer = 0;
				parentState.adjustOption(opt, holdDir, typedVisualItems[selection]);
				FlxG.sound.play(Flags.NAVIGATE);
			} else if ((left && holdDir == -1) || (right && holdDir == 1)) {
				if (opt.type == "int" || opt.type == "float" || opt.type == "percent") {
					holdTime += flixel.FlxG.elapsed;
					if (holdTime > speedScrollDelay) {
						var speed = opt.scrollSpeed != null ? opt.scrollSpeed : 0.05;
						currentScrollTimer += flixel.FlxG.elapsed;
						while (currentScrollTimer >= speed) {
							currentScrollTimer -= speed;
							parentState.adjustOption(opt, holdDir, typedVisualItems[selection]);
						}
					}
				}
			} else {
				holdDir = 0;
				holdTime = 0;
			}
		}

		if (Controls.CANCEL) {
			FlxG.sound.play(Flags.CANCEL);
			parentState.close();
			GamePrefs.saveSettings();
		}
	}

	override public function acceptSelection():Void {
		if (selection == options.length) {
			GamePrefs.saveSettings();
			parentState.close();
			return;
		}

		var opt = options[selection];
		if (opt.onClicked != null)
			opt.onClicked();

		if (currentMenuId == "main") {
			FlxG.sound.play(Flags.CONFIRM);
			if (opt.target == "language")
				parentState.openSubState(new LanguageMenu());
			else
				parentState.openSubState(new SettingsMenu(opt.target, parentState.fromPause));
		} else {
			if (opt.type == "bool") {
				FlxG.sound.play(Flags.CONFIRM);
				parentState.adjustOption(opt, 1, typedVisualItems[selection]);
			}
			if (opt.type == "keybind") {
				FlxG.sound.play(Flags.CONFIRM);
				isListening = true;
				typedVisualItems[selection].setListeningState();
			}
		}
	}

	function handleKeybindListening():Void {
		var opt = options[selection];
		var bindHandled:Bool = false;
		var kbKey:FlxKey = FlxG.keys.firstJustPressed();

		if (kbKey != FlxKey.NONE) {
			if (kbKey == FlxKey.ESCAPE) {
				bindHandled = true;
			} else if (kbKey == FlxKey.BACKSPACE || kbKey == FlxKey.DELETE) {
				GamePrefs.keybinds.get(opt.variable)[0] = "NONE";
				bindHandled = true;
			} else {
				GamePrefs.keybinds.get(opt.variable)[0] = kbKey.toString();
				bindHandled = true;
			}
		} else if (FlxG.gamepads.lastActive != null) {
			var gpBtn = FlxG.gamepads.lastActive.firstJustPressedID();
			if (gpBtn != FlxGamepadInputID.NONE) {
				if (gpBtn == FlxGamepadInputID.BACK) {
					GamePrefs.keybinds.get(opt.variable)[1] = "NONE";
					bindHandled = true;
				} else {
					GamePrefs.keybinds.get(opt.variable)[1] = gpBtn.toString();
					bindHandled = true;
				}
			}
		}

		if (bindHandled) {
			GamePrefs.saveSettings();
			if (opt.onChanged != null)
				opt.onChanged(GamePrefs.keybinds.get(opt.variable));
			typedVisualItems[selection].resetListeningState();
			isListening = false;
			highlightSelection();
		}
	}
}

class SettingsVisualEntry extends MenuVisualEntry {
	public var valueText:FlxText;
	public var optionLabel:LangText;
	public var optData:XmlOption;
	public var keySprites:Array<FlxSprite>;
	public var isListening:Bool = false;

	public var internalScale:Float;
	public var entryWidth:Float;
	public var entryHeight:Float;

	public function new(X:Float, Y:Float, opt:XmlOption, width:Float, height:Float, scale:Float) {
		super(Math.floor(X), Math.floor(Y), "", width, height);

		this.optData = opt;
		this.internalScale = scale;
		this.entryWidth = width;
		this.entryHeight = height;

		var ts = Std.int(28 * scale);

		optionLabel = new LangText(0, 0, 0, opt.label, null, ts);

		add(optionLabel);

		valueText = new FlxText(0, 0, 0, "needed for fixing text issue lol", ts); // text basically fixes the font issue idk why lmao.
		add(valueText);

		if (opt.type == "keybind" && opt.keyPath != null) {
			keySprites = [new FlxSprite(0, 0), new FlxSprite(0, 0)];
			add(keySprites[0]);
			add(keySprites[1]);
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (optData.type != "button" && optData.type != "category") {
			var curVal:Dynamic = GamePrefs.getOption(optData.variable);
			if (curVal == null)
				curVal = optData.defaultValue;

			switch (optData.type) {
				case "bool":
					valueText.text = (curVal == true) ? "< ON >" : "< OFF >";
				case "array", "int", "float":
					valueText.text = "< " + Std.string(curVal) + " >";
				case "percent":
					valueText.text = "< " + Std.string(curVal) + "% >";
				case "keybind":
					if (isListening) {
						valueText.text = Lang.get("system.settings.ui.waiting");
					} else {
						var binds:Array<String> = GamePrefs.keybinds.get(optData.variable);
						if (binds != null) {
							var kbStr = binds[0];
							var gpStr = binds[1];
							var displayText = "";

							if (optData.keyPath != null) {
								var kbImgPath = getInputImagePath(kbStr, false, optData.keyPath);
								var gpImgPath = getInputImagePath(gpStr, true, optData.keyPath);

								if (kbImgPath != "" && Assets.exists(kbImgPath)) {
									keySprites[0].loadGraphic(kbImgPath);
									keySprites[0].scale.set(0.5 * internalScale, 0.5 * internalScale);
									keySprites[0].updateHitbox();
									keySprites[0].visible = true;
									displayText += "[ IMG ]";
								} else {
									keySprites[0].visible = false;
									displayText += "[ " + kbStr + " ]";
								}

								displayText += " / ";

								if (gpImgPath != "" && Assets.exists(gpImgPath)) {
									keySprites[1].loadGraphic(gpImgPath);
									keySprites[1].scale.set(0.5 * internalScale, 0.5 * internalScale);
									keySprites[1].updateHitbox();
									keySprites[1].visible = true;
									displayText += "[ IMG ]";
								} else {
									keySprites[1].visible = false;
									displayText += "[ " + gpStr + " ]";
								}
								valueText.text = StringTools.replace(displayText, "[ IMG ]", "      ");
							} else {
								valueText.text = "[ " + kbStr + " ] / [ " + gpStr + " ]";
							}
						}
					}
			}
		}

		if (optData.type == "category" || optData.type == "button") {
			optionLabel.x = this.x + (entryWidth - optionLabel.width) / 2;
			valueText.visible = false;
		} else {
			optionLabel.x = this.x + 15 * internalScale;
		}
		optionLabel.y = this.y + (entryHeight - optionLabel.height) / 2;

		valueText.x = this.x + entryWidth - valueText.width - (15 * internalScale);
		valueText.y = this.y + (entryHeight - valueText.height) / 2;

		if (keySprites != null && optData.type == "keybind" && optData.keyPath != null && !isListening) {
			if (keySprites[0].visible) {
				keySprites[0].x = valueText.x - (5 * internalScale);
				keySprites[0].y = valueText.y + (valueText.height / 2) - (keySprites[0].height / 2);
			}
			if (keySprites[1].visible) {
				keySprites[1].x = valueText.x + (80 * internalScale);
				keySprites[1].y = valueText.y + (valueText.height / 2) - (keySprites[1].height / 2);
			}
		}
	}

	public function setListeningState():Void {
		isListening = true;
		valueText.text = Lang.get("system.settings.ui.waiting");
		bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), 0x77FFD700);
		if (keySprites != null) {
			keySprites[0].visible = false;
			keySprites[1].visible = false;
		}
	}

	public function resetListeningState():Void {
		isListening = false;
	}

	private function getInputImagePath(inputStr:String, isGamepad:Bool, basePath:String):String {
		if (inputStr == null || inputStr == "NONE" || inputStr == "")
			return "";
		var fileName:String = "";
		var raw = inputStr.toUpperCase();
		if (!isGamepad) {
			if (raw.length == 1 && raw.charCodeAt(0) >= 65 && raw.charCodeAt(0) <= 90) {
				fileName = "keyboard_letter_" + raw.toLowerCase();
			} else {
				fileName = switch (raw) {
					case "ZERO", "NUMPADZERO": "keyboard_number_0";
					case "ONE", "NUMPADONE": "keyboard_number_1";
					case "TWO", "NUMPADTWO": "keyboard_number_2";
					case "THREE", "NUMPADTHREE": "keyboard_number_3";
					case "FOUR", "NUMPADFOUR": "keyboard_number_4";
					case "FIVE", "NUMPADFIVE": "keyboard_number_5";
					case "SIX", "NUMPADSIX": "keyboard_number_6";
					case "SEVEN", "NUMPADSEVEN": "keyboard_number_7";
					case "EIGHT", "NUMPADEIGHT": "keyboard_number_8";
					case "NINE", "NUMPADNINE": "keyboard_number_9";
					case "MINUS": "keyboard_minus";
					case "PLUS": "keyboard_plus";
					case "SLASH": "keyboard_slash";
					case "SPACE": "keyboard_space";
					case "TAB": "keyboard_tab";
					case "SHIFT": "keyboard_shift";
					case "PAGEUP": "keyboard_page_up";
					case "PAGEDOWN": "keyboard_page_down";
					case "SEMICOLON": "keyboard_semicolon";
					case "QUOTE": "keyboard_quotes";
					case "PERIOD": "keyboard_period";
					default: "keyboard_" + raw.toLowerCase();
				}
			}
		} else {
			var prefix = "xbone_";
			fileName = switch (raw) {
				case "A", "B", "X", "Y": prefix + raw.toLowerCase();
				case "DPAD_UP": prefix + "dpad_up";
				case "DPAD_DOWN": prefix + "dpad_down";
				case "DPAD_LEFT": prefix + "dpad_left";
				case "DPAD_RIGHT": prefix + "dpad_right";
				case "LEFT_SHOULDER": prefix + "lb";
				case "RIGHT_SHOULDER": prefix + "rb";
				case "LEFT_TRIGGER": prefix + "lt";
				case "RIGHT_TRIGGER": prefix + "rt";
				case "LEFT_STICK_CLICK": prefix + "ls";
				case "RIGHT_STICK_CLICK": prefix + "rs";
				case "BACK": prefix + "view";
				case "START": prefix + "menu";
				default: prefix + raw.toLowerCase();
			}
		}
		return basePath + fileName + ".png";
	}
}
