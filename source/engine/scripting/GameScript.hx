package engine.scripting;

#if FEATURE_HXSCRIPT
import hxscript.Environment;
import hxscript.Module;
import hxscript.types.ScriptedClass;
import hxscript.types.IScriptedType;
import openfl.utils.Assets;

/**
 * A class that applies some patches to script files to make hxScript usage easier and similar to LilyScript.
 * This class never used and not gonna be used.
 * @:Author: Gemini
 **/
@:access(hxscript.Module)
class GameScript {
	public var env(default, null):Environment;
	public var mainModule(default, null):Module;
	public var defaultClassName(default, null):String;

	private var instances:Map<String, Dynamic> = new Map();
	private var evalUid:Int = 0;

	private static var sharedEnv:Environment = null;
	private static var sharedLoadedFiles:Map<String, Bool> = new Map();
	private static var sharedModulesByPath:Map<String, Module> = new Map();
	private static var pendingModules:Array<Module> = [];

	public function new(entryPath:String) {
		var fileName = entryPath.split("/").pop();
		defaultClassName = fileName.split(".")[0];

		env = getSharedEnv();
		mainModule = loadSharedModules(entryPath);

		shareClassNames();

		startPendingModules();

		shareClassNames();
		bindScriptContext();
	}

	private static function getSharedEnv():Environment {
		if (sharedEnv == null) {
			sharedEnv = new Environment();
		}
		return sharedEnv;
	}

	private static function loadSharedModules(path:String):Module {
		var filePath = findAssetPath(path);

		if (sharedLoadedFiles.exists(filePath)) {
			return sharedModulesByPath.get(filePath);
		}

		sharedLoadedFiles.set(filePath, true);

		var content = Assets.getText(filePath);
		if (content == null) {
			throw 'Failed to load script asset: $filePath';
		}

		// Compatibility patch:
		// `some.script = this;` usually wants the GameScript wrapper on the Haxe side,
		// not the raw scripted instance.
		var scriptThisEreg = ~/([A-Za-z0-9_.]+\.script)\s*=\s*this\s*;/g;
		content = scriptThisEreg.replace(content, "$1 = script;");

		var ereg = ~/importScript\s*\(\s*["']([^"']+)["']\s*\)\s*;/g;
		var codeBuffer = new StringBuf();
		var currentPos = 0;

		while (ereg.matchSub(content, currentPos)) {
			var match = ereg.matched(1);
			var matchPos = ereg.matchedPos();

			codeBuffer.addSub(content, currentPos, matchPos.pos - currentPos);

			// Imported scripts are loaded into the same shared Environment.
			loadSharedModules(match);

			currentPos = matchPos.pos + matchPos.len;
		}

		codeBuffer.addSub(content, currentPos, content.length - currentPos);

		var cleanCode = codeBuffer.toString();
		var moduleName = makeModuleName(filePath);

		var module = new Module(cleanCode, moduleName, [], filePath);

		sharedModulesByPath.set(filePath, module);

		var e = getSharedEnv();
		e.addModule(module);
		pendingModules.push(module);

		return module;
	}

	private static function makeModuleName(filePath:String):String {
		var safe = filePath.split("/")
			.join("_")
			.split("\\")
			.join("_")
			.split(":")
			.join("_")
			.split(".")
			.join("_");

		return "GameScriptModule_" + safe;
	}

	private static function findAssetPath(path:String):String {
		if (Assets.exists(path))
			return path;
		throw 'OpenFL Asset not found for script: $path';
	}

	private function shareClassNames():Void {
		// Makes classes reachable by short class name across modules, ignoring package.
		for (module in env.modules) {
			injectSharedImports(module);
		}

		// Also add to env.variables
		for (other in env.modules) {
			for (type in other.types) {
				if (!env.variables.exists(type.name)) {
					env.variables.set(type.name, type);
				}
			}
		}
	}

	private function injectSharedImports(module:Module):Void {
		if (module.interp == null)
			return;
		for (other in env.modules) {
			for (type in other.types) {
				module.interp.imports.set(type.name, type);
				if (!module.variables.exists(type.name)) {
					module.variables.set(type.name, type);
				}
			}
		}
	}

