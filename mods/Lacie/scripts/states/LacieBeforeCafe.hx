class LacieBeforeCafe {
	public function createPost() {
		new FlxTimer().start(2, function() {
			Game.save.setVariable("cafeSelectorFinished", true);
			FlxG.state.openSubState(new DialogBox("void", "cafeSelector"));
			FlxG.state.persistentUpdate = true;

			#if FEATURE_TOUCH_CONTROLS
			Game.mobileC.removeDPad();
			Game.mobileC.removeButton();
			#end
		});
	}
}
