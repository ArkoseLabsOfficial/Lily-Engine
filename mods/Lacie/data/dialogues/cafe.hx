import openfl.utils.Assets;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;

importScript("substates/DialogBox");
importScript("FakeASync");
using StringTools;

class cafe {
	var talkBG:FlxSprite = new FlxSprite(0, -450);
	var blackBG:FlxSprite = new FlxSprite(0, 0);
	var executed:Bool = false;
	var canConfirm:Bool = true;
	var currentText:String = null;
	var prevName:String = null;
	var talkBGYTween:FlxTween;

	function onOpen(evt) {
		blackBG.makeGraphic(1920, 1080, FlxColor.BLACK);
		insert(0, blackBG);
		blackBG.alpha = 0;
		switch (id) {
			case "talkingWithCashier":
				evt.cancelled = true;
				blackBG.alpha = 1;
				talkBG.loadGraphic("images/img/cg/ch1/lacie_cafe.png");
				talkBG.antialiasing = true;
				talkBG.alpha = 0;
				insert(1, talkBG);

				DialogBoxHelper.hideUI(0);

				FlxTween.tween(talkBG, {alpha: 1}, 1);
				talkBGYTween = FlxTween.tween(talkBG, {y: 0}, 3);
				DialogBoxHelper.showUI(0.25, () -> {
					if (jsonData != null)
						playCurrentEntry();
				});
		}
	}

	function onTextStart(evt) {
		currentText = evt.text;

		switch (currentText) {
			case "Could I get-":
				canConfirm = false;
			case "(Her whole vibe is... really unsettling.)":
				talkBGYTween.cancel();
				talkBG.y = 0; // just like og game lol.
			case "...Two of each, yes.", "Um... just one of those on display.", "...And a coffee.":
				talkBG.loadGraphic("images/img/cg/ch1/lacie_cafe_2.png");
			case "...And the milkshake.", "...And a tea, please.", "...":
				talkBG.loadGraphic("images/img/cg/ch1/lacie_cafe_3.png");
			case "Um... strawberry please.", "Then... just a flan.", "...Maybe one of each?", "...That one, then.":
				talkBG.loadGraphic("images/img/cg/ch1/lacie_cafe_5.png");
			case "...W-wait... concentrate?", "...Um... Actually, just a bottle of water... please.", "Tea, I think.", "...Maybe bubble tea then?":
				talkBG.loadGraphic("images/img/cg/ch1/lacie_cafe_6.png");
			case "Another fruit...?", "Just coffee?", "(What's bubble tea...?)", "(Which was it...? It was none of those...!)":
				talkBG.loadGraphic("images/img/cg/ch1/lacie_cafe_4.png");
			case "What is it? Did you notice that girl too?":
				callFromRoot("fadeOutMusic", [2.5]);
			case "Do you wanna move?":
				new FlxTimer().start(1.5, function() {
					callFromRoot("playMusic", ["bgm/ch1_anxiety.ogg", 1, true, true]);
				});
			// Lady and Man's anims
			case "That girl.. isn't she the daughter of the family who lives on the next block?":
				callFromRoot("NpcCTurnDown");
			case "Oh my goodness. You're right.":
				callFromRoot("NpcDTurnDown");
			case "Man... Just being around her gives me the chills.":
				callFromRoot("NpcDRestore");
				callFromRoot("NpcCRestore");
			case "${translate[0]}?":
				if (evt.entry.translate != null) {
					var drinkIdx:Int = Game.save.getVariable("ch1.cafe.drinkIndex");
					var foodIdx:Int = Game.save.getVariable("ch1.cafe.foodIndex");
					var targetIndex = (drinkIdx * 3) + foodIdx;
					evt.text = evt.text.replace("[0]", '[$targetIndex]');
				}
			case "${translate[0]}":
				var foodIdx:Int = Game.save.getVariable("ch1.cafe.foodIndex");
				switch (foodIdx) {
					case 0:
						evt.text = "...A bottle of water and a flan...?";
					case 1:
						evt.text = "...A water and six macarons?";
					case 2:
						evt.text = "...A bottle of water and a single eclair?";
				}
		}
		if (prevName != evt.entry.name) {
			var name = evt.entry.name;
			switch (name) {
				case "Girl A":
					callFromRoot("girlATalk");
				case "Girl B":
					callFromRoot("girlBTalk");
				case "Lady":
					callFromRoot("ladyTalk");
				case "Man":
					callFromRoot("manTalk");
				case "Child":
					callFromRoot("childTalk");
				case "Mother":
					callFromRoot("motherTalk");
			}
		}

		prevName = evt.entry.name;
	}

	function onSelectionOpen(evt) {}

	function onOptionSelected(evt) {}