	private function startPendingModules():Void {
		if (pendingModules.length == 0)
			return;

		var toStart = pendingModules.copy();
		pendingModules.resize(0);

		for (module in toStart) {
			if (!module.started) {
				module.init(env);
				// Re-inject shared class names after init() clears them
				injectSharedImports(module);
				module.start(env);
			}

			module.startTypes(env);
		}

		fireEnvironmentInitialized();
	}

	private function fireEnvironmentInitialized():Void {
		var allTypes:Map<String, IScriptedType> = [];

		for (module in env.modules) {
			for (n in module.types.keys()) {
				allTypes.set(n, module.types.get(n));
			}
		}

		var i:Int = env.onInitialized.length;
		while (--i >= 0) {
			if (!env.onInitialized[i](allTypes)) {
				env.onInitialized.remove(env.onInitialized[i]);
			}
		}
	}

	private function bindScriptContext():Void {
		if (env == null)
			return;

		env.variables.set("this", this);
		env.variables.set("script", this);
		env.variables.set("gameScript", this);
		env.variables.set("self", this);

		if (mainModule != null && mainModule.interp != null) {
			mainModule.variables.set("this", this);
			mainModule.variables.set("script", this);
			mainModule.variables.set("gameScript", this);
			mainModule.variables.set("self", this);
		}

		for (module in env.modules) {
			if (module.interp == null)
				continue;

			module.variables.set("this", this);
			module.variables.set("script", this);
			module.variables.set("gameScript", this);
			module.variables.set("self", this);
		}
	}

	// ---------------------------------------------------------------------
	// Type / instance helpers
	// ---------------------------------------------------------------------

	private function findClass(className:String):ScriptedClass {
		for (module in env.modules) {
			for (type in module.types) {
				if (Std.isOfType(type, ScriptedClass) && type.name == className) {
					return cast type;
				}
			}
		}
		return null;
	}

	private function getDefaultClass():ScriptedClass {
		if (defaultClassName == null)
			return null;
		return findClass(defaultClassName);
	}

	private function getInstance(className:String):Dynamic {
		if (instances.exists(className))
			return instances.get(className);

		var clazz = findClass(className);
		if (clazz == null)
			return null;

		bindScriptContext();

		// Lazy instance creation: not triggered by GameScript.new().
		var inst = clazz.typeCreateInstance([]);
		instances.set(className, inst);
		return inst;
	}

	private function hasInstanceField(clazz:ScriptedClass, field:String):Bool {
		return clazz.typeGetInstanceFields().contains(field);
	}

	private function findModuleFields(field:String):ScriptedClass {
		for (module in env.modules) {
			if (module.moduleFields != null && module.moduleFields.reflectHasField(field)) {
				return module.moduleFields;
			}
		}
		return null;
	}

	private function setStatic(clazz:ScriptedClass, name:String, value:Dynamic):Void {
		if (clazz.reflectSetProperty(name, value) == null) {
			clazz.reflectSetField(name, value);
		}
	}

	private function getStatic(clazz:ScriptedClass, name:String):Dynamic {
		var val = clazz.reflectGetProperty(name);
		if (val == null)
			val = clazz.reflectGetField(name);
		return val;
	}

	// ---------------------------------------------------------------------
	// Interpreter evaluation helpers
	// ---------------------------------------------------------------------

	private function evalWithVars(code:String, temp:Map<String, Dynamic>):Dynamic {
		if (mainModule == null || mainModule.interp == null)
			return null;

		bindScriptContext();

		var vars = mainModule.variables;
		var keys:Array<String> = [];

		for (k in temp.keys()) {
			vars.set(k, temp.get(k));
			keys.push(k);
		}

		function cleanup():Void {
			for (k in keys) {
				vars.remove(k);
			}
		}

		try {
			var program = mainModule.parser.parseScript(code, "GameScript.eval");
			var result = mainModule.interp.execute(program);
			cleanup();
			return result;
		} catch (e:Dynamic) {
			cleanup();
			throw e;
		}
	}

