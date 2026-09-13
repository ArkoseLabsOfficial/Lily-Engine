importScript("substates/DialogBox");
importScript("QuickStuff");
class zack_invite {
	var blockDialogMove:Bool = false;
	var blockDialogStart:Bool = false;
	var codeExecuted:Bool = false;

	function onOpen(evt) {}

	function onOptionSelected(evt) {
		if (evt.index == 0) {
			FlxG.state.openSubState(new DialogBox("zack_invite", "zack_intro_accept"));
		} else if (evt.index == 1) {
			FlxG.state.openSubState(new DialogBox("zack_invite", "zack_intro_refuse_1"));
		}
	}

	function onTextStart(evt) {
		if (blockDialogStart) {
			evt.cancelled = true;
			return;
		}
		if (!codeExecuted) {
			switch (evt.text) {
				case "Sarahhh, uyudunmu?":
					blockDialogStart = true;
					blockDialogMove = true;
					evt.cancelled = true;
					codeExecuted = true;
					DialogBoxHelper.hideUI(0, () -> Game.scene.root.script.instance.knockKnockKnock());
					new FlxTimer().start(1.25, function() {
						DialogBoxHelper.showUI(0.25, function() {
							blockDialogStart = false;
							blockDialogMove = false;
							playCurrentEntry();
						});
					});
				case "Sarahh...":
					blockDialogStart = true;
					blockDialogMove = true;
					evt.cancelled = true;
					codeExecuted = true;
					DialogBoxHelper.hideUI(0.25, () -> Game.scene.root.script.instance.knockKnockKnock());
					new FlxTimer().start(1.25, function() {
						DialogBoxHelper.showUI(0.25, function() {
							blockDialogStart = false;
							blockDialogMove = false;
							playCurrentEntry();
						});
					});
			}
		}
	}

	function onConfirm(evt) {
		if (blockDialogMove) {
			evt.cancelled = true;
			return;
		}
		switch (bodyText.text) {
			case "Olur.":
				blockDialogStart = true;
				blockDialogMove = true;
				DialogBoxHelper.hideUI(0.25, () -> Game.scene.root.script.instance.zackAndSarah());
				new FlxTimer().start(1.25, function() {
					DialogBoxHelper.showUI(0.25, function() {
						blockDialogStart = false;
						blockDialogMove = false;
						Game.scene.root.script.instance.zackAndSarah2();
						playCurrentEntry();
					});
				});
			case "Görüşürüz.":
				blockDialogStart = true;
				blockDialogMove = true;
				DialogBoxHelper.hideUI(0.25, () -> Game.scene.root.script.instance.zackAndSarah3());
				new FlxTimer().start(1.25, function() {
					DialogBoxHelper.showUI(0.25, function() {
						Game.party[0].movementEnabled = true;
						QuickStuff.enableInteraction();
						FlxG.state.persistentUpdate = false;
						blockDialogStart = false;
						blockDialogMove = false;
						playCurrentEntry();
					});
				});
		}
		codeExecuted = false;
	}

	function getRootScript() {
		return Game.scene.root.script.instance;
	}

	function onClose(evt) {
		switch (bodyText.text) {
			case "Sarahh...":
				QuickStuff.blackOut(0.25);
				getRootScript().sarahWakeUp();
			case "Bekle Bekle, tamam açıyorum.":
				getRootScript().zackEnters();
			case "(Beleş yemek her zaman güzeldir.)":
				
		}
		if (id == "zack_intro_refuse_1") {
			getRootScript().zackAndSarah3();
			Game.party[0].movementEnabled = true;
			QuickStuff.enableInteraction();
			FlxG.state.persistentUpdate = false;
		}
	}
}