	function fadeOutBlackBGAndBoxAndClose(func:String, ?delay:Float = 0) {
		DialogBoxHelper.hideUI(0.25);
		new FakeASync().await([
			(wait) -> FlxTween.tween(blackBG, {alpha: 0}, 0.2),
			(wait) -> wait(1.2),
			(wait) -> {
				if (delay == 0)
					callFromRoot(func);
				close();
			},
		]);
		if (delay != 0) {
			new FlxTimer().start(delay, function() {
				callFromRoot(func);
			});
		}
	}

	function slideBoxTransition(timerDuration:Float, ?onMidAction:Void->Void, ?tweenBlackBGAlpha:Float) {
		var actions = function() {
			new FakeASync().await([
				(wait) -> wait(1),
				(wait) -> DialogBoxHelper.showUI(0.25, function() {
					continueIcon.visible = false;
					bodyText.text = "";
					nameText.text = "";
					progressDialog();
					new FlxTimer().start(1, function() {
						executed = false;
					});
				})
			]);
		}
		new FakeASync().await([
			(wait) -> DialogBoxHelper.hideUI(0.25, function() {
				if (onMidAction != null)
					onMidAction();
			}),
			(wait) -> wait(timerDuration + 0.25),
			(wait) -> {
				if (tweenBlackBGAlpha != null) {
					FlxTween.tween(blackBG, {alpha: tweenBlackBGAlpha}, 0.25, {
						onComplete: function() {
							actions();
						}
					});
				} else {
					actions();
				}
			},
		]);
	}

	function callFromRoot(func:String, ?args:Array<Dynamic> = []) {
		if (args == null)
			args = [];
		Game.room.scene.root.script.call(func, args);
	}

	function onClose(evt) {
		if (executed) {
			evt.cancelled = true;
			return;
		}
		switch (currentText) {
			case "Have a seat, I'll bring it for you.":
				evt.cancelled = true;
				executed = true;
				fadeOutBlackBGAndBoxAndClose("LacieSitBubble");
			case "(I can't even do this much?)":
				callFromRoot("GirlLookingBack");
			case "(It's just two girls. You can put up with it.)":
				evt.cancelled = true;
				executed = true;
				fadeOutBlackBGAndBoxAndClose("GirlsABStandUp", 0.1);
			case "Whatever! She's a freak.":
				evt.cancelled = true;
				executed = true;
				fadeOutBlackBGAndBoxAndClose("LittleGirlPart");
			case "It's probably her fault, don't you think?":
				callFromRoot("LacieGetUp");
		}
		switch (id) {
			case "talkingWithCashier":
				evt.cancelled = true;
				returnToSelectionDialog("ch1.cafe.food");
			case "talkingWithCashier_(Flan)", "talkingWithCashier_(Macarons)", "talkingWithCashier_(Chocolate Eclair)":
				evt.cancelled = true;
				returnToSelectionDialog("ch1.cafe.drink");
			case "talkingWithCashier_(Coffee)", "talkingWithCashier_(Green Tea)", "talkingWithCashier_(Strawberry Milkshake)":
				evt.cancelled = true;
				loadDialogSequence('talkingWithCashier_Post');
				playCurrentEntry();
		}
	}

	function returnToSelectionDialog(selection:String) {
		var load = Game.save.getVariable(selection);
		loadDialogSequence('talkingWithCashier_($load)');
		playCurrentEntry();
	}

	function onClosePost(evt) {}

	function onOpenPost(evt) {}

	function onCharTyped(evt) {}

	function onCharTypedPost(num) {}

	function onSkip(evt) {}

	function onSkipPost(evt) {}

	function onConfirm(evt) {
		if (executed) {
			evt.cancelled = true;
			return;
		}
		evt.cancelled = !canConfirm;
		switch (currentText) {
			case "Oh, h-hello.":
				callFromRoot("cashierGoToLacie");
			case "Alright.":
				evt.cancelled = true;
				executed = true;
				FlxTween.tween(talkBG, {alpha: 0}, 0.25, {
					onComplete: function() {
						FlxG.sound.play("sounds/sfx/cash_register.ogg");
					}
				});
				slideBoxTransition(1.0);

			case "She gives off creepy vibes...":
				evt.cancelled = true;
				executed = true;
				slideBoxTransition(3.0, function() {
					callFromRoot("lacieBubble");
				});
			case "Go go, before she curses us or something!":
				evt.cancelled = true;
				executed = true;
				slideBoxTransition(3.0, function() {
					callFromRoot("showLaughs");
				}, 1.0);
			case "I don't want it anymore, I wanna go...":
				evt.cancelled = true;
				executed = true;
				slideBoxTransition(1.0, function() {
					callFromRoot("NpcERestore");
				});
		}
	}

	function onConfirmPost(evt) {}

	function onTextComplete(evt) {}

	function onTextCompletePost(evt) {}

	function onSelectionOpenPost(opts) {}

	function onSelectionClose(evt) {}

	function onSelectionClosePost(evt) {}

	function onOptionSelectedPost(idx, id) {}
}
