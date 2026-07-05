package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class AbstractMacro {
	public static macro function generateWrappers(classes:Array<String>):Expr {
		for (className in classes) {
			var type = Context.getType(className);

			var parts = className.split(".");
			var baseName = parts.pop();
			var pack = parts;
			var newClassName = baseName + "_HX";

			var typeDef = {
				pack: pack,
				name: newClassName,
				pos: Context.currentPos(),
				kind: TDClass(),
				fields: []
			};

			Context.defineType(typeDef);
			trace("Generated: " + pack.join(".") + "." + newClassName);
		}
		return macro null;
	}
}