	private function getOnTarget(target:Dynamic, field:String):Dynamic {
		if (target == null)
			return null;

		var id = evalUid++;
		var targetName = '__gs_target_$id';

		var temp:Map<String, Dynamic> = new Map();
		temp.set(targetName, target);

		return evalWithVars('$targetName.$field', temp);
	}

	private function setOnTarget(target:Dynamic, field:String, value:Dynamic):Void {
		if (target == null)
			return;

		var id = evalUid++;
		var targetName = '__gs_target_$id';
		var valueName = '__gs_value_$id';

		var temp:Map<String, Dynamic> = new Map();
		temp.set(targetName, target);
		temp.set(valueName, value);

		evalWithVars('$targetName.$field = $valueName', temp);
	}

	private function callOnTarget(target:Dynamic, methodName:String, args:Array<Dynamic>):Dynamic {
		if (target == null)
			return null;

		var id = evalUid++;
		var targetName = '__gs_target_$id';

		var temp:Map<String, Dynamic> = new Map();
		temp.set(targetName, target);

		var argNames:Array<String> = [];

		for (i in 0...args.length) {
			var argName = '__gs_arg_${id}_$i';
			temp.set(argName, args[i]);
			argNames.push(argName);
		}

		var code = '$targetName.$methodName(' + argNames.join(", ") + ')';
		return evalWithVars(code, temp);
	}

	// ---------------------------------------------------------------------
	// Dynamic / fallback field access helpers
	// ---------------------------------------------------------------------

	private function tryScriptSet(target:Dynamic, field:String, value:Dynamic):Bool {
		var methods = ["__scriptSet", "__scriptSetField", "__setField", "setField"];

		for (m in methods) {
			try {
				var f = Reflect.field(target, m);
				if (f != null && Reflect.isFunction(f)) {
					Reflect.callMethod(target, f, [field, value]);
					return true;
				}
			} catch (e:Dynamic) {}
		}

		return false;
	}

	private function tryScriptGet(target:Dynamic, field:String):Dynamic {
		var methods = ["__scriptGet", "__scriptGetField", "__getField", "getField"];

		for (m in methods) {
			try {
				var f = Reflect.field(target, m);
				if (f != null && Reflect.isFunction(f)) {
					return Reflect.callMethod(target, f, [field]);
				}
			} catch (e:Dynamic) {}
		}

		return null;
	}

	private function tryProxySet(target:Dynamic, field:String, value:Dynamic):Bool {
		try {
			var cls = Type.resolveClass("hxscript.proxy.ReflectProxy");
			if (cls == null)
				return false;

			if (Type.getClassFields(cls).contains("setField")) {
				var f = Reflect.field(cls, "setField");
				if (f != null && Reflect.isFunction(f)) {
					Reflect.callMethod(cls, f, [target, field, value]);
					return true;
				}
			}
		} catch (e:Dynamic) {}

		return false;
	}

	private function tryProxyGet(target:Dynamic, field:String):Dynamic {
		try {
			var cls = Type.resolveClass("hxscript.proxy.ReflectProxy");
			if (cls == null)
				return null;

			if (Type.getClassFields(cls).contains("field")) {
				var f = Reflect.field(cls, "field");
				if (f != null && Reflect.isFunction(f)) {
					return Reflect.callMethod(cls, f, [target, field]);
				}
			}
		} catch (e:Dynamic) {}

		return null;
	}

	private function setInstanceFieldExisting(target:Dynamic, field:String, value:Dynamic):Void {
		if (target == null)
			return;

		try {
			setOnTarget(target, field, value);
			return;
		} catch (e:Dynamic) {}

		if (tryScriptSet(target, field, value))
			return;
		if (tryProxySet(target, field, value))
			return;

		try {
			Reflect.setField(target, field, value);
		} catch (e:Dynamic) {}
	}

