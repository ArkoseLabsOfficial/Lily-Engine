function onRoomLoaded() {
	faceEntity("player", "up");
	if (Save.getVariable("ch1_cafe_cutscene_seen")) {
		cashier.x = 244;
		cashier.y = 244;
		faceEntity("cashier", "down");
		return;
	}

	faceEntity("cashier", "left");
	lockPlayer(true);
	cutscenePart1();
	player.x -= 15;
}

function cutscenePart1() {
	// walkEntity("player", player.x, player.y - 150, 60, wait(2, cutscenePart2));
	cutscenePart2();
}

function cutscenePart2() {
	setCameraTarget("cashier");
	walkEntity("cashier", cashier.x - 100, cashier.y, 60, function() {
		cashier.playAnim("drop", true);
		wait(2, function() {
			faceEntity("cashier", "down");
			walkEntity("cashier", cashier.x, cashier.y + 20, 60);
			wait(2, function() {
				setCameraTarget("player");
				lockPlayer(false);
				trace(cashier.x);
				trace(cashier.y);
				Save.setVariable("ch1_cafe_cutscene_seen", true);
			});
		});
	});
}
