using StringTools;

class Bubble {
	public var sfxSound:String;

	public function PlaySound() {
		sfxSound = sfxSound.replace("assets/", "");
		FlxG.sound.play('sounds/$sfxSound');
	}

	public function InitSelf(nodeName:String) {
		var nodeToRemove = scene.root.getNode(nodeName);
		if (nodeToRemove == null)
			return;

		if (nodeToRemove != null && nodeToRemove.parent != null) {
			nodeToRemove.parent.removeChild(nodeToRemove.name, nodeToRemove);
		}
	}

	public function DestroySelf(nodeName:String) {
		var nodeToRemove = scene.root.getNode(nodeName);
		if (nodeToRemove != null && nodeToRemove.parent != null) {
			nodeToRemove.parent.removeChild(nodeToRemove.name, nodeToRemove);
		}
	}
}
