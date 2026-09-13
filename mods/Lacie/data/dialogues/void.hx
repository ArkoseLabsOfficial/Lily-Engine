importScript("substates/DialogBox");
using StringTools;

class void {
	var canInvisible:Bool = false;

	function onOpen(evt) {
		DialogBoxHelper.hideUI(0);
		DialogBoxHelper.showUI(0.25);
		if (id == "cafeSelector")
			canInvisible = true;
	}

	function onTextStart(evt) {
		if (evt.text == "...For now, I'll focus on getting the first item on the list done.")
			canInvisible = false;

		if (id == "cafeSelector" && evt.entry.name == null && canInvisible) {
			bg.visible = false;
			continueIcon.x = 900;
		} else if (id == "cafeSelector") {
			bg.visible = true;
			continueIcon.x = 1340;
		}

		if (evt.entry.translate != null) {
			var drinkIdx:Int = Game.save.getVariable("ch1.cafe.drinkIndex");
			var foodIdx:Int = Game.save.getVariable("ch1.cafe.foodIndex");
			var targetIndex = (drinkIdx * 3) + foodIdx;
			evt.text = evt.text.replace("[0]", '[$targetIndex]');
		}
	}

	function onOptionSelected(evt) {
		switch (evt.index) {
			case 0:
				switch (evt.optionId) {
					case "ch1.cafe.drink":
						Game.save.setVariable("ch1.cafe.drink", "Coffee");
						Game.save.setVariable("ch1.cafe.drinkIndex", 0);
					case "ch1.cafe.food":
						Game.save.setVariable("ch1.cafe.food", "Flan");
						Game.save.setVariable("ch1.cafe.foodIndex", 0);
				}
			case 1:
				switch (evt.optionId) {
					case "ch1.cafe.drink":
						Game.save.setVariable("ch1.cafe.drink", "Green Tea");
						Game.save.setVariable("ch1.cafe.drinkIndex", 1);
					case "ch1.cafe.food":
						Game.save.setVariable("ch1.cafe.food", "Macarons");
						Game.save.setVariable("ch1.cafe.foodIndex", 1);
				}
			case 2:
				switch (evt.optionId) {
					case "ch1.cafe.drink":
						Game.save.setVariable("ch1.cafe.drink", "Strawberry Milkshake");
						Game.save.setVariable("ch1.cafe.drinkIndex", 2);
					case "ch1.cafe.food":
						Game.save.setVariable("ch1.cafe.food", "Chocolate Eclair");
						Game.save.setVariable("ch1.cafe.foodIndex", 2);
				}
		}
	}

	function onClose(evt) {
		if (id == "cafeSelector") {
			evt.cancelled = true;
			var drink = Game.save.getVariable("ch1.cafe.drink");
			var food = Game.save.getVariable("ch1.cafe.food");

			loadDialogSequence('cafe_selector_after');
			playCurrentEntry();
		} else if (id == "cafe_selector_after") {
			FlxG.switchState(new BaseRoom("Ch1_Cutscene_Cafe"));
		} else if (id == "cantGet") {
			StateBackend.instance.call("showImage");
		}
	}
}
