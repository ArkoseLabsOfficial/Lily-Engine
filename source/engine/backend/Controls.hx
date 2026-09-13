package engine.backend;

class Controls {
	private static var _initializedSignals:Bool = false;
	private static var _lastActiveState:Dynamic = null;
	private static var _blockTimer:Int = 0;

	private static function getActiveState():Dynamic {
		if (FlxG.state == null)
			return null;
		var current:Dynamic = FlxG.state;
		while (Reflect.field(current, "subState") != null) {
			current = Reflect.field(current, "subState");
		}
		return current;
	}

	private static function initSignals() {
		if (_initializedSignals)
			return;
		_initializedSignals = true;

		FlxG.signals.preUpdate.add(function() {
			var currentState = getActiveState();
			if (_lastActiveState != currentState) {
				_lastActiveState = currentState;
				_blockTimer = 1;
			} else if (_blockTimer > 0) {
				_blockTimer--;
			}
		});
	}

	public static function checkAction(action:String, status:String):Bool {
		initSignals();

		if (_blockTimer > 0) {
			return false;
		}

		var baseResult = checkKeyboardAndGamepad(action, status);
		var mobilePressed = false;

		#if FEATURE_TOUCH_CONTROLS
		if (Game.mobileC != null) {
			var btnName = action.toUpperCase();
			mobilePressed = Game.mobileC.checkState(btnName, status);
		}
		#end

		return baseResult || mobilePressed;
	}

	private inline static function checkKeyboardAndGamepad(action:String, status:String):Bool {
		var binds:Array<String> = GamePrefs.keybinds.get(action);
		if (binds == null || binds.length < 2)
			return false;

		var kbKey:FlxKey = FlxKey.fromString(binds[0]);
		var gpBtn:FlxGamepadInputID = FlxGamepadInputID.fromString(binds[1]);

		var kbMatched:Bool = false;
		if (kbKey != FlxKey.NONE) {
            switch (status) {
                case "justPressed":
                    kbMatched = FlxG.keys.anyJustPressed([kbKey]);
                case "pressed":
                    kbMatched = FlxG.keys.anyPressed([kbKey]);
                case "justReleased":
                    kbMatched = FlxG.keys.anyJustReleased([kbKey]);
                case "released":
                    kbMatched = FlxG.keys.checkStatus(kbKey, RELEASED);
            }
        }

		var gpMatched:Bool = false;
        if (gpBtn != FlxGamepadInputID.NONE) {
            var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
            if (gamepad != null) {
                switch (status) {
                    case "justPressed":
                        gpMatched = gamepad.anyJustPressed([gpBtn]);
                    case "pressed":
                        gpMatched = gamepad.anyPressed([gpBtn]);
                    case "justReleased":
                        gpMatched = gamepad.anyJustReleased([gpBtn]);
                    case "released":
                        gpMatched = gamepad.checkStatus(gpBtn, RELEASED);
                }
            }
        }

        return kbMatched || gpMatched;
	}

	public static var UP_P(get, never):Bool;

	inline static function get_UP_P()
		return checkAction("UP", "justPressed");

	public static var DOWN_P(get, never):Bool;

	inline static function get_DOWN_P()
		return checkAction("DOWN", "justPressed");

	public static var LEFT_P(get, never):Bool;

	inline static function get_LEFT_P()
		return checkAction("LEFT", "justPressed");

	public static var RIGHT_P(get, never):Bool;

	inline static function get_RIGHT_P()
		return checkAction("RIGHT", "justPressed");

	public static var ACCEPT(get, never):Bool;

	inline static function get_ACCEPT()
		return checkAction("ACCEPT", "justPressed");

	public static var BACK(get, never):Bool;

	inline static function get_BACK()
		return checkAction("BACK", "justPressed");

	public static var RUN_P(get, never):Bool;

	inline static function get_RUN_P()
		return checkAction("RUN", "justPressed");

	public static var MENU_P(get, never):Bool;

	inline static function get_MENU_P()
		return checkAction("MENU", "justPressed");

	public static var UP(get, never):Bool;

	inline static function get_UP()
		return checkAction("UP", "pressed");

	public static var DOWN(get, never):Bool;

	inline static function get_DOWN()
		return checkAction("DOWN", "pressed");

	public static var LEFT(get, never):Bool;

	inline static function get_LEFT()
		return checkAction("LEFT", "pressed");

	public static var RIGHT(get, never):Bool;

	inline static function get_RIGHT()
		return checkAction("RIGHT", "pressed");

	public static var RUN(get, never):Bool;

	inline static function get_RUN()
		return checkAction("RUN", "pressed");

	public static var MENU(get, never):Bool;

	inline static function get_MENU()
		return checkAction("MENU", "pressed");
}