	private function forceSetOnTarget(target:Dynamic, field:String, value:Dynamic):Void {
		if (target == null)
			return;

		// 1. Try normal scripted assignment
		try {
			setOnTarget(target, field, value);
			return;
		} catch (e:Dynamic) {}

		// 2. Fallbacks for scripted/native/dynamic instance storage
		if (tryScriptSet(target, field, value))
			return;
		if (tryProxySet(target, field, value))
			return;

		// 3. Final fallback: Reflect.setField which adds it to the dynamic object
		try {
			Reflect.setField(target, field, value);
		} catch (e:Dynamic) {}
	}

	private function dynamicGet(target:Dynamic, field:String):Dynamic {
		if (target == null)
			return null;

		try {
			return getOnTarget(target, field);
		} catch (e:Dynamic) {}

		var v = tryScriptGet(target, field);
		if (v != null)
			return v;

		v = tryProxyGet(target, field);
		if (v != null)
			return v;

		return Reflect.field(target, field);
	}

	// ---------------------------------------------------------------------
	// Global/shared variable helpers
	// ---------------------------------------------------------------------

	private function setGlobalVariable(name:String, value:Dynamic, forceCreate:Bool):Void {
		if (forceCreate) {
			env.variables.set(name, value);

			for (module in env.modules) {
				if (module.interp != null) {
					module.variables.set(name, value);
				}
			}

			return;
		}

		if (env.variables.exists(name)) {
			env.variables.set(name, value);
		}

		for (module in env.modules) {
			if (module.interp != null && module.variables.exists(name)) {
				module.variables.set(name, value);
			}
		}
	}

	private function getGlobalVariable(name:String):Dynamic {
		if (mainModule != null && mainModule.interp != null) {
			if (mainModule.variables.exists(name)) {
				return mainModule.variables.get(name);
			}
		}

		if (env.variables.exists(name)) {
			return env.variables.get(name);
		}

		for (module in env.modules) {
			if (module.interp != null && module.variables.exists(name)) {
				return module.variables.get(name);
			}
		}

		return null;
	}

	private function setDefaultScope(name:String, value:Dynamic, forceCreate:Bool):Void {
		// Top-level/module fields.
		var moduleFields = findModuleFields(name);
		if (moduleFields != null) {
			setStatic(moduleFields, name, value);
			return;
		}

		// Default script class fields.
		var defaultClass = getDefaultClass();
		if (defaultClass != null) {
			if (defaultClass.reflectHasField(name)) {
				setStatic(defaultClass, name, value);
				return;
			}

			if (hasInstanceField(defaultClass, name)) {
				var inst = getInstance(defaultClassName);
				if (inst != null) {
					setInstanceFieldExisting(inst, name, value);
				}
				return;
			}

			// If default instance already exists, allow existing/dynamic fields on it.
			if (instances.exists(defaultClassName)) {
				var inst = instances.get(defaultClassName);
				if (inst != null) {
					if (Reflect.hasField(inst, name)) {
						setInstanceFieldExisting(inst, name, value);
						return;
					}

					if (forceCreate) {
						forceSetOnTarget(inst, name, value);
						return;
					}
				}
			}
		}

		// Shared/global variables.
		setGlobalVariable(name, value, forceCreate);
	}

	// ---------------------------------------------------------------------
	// Dynamic proxy support
	// ---------------------------------------------------------------------

	public function resolve(name:String):Dynamic {
		return get(name);
	}

	public function setProperty(name:String, value:Dynamic):Void {
		set(name, value, null, true);
	}

	// ---------------------------------------------------------------------
	// Public API
	// ---------------------------------------------------------------------

