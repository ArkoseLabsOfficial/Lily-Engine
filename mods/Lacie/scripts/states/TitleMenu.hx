class TitleMenu {
	function createPost() {
		bg.loadLocalizedGraphic(Assets.getImagePath("paperlily/paperlily_title"));
		bg.scale.set(1, 1);
		bg.setPosition(0, 0);
		var logo = new LangSprite(1000, 300, Assets.getImagePath("paperlily/title_logo_paperlily"));
		logo.antialiasing = true;
		logo.scale.set(0.75, 0.75);
		insert(1, logo);
	}
	function onStartingNewGame(evt) {
		evt.cancelled = true;
		FlxG.switchState(new ScriptedState('LacieBeforeCafe'));
	}
}
