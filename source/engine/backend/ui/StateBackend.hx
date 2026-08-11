package engine.backend.ui;

class StateBackend extends FlxState {
	var simpleMenu:SimpleVerticalMenu;

	/**
	 * SCRIPTING STUFF
	 */
	#if FEATURE_HSCRIPT
	public var scriptsAllowed:Bool = true;
	public var stateScripts:ScriptPack;

	public static var lastScriptName:String = null;
	public static var lastStateName:String = null;

	public var scriptName:String = null;

	public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
		super();
		if (lastStateName != (lastStateName = Type.getClassName(Type.getClass(this)))) {
			lastScriptName = null;
		}
		this.scriptName = scriptName != null ? scriptName : lastScriptName;
		lastScriptName = this.scriptName;
	}

	function loadScript(?customPath:String) {
		var className = Type.getClassName(Type.getClass(this));
		if (stateScripts == null)
			(stateScripts = new ScriptPack(className)).setParent(this);
		if (scriptsAllowed) {
			if (stateScripts.scripts.length == 0) {
				var scriptName = this.scriptName != null ? this.scriptName : className.substr(className.lastIndexOf(".") + 1);
				var filePath:String = "states/" + scriptName;
				if (customPath != null)
					filePath = customPath;

				var scriptPath = 'data/$filePath';
				var script = Script.create(scriptPath);
				if (script is DummyScript) {} else {
					script.remappedNames.set(script.fileName, '${script.fileName}');
					stateScripts.add(script);
					script.load();
					call('create');
				}
			}
		}
	}
	#else
	public function new() {
		super();
	}
	#end

	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic {
		#if FEATURE_HSCRIPT
		if (stateScripts != null)
			return stateScripts.call(name, args);
		#end
		return defaultVal;
	}

	public function event(name:String, event:CancellableEvent):CancellableEvent {
		#if FEATURE_HSCRIPT
		if (stateScripts != null)
			stateScripts.call(name, [event]);
		#end
		return event;
	}

	override function create() {
		#if FEATURE_HSCRIPT
		loadScript();
		#end
		super.create();
		#if FEATURE_HSCRIPT
		call("create");
		#end
	}

	override public function update(elapsed:Float) {
		#if FEATURE_HSCRIPT call("preUpdate", [elapsed]); #end
		super.update(elapsed);
		#if FEATURE_HSCRIPT call("update", [elapsed]); #end
		#if FEATURE_HSCRIPT call("postUpdate", [elapsed]); #end
	}

	override function destroy() {
		#if FEATURE_HSCRIPT
		call("destroy");
		stateScripts = FlxDestroyUtil.destroy(stateScripts);
		#end
		super.destroy();
	}

	override public function closeSubState() {
		if (simpleMenu != null)
			simpleMenu.canInput = true;
		super.closeSubState();
		#if FEATURE_HSCRIPT
		call('onCloseSubState');
		#end
		#if FEATURE_TOUCH_CONTROLS
		Main.mobileControls.resetAllInputs();
		#end
	}

	public function closeSubStatePost() {
		#if FEATURE_HSCRIPT
		call('onCloseSubStatePost');
		#end
	}

	/**
	 * Call this instead of FlxG.switchState()
	 */
	public static function switchState(nextState:FlxState, duration:Float = 0.2):Void {
		FlxG.camera.fade(FlxColor.BLACK, duration, false, function() {
			FlxG.switchState(nextState);
		});
	}

	override public function openSubState(SubState:FlxSubState):Void {
		if (simpleMenu != null)
			simpleMenu.canInput = false;
		super.openSubState(SubState);
	}

	override public function onFocus() {
		super.onFocus();
		#if FEATURE_HSCRIPT call("onFocus"); #end
	}

	override public function onFocusLost() {
		super.onFocusLost();
		#if FEATURE_HSCRIPT call("onFocusLost"); #end
	}
}
