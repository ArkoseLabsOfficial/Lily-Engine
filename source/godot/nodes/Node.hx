package godot.nodes;

import flixel.group.FlxSpriteGroup;

/**
 * A class that mimics Godot Engine Node.
 * @Author ArkoseLabs.
 */
class Node extends FlxSpriteGroup {
	public var children:Dynamic = {};
	public var parent:Node = null;
	public var name:String = "";
	public var scriptPath:String = null;
	public var script:Dynamic = null;

	public function new() {
		super();
        moves = false;
	}

	public function addChild(name:String, node:Node) {
		Reflect.setField(children, name, node);
		node.parent = this;
		node.name = name;
		this.add(node);
	}

	public function removeChild(name:String, node:Node) {
		if (Reflect.hasField(children, name)) {
			Reflect.deleteField(children, name);
			node.parent = null;
			this.remove(node, true);
		}
	}

	/**
	 * Gets a node by its relative path.
	 * Supports downward traversal ("Child/Grandchild") and upward traversal ("../Sibling").
	 */
	public function getNode(nodePath:String):Node {
		if (nodePath == null || nodePath == "")
			return this;

		var parts = nodePath.split("/");
		var current:Node = this;

		for (part in parts) {
			if (part == "." || part == "")
				continue;

			if (part == "..") {
				if (current.parent != null) {
					current = current.parent;
				} else {
					return null;
				}
			} else {
				if (current.children != null && Reflect.hasField(current.children, part)) {
					current = cast Reflect.field(current.children, part);
				} else {
					return null;
				}
			}
		}
		return current;
	}
}
