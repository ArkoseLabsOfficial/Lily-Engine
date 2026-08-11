package engine.backend.ui;

class SubStateBackend extends FlxSubState {
	var simpleMenu:SimpleVerticalMenu; // Used for many menus.

	/**
	 * SCRIPTING STUFF
	 */
	#if FEATURE_HSCRIPT
	public var stateScripts:ScriptPack;
	public var scriptsAllowed:Bool = true;
	public var scriptName:String = null;

	public function new(scriptsAllowed:Bool = true, ?scriptName:String, bgColor:FlxColor = FlxColor.TRANSPARENT) {
		super(bgColor);
		this.scriptsAllowed = scriptsAllowed;
		this.scriptName = scriptName;
		#if FEATURE_TOUCH_CONTROLS
		Main.mobileControls.resetAllInputs();
		#end
	}

	function loadScript(?customPath:String) {
		var className = Type.getClassName(Type.getClass(this));
		if (stateScripts == null)
			(stateScripts = new ScriptPack(className)).setParent(this);
		if (scriptsAllowed) {
			if (stateScripts.scripts.length == 0) {
				var scriptName = this.scriptName != null ? this.scriptName : className.substr(className.lastIndexOf(".") + 1);
				var filePath:String = "scripts/substates/" + scriptName;
				if (customPath != null)
					filePath = customPath;

				var scriptPath = '$filePath.hx';
				var script = Script.create(scriptPath);
				if (script is DummyScript) {} else {
					script.remappedNames.set(script.fileName, '${script.fileName}');
					stateScripts.add(script);
					script.load();
					call('new');
				}
			}
		}
	}
	#else
	public function new(bgColor:FlxColor = FlxColor.TRANSPARENT) {
		super(bgColor);
		#if FEATURE_TOUCH_CONTROLS
		Main.mobileControls.resetAllInputs();
		#end
	}
	#end

	var camMenu:FlxCamera;

	override function create() {
		#if FEATURE_HSCRIPT
		loadScript();
		#end
		super.create();

		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;
		FlxG.cameras.add(camMenu, false);
		cameras = [camMenu];
		camMenu.zoom = 1;

		#if FEATURE_HSCRIPT
		call("create");
		#end
	}

	override function update(elapsed:Float) {
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

	override function close() {
		#if FEATURE_HSCRIPT
		var event = event("onClose", new CancellableEvent());
		if (!event.cancelled) {
			super.close();
			call("onClosePost");
		}
		#else
		super.close();
		#end
	}

	override public function openSubState(SubState:FlxSubState):Void {
		if (simpleMenu != null)
			simpleMenu.canInput = false;
		super.openSubState(SubState);
	}

	override public function closeSubState():Void {
		if (simpleMenu != null)
			simpleMenu.canInput = true;
		super.closeSubState();
	}

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

	override public function onFocus() {
		super.onFocus();
		#if FEATURE_HSCRIPT call("onFocus"); #end
	}

	override public function onFocusLost() {
		super.onFocusLost();
		#if FEATURE_HSCRIPT call("onFocusLost"); #end
	}
}
