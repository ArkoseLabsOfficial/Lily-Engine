import godot.Scene;
import engine.ui.GameText;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.addons.display.shapes.FlxShapeBox;

importScript("FakeASync");

class PhoneUI {
	var ui:Scene;
	function update(elapsed:Float) {
		if (FlxG.keys.justPressed.P)
			close();
	}

    public function create() {
        ui = new Scene(0, 0);
        ui.load(Assets.getPath("scenes/phone/ch1_phone_talk.tscn"));
        add(ui);
		startCutscene();
	}

	public function startCutscene() {
		for (i in 1...9)
			ui.getNode("WhatsApp/Messages/Message"  + i).visible = false;

		new FakeASync().await([
			(wait) -> wait(2),
			(wait) -> {
				ui.getNode("WhatsApp/Messages/Message1").visible = true;
			},
			(wait) -> wait(2),
			(wait) -> {
				ui.getNode("WhatsApp/Messages/Message2").visible = true;
			},
			(wait) -> wait(2),
			(wait) -> {
				ui.getNode("WhatsApp/Messages/Message3").visible = true;
			},
			(wait) -> wait(2),
			(wait) -> {
				ui.getNode("WhatsApp/Messages/Message4").visible = true;
			},
			(wait) -> wait(2),
			(wait) -> {
				ui.getNode("WhatsApp/Messages/Message5").visible = true;
			},
			(wait) -> wait(2),
			(wait) -> {
				ui.getNode("WhatsApp/Messages/Message6").visible = true;
			},
			(wait) -> wait(2),
			(wait) -> {
				ui.getNode("WhatsApp/Messages/Message7").visible = true;
			},
			(wait) -> wait(2),
			(wait) -> {
				ui.getNode("WhatsApp/Messages/Message8").visible = true;
			},
		]);
	}
}