	public function set(name:String, value:Dynamic, ?className:String, ?createVariable:Bool):GameScript {
		var forceCreate:Bool = createVariable == true;

		bindScriptContext();

		if (className != null) {
			var clazz = findClass(className);
			if (clazz == null)
				return this;

			// Static class field/property.
			if (clazz.reflectHasField(name)) {
				setStatic(clazz, name, value);
				return this;
			}

			var inst = getInstance(className);
			if (inst != null) {
				if (hasInstanceField(clazz, name) || Reflect.hasField(inst, name)) {
					setInstanceFieldExisting(inst, name, value);
				} else if (forceCreate) {
					// Force create on instance
					forceSetOnTarget(inst, name, value);
					// Fallback: also create it globally in case the script accesses it without 'this'
					setGlobalVariable(name, value, true);
				}
			} else if (forceCreate) {
				// Instance doesn't exist yet, but we can force create it as a static/global
				if (clazz.interp != null) {
					clazz.interp.variables.set(name, value);
				}
				setGlobalVariable(name, value, true);
			}

			return this;
		}

		setDefaultScope(name, value, forceCreate);
		return this;
	}

	public function get(name:String, ?className:String):Dynamic {
		bindScriptContext();

		if (className != null) {
			var clazz = findClass(className);
			if (clazz == null)
				return null;

			// Static class field/property.
			if (clazz.reflectHasField(name)) {
				return getStatic(clazz, name);
			}

			// Instance field/property, including inherited fields.
			var inst = getInstance(className);
			if (inst == null)
				return null;

			return dynamicGet(inst, name);
		}

		// Top-level/module fields.
		var moduleFields = findModuleFields(name);
		if (moduleFields != null) {
			return getStatic(moduleFields, name);
		}

		// Shared/global variables.
		var globalVal = getGlobalVariable(name);
		if (globalVal != null)
			return globalVal;

		// Default script class fields.
		var defaultClass = getDefaultClass();
		if (defaultClass != null) {
			if (defaultClass.reflectHasField(name)) {
				return getStatic(defaultClass, name);
			}

			if (hasInstanceField(defaultClass, name)) {
				var inst = getInstance(defaultClassName);
				if (inst != null) {
					return dynamicGet(inst, name);
				}
			}

			// If default instance already exists, allow dynamic reads without forcing creation.
			if (instances.exists(defaultClassName)) {
				var inst = instances.get(defaultClassName);
				if (inst != null) {
					return dynamicGet(inst, name);
				}
			}
		}

		return null;
	}

	public function call(methodName:String, ?args:Array<Dynamic>, ?className:String):Dynamic {
		var callArgs:Array<Dynamic> = args ?? [];

		bindScriptContext();

		if (className != null) {
			var clazz = findClass(className);
			if (clazz == null)
				return null;

			// Static class function.
			if (clazz.reflectHasField(methodName)) {
				var func = clazz.reflectGetField(methodName);
				if (func != null && Reflect.isFunction(func)) {
					return Reflect.callMethod(clazz.interp, func, callArgs);
				}

				// Fallback: let the interpreter call it as a member of the class object.
				if (func == null) {
					return callOnTarget(clazz, methodName, callArgs);
				}

				return null;
			}

			// Instance function, including inherited functions.
			var inst = getInstance(className);
			if (inst == null)
				return null;

			var func = Reflect.field(inst, methodName);
			if (func != null && Reflect.isFunction(func)) {
				return Reflect.callMethod(inst, func, callArgs);
			}

			if (hasInstanceField(clazz, methodName) || Reflect.hasField(inst, methodName)) {
				return callOnTarget(inst, methodName, callArgs);
			}

			// Last chance for extended/native/dynamic methods.
			try {
				return callOnTarget(inst, methodName, callArgs);
			} catch (e:Dynamic) {
				return null;
			}
		}

		var lookupName = methodName;
		if (lookupName.indexOf(".") != -1) {
			lookupName = lookupName.split(".").join("_");
		}

		// Top-level module functions.
		var moduleFields = findModuleFields(lookupName);
		if (moduleFields != null) {
			var func = moduleFields.reflectGetField(lookupName);
			if (func != null && Reflect.isFunction(func)) {
				return Reflect.callMethod(moduleFields.interp, func, callArgs);
			}
		}

		// Shared/global function variables.
		var funcDyn = getGlobalVariable(lookupName);
		if (funcDyn != null && Reflect.isFunction(funcDyn)) {
			return Reflect.callMethod(mainModule?.interp, funcDyn, callArgs);
		}

		return null;
	}

	public function start():Void {}
}
#end