import haxe.ds.StringMap;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import godot.nodes.Sprite;
import godot.PackedScene;
import godot.nodes.AnimationPlayer.TrackData;
import engine.scripting.HScript.Script;
import flixel.FlxObject;

importScript("GameRoom");
importScript("FakeASync");
class Ch1CutsceneCafe extends GameRoom {
	var texLacieDark:String = "";
	var nRoom:Dynamic = null;
	var nLacieSit:Dynamic = null;
	var nLacieChair:Dynamic = null;
	var nCashierDrop:Dynamic = null;
	var nCashierIdle:Dynamic = null;
	var nNpcA:Dynamic = null;
	var nNpcA2:Dynamic = null;
	var nNpcB:Dynamic = null;
	var nNpcB2:Dynamic = null;
	var nNpcC:Dynamic = null;
	var nNpcD:Dynamic = null;
	var nNpcE:Dynamic = null;
	var nNpcEIdle:Dynamic = null;
	var nNpcG:Dynamic = null;
	var nNpcF:Dynamic = null;

	// Cutscene
	function LacieComing() {
		Game.party[0].movementEnabled = false;
		Game.party[0].baseSpeed = 75;
		new FakeASync().await([
			(wait) -> wait(0.75),
			(wait) -> {
				playMusic("bgm/ch1_lacie_2.ogg");
				Game.party[0].moveTo(175, 240);
			},
		]);
		ch1_cashier.baseSpeed = 50;
		ch1_cashier.isSolid = false;
		ch1_cashier.moveTo(175, 165, function() {
			FlxG.state.openSubState(new DialogBox("cafe", "tryingTalk"));
			FlxG.state.persistentUpdate = true;
			CashierDrop();
		});
	}

	function CashierDrop() {
		var cashier = ch1_cashier;
		if (cashier != null)
			cashier.visible = false;

		if (nCashierDrop != null) {
			nCashierDrop.visible = true;
			FlxG.sound.play("sounds/sfx/glass_crack.ogg");
			nCashierDrop.Frame = 0;
			playNewNewBubble(bubble_cashier, "exclamation").y -= 20;

			new FakeASync().await([
				(delay) -> delay(1.5),
				(delay) -> {
					nCashierDrop.Frame = 1;
					FlxG.state.subState.close();
				}
				(delay) -> delay(0.3),
				(delay) -> {
					nCashierDrop.Frame = 2;
					if (cashier != null) {
						cashier.turn("down");
						cashier.x -= 1;
						cashier.y -= 1;
						cashier.visible = true;
					}
					if (nCashierDrop.visual != null) {
						FlxTween.tween(nCashierDrop.visual, {alpha: 0}, 1.0);
					}
					FlxG.state.openSubState(new DialogBox("cafe", "cashierHello"));
				}
			]);
		}
	}

	function cashierGoToLacie() {
		var cashier = ch1_cashier;
		new FakeASync().await([
			(delay) -> delay(1),
			(delay) -> {
				cashier.moveTo(cashier.x, cashier.y + 30, function() {
					new FakeASync().await([
						(wait) -> wait(0.5),
						(wait) -> {
							FlxG.state.openSubState(new DialogBox("cafe", "talkingWithCashier"));
							FlxG.state.persistentUpdate = false;
							LacieSit();
						},
					]);
				});
			}
		]);
	}

	function LacieSit() {
		CashierIdle();
		var lacie = Game.party[0];
		if (lacie != null)
			lacie.visible = false;
		if (nLacieSit != null)
			nLacieSit.visible = true;
		camFollow.y = 240;
	}

	function GirlLookingBack() {
		new FakeASync().await([
			(delay) -> delay(1),
			(delay) -> NpcBTurnBack(),
			(delay) -> delay(1),
			(delay) -> NpcBRestore(),
			(delay) -> delay(1),
			(delay) -> NpcBTurnBack(),
			(delay) -> delay(1),
			(delay) -> NpcBRestore(),
			(delay) -> delay(1),
			(delay) -> {
				FlxG.state.openSubState(new DialogBox("cafe", "girlAB"));
				FlxG.state.persistentUpdate = true;
			}
		]);
	}

	function GirlsABStandUp() {
		var npcAPoint = parent.scene.getNode("Points/npc_a");
		var npcBPoint = parent.scene.getNode("Points/npc_b");

		nNpcA.visible = false;
		nNpcB.visible = false;
		nLacieSit.Frame = 1;

		npc_a.baseSpeed = 50;
		npc_b.baseSpeed = 50;
		npc_a.visible = true;
		npc_b.visible = true;

		FlxTween.tween(camFollow, {y: 208}, 1);
		npc_a.moveTo(npcAPoint.x, npcAPoint.y - 60);
		npc_b.moveTo(npcBPoint.x, npcBPoint.y - 60, function() {
			GirlsABSit();
			new FakeASync().await([
				(wait) -> wait(2),
				(wait) -> {
					FlxG.state.openSubState(new DialogBox("cafe", "LadyMan"));
					FlxG.state.persistentUpdate = true;
				},
			]);
		});
	}

	function GirlsABSit() {
		var npcA = RegisteredNPCs.get("ch1_npc_a");
		var npcB = RegisteredNPCs.get("ch1_npc_b");

		npcA.visible = false;
		npcB.visible = false;

		nNpcA2.visible = true;
		nNpcB2.visible = true;
	}

	function LittleGirlPart() {
		new FakeASync().await([
			(wait) -> wait(1),
			(wait) -> {
				NpcETurnDown();
				FlxG.state.openSubState(new DialogBox("cafe", "ChildTalk"));
				FlxG.state.persistentUpdate = true;
			},
		]);
	}

	function LacieGetUp() {
		nLacieSit.visible = false;
		nLacieChair.x += 20;
		FlxG.sound.play("sounds/sfx/cafe_stand_up.ogg");
		stopMusic();

		var obj = Game.party[0];
		// shadow == lacie dark.
		obj.idlePrefix = "shadowIdle";
		obj.walkPrefix = "shadow";

		var point = GetPoint("get_up");
		obj.x = point.x;
		obj.y = point.y;

		var spawnPt = GetSpawnPoint("get_up");
		obj.direction = directions[spawnPt.script.instance.Direction];
		obj.visible = true;
		lookAllNPCsToLacie();
		new FakeASync().await([
			(wait) -> wait(1),
			(wait) -> {
				var lacie = Game.party[0];
				lacie.baseSpeed = 75;
				lacie.moveTo(lacie.x, lacie.y - 50, function() {
					lacie.baseSpeed = 175;
					lacie.moveTo(lacie.x - 275, lacie.y, function() {
						lacie.moveTo(lacie.x, lacie.y + 125, function() {
							lacie.visible = false;
							new FakeASync().await([
								(wait) -> wait(0.25),
								(wait) -> {
									FlxG.sound.play("sounds/sfx/door.ogg");
									FlxG.sound.play("sounds/sfx/door_chime.ogg");
									endCutscene();
								}
							]);
						});
					});
				});
			},
		]);
	}

	function lookAllNPCsToLacie() {
		NpcA2TurnDown();
		NpcB2TurnDown();
		NpcCTurnDown();
		NpcDTurnDown();
		NpcETurnDown();
		NpcGTurnRight();
		CashierTurn();
	}

	function endCutscene() {
		new FakeASync().await([
			(wait) -> wait(2),
			(wait) -> {
				FlxG.switchState(new ScriptedState("LacieAfterCafe"));
			}
		]);
	}

	var directions:Array<String> = [
		"none",
		"left",
		"up",
		"upLeft",
		"right",
		"upRight",
		"down",
		"downLeft",
		"downRight"
	];

	// --- Lifecycle Methods ---
	var ch1_cashier:Character = new Character(325, 165);
	var npc_a:Character = new Character(0, 0);
	var npc_b:Character = new Character(0, 0);
	var bubble_cashier:Dynamic = null;
	var bubble_lacie:Dynamic = null;
	var bubble_npc_e:Dynamic = null;

	override function _Initialize() {
		super._Initialize();
		nRoom = parent.scene.getNode("Ch2_Cafe");
		nLacieSit = nRoom.getNode("Main/Table4Chair2/LacieSit");
		nLacieChair = nRoom.getNode("Main/Table4Chair2");
		nCashierDrop = nRoom.getNode("Main/ChrCafeCashierDrop");
		nCashierIdle = nRoom.getNode("Main/CashierIdle");
		nNpcA = nRoom.getNode("Main/Table3Chair1/NpcA");
		nNpcA2 = nRoom.getNode("Background/FurnitureBench/NpcA2");
		nNpcB = nRoom.getNode("Main/Table3Chair2/NpcB");
		nNpcB2 = nRoom.getNode("Background/FurnitureBench3/NpcB2");
		nNpcC = nRoom.getNode("Background/FurnitureBench4/NpcC");
		nNpcD = nRoom.getNode("Background/FurnitureBench2/NpcD");
		nNpcE = nRoom.getNode("Background/Table1Chair4/NpcE");
		nNpcEIdle = nRoom.getNode("Background/Table1Chair4/NpcEIdle");
		nNpcG = nRoom.getNode("Main/Table2/NpcG");

		bubble_cashier = parent.scene.getNode("Points/bubble_cashier");
		bubble_lacie = parent.scene.getNode("Points/bubble_lacie");
		bubble_npc_e = parent.scene.getNode("Points/bubble_npc_e");

		initializeCharacters();

		nNpcF = parent.scene.getNode("Ch2_Cafe/Main/Table1/NpcF");
	}

	public function initializeCharacters() {
		ch1_cashier.loadEntity("cashier");
		parent.add(ch1_cashier);
		RegisteredNPCs.set("ch1_cashier", ch1_cashier);

		var npcAPoint = parent.scene.getNode("Points/npc_a");
		var npcBPoint = parent.scene.getNode("Points/npc_b");

		npc_a.loadEntity("npc_a");
		npc_a.x = npcAPoint.x;
		npc_a.y = npcAPoint.y;
		npc_a.direction = "up";
		npc_a.visible = false;
		parent.add(npc_a);
		RegisteredNPCs.set("ch1_npc_a", npc_a);

		npc_b.loadEntity("npc_b");
		npc_b.x = npcBPoint.x;
		npc_b.y = npcBPoint.y;
		npc_b.direction = "up";
		npc_b.visible = false;
		parent.add(npc_b);
		RegisteredNPCs.set("ch1_npc_b", npc_b);
	}

	public function showLaughs() {
		var npcA_laugh = playNewNewBubble(nNpcA, "laugh", false, true);
		var npcB_laugh = playNewNewBubble(nNpcB, "laugh", false, true);
		npcA_laugh.y += 10;
		npcB_laugh.y += 10;
		new FakeASync().await([
			(wait) -> wait(3.5),
			(wait) -> {
				npcA_laugh.visible = false;
				npcB_laugh.visible = false;
			},
		]);
	}

	override function _UpdateRoom() {
		if (nRoom != null && Reflect.hasField(nRoom, "_UpdateRoom")) {
			Reflect.callMethod(nRoom, Reflect.field(nRoom, "_UpdateRoom"), []);
		}
	}

	var camFollow:FlxObject;

	override function _BeforeFadeIn() {
		nLacieSit.visible = false;
		nCashierDrop.visible = false;
		nNpcE.visible = false;
		nNpcA2.visible = false;
		nNpcB2.visible = false;

		camFollow = new FlxObject(240, 190, 1, 1);
		// var camFollow = new FlxObject(240, 235, 1, 1); // start
		// var camFollow = new FlxObject(240, 208, 1, 1); //
		parent.add(camFollow);

		Game.baseRoom.camGame.follow(camFollow, "lockon", 1);

		FlxG.sound.play("sounds/sfx/door_chime.ogg");
		LacieComing();
	}

	function _BeforeFadeOut() {}

	function _AfterFadeIn() {}

	function _AfterFadeOut() {}

	function _RoomProcess(delta:Float) {}

	// --- Helper Methods ---
	function GetMainLayer():Dynamic {
		if (nRoom != null && Reflect.hasField(nRoom, "GetMainLayer")) {
			return nRoom.GetMainLayer();
		}
		return parent.scene.getNode("Ch2_Cafe/Main");
	}

	function GetSpawnPoint(pointName:String):Dynamic {
		var targetNode = parent.scene.getNode("Points/" + pointName);
		if (targetNode != null)
			return targetNode;

		trace("Warning: SpawnPoint not found: " + pointName);
		return null;
	}

	function GetPoint(pointName:String):Dynamic {
		var spawnPoint = GetSpawnPoint(pointName);
		if (spawnPoint != null) {
			return {x: spawnPoint.x, y: spawnPoint.y};
		}
		return {x: 0, y: 0};
	}

	function ChangeLayer(newLayer:Int) {}

	// Helpers
	var RegisteredNPCs:StringMap = new StringMap();

	public function playNewNewBubble(obje:Sprite, bubble:String, ?silent:Bool = true, ?loop:Bool = false):Node {
		var name = '${obje.name}_bubble';
		if (silent)
			bubble += "_silent";

		var bubbleScene = new PackedScene(obje.x, obje.y - 40).load('data/scenes/$bubble.tscn');
		var bubbleNode = bubbleScene.instance(parent.scene);
		bubbleNode.script.instance.InitSelf(name);
		parent.scene.root.addChild(name, bubbleNode);
		bubbleNode.name = name;
		var animPlayer:AnimationPlayer = cast bubbleNode.getNode("Animation");
		var animData = animPlayer.animations.get("animation");

		if (loop) {
			animData.loop = true;
		} else if (animData != null) {
			var track = new TrackData();
			track.path = ".";
			track.type = "method";
			track.times = [animData.length - 0.01];
			track.methodNames = ["DestroySelf"];
			track.methodArgs = [[bubbleNode.name]];

			animData.tracks.push(track);
		}
		animPlayer.play("animation");

		return bubbleNode;
	}

	// Cutscene Extras
	function LacieSitBubble() {
		new FakeASync().await([
			(wait) -> wait(1),
			(wait) -> lacieBubble(true),
			(wait) -> wait(3.5),
			(wait) -> {
				FlxG.state.openSubState(new DialogBox("cafe", "lacieToughts"));
				FlxG.state.persistentUpdate = true;
			},
		]);
	}

	public function girlATalk() {
		playNewNewBubble(nNpcA, "talk");
	}

	public function girlBTalk() {
		playNewNewBubble(nNpcB, "talk");
	}

	public function ladyTalk() {
		playNewNewBubble(nNpcD, "talk");
	}

	public function manTalk() {
		playNewNewBubble(nNpcC, "talk");
	}

	public function childTalk() {
		playNewNewBubble(nNpcE, "talk");
	}

	public function motherTalk() {
		playNewNewBubble(nNpcF, "talk");
	}

	public function lacieBubble(?silent:Bool = false) {
		playNewNewBubble(bubble_lacie, "ellipsis", silent).y += 40;
	}

	function CashierIdle() {
		var cashier = RegisteredNPCs.get("ch1_cashier");
		cashier.visible = false;
		nCashierIdle.visible = true;
	}

	function CashierTurn() {
		var cashier = RegisteredNPCs.get("ch1_cashier");
		nCashierIdle.visible = false;
		cashier.visible = true;
		cashier.setPosition(nCashierIdle.x, nCashierIdle.y + 25);
		cashier.direction = "down";
	}

	function NpcATurnUp() {
		nNpcA.script.instance.turn("up");
	}

	function NpcA2TurnDown() {
		nNpcA2.script.instance.turn("down");
	}

	function NpcBTurnUp() {
		nNpcB.script.instance.turn("up");
	}

	function NpcBTurnBack() {
		nNpcB.script.instance.turn("right");
	}

	function NpcB2TurnDown() {
		nNpcB2.script.instance.turn("down");
	}

	function NpcCTurnDown() {
		nNpcC.script.instance.turn("down");
	}

	function NpcDTurnDown() {
		nNpcD.script.instance.turn("down");
	}

	function NpcETurnDown() {
		nNpcE.visible = true;
		nNpcE.script.instance.turn("down");
		nNpcEIdle.visible = false;
	}

	function NpcGTurnRight() {
		nNpcG.script.instance.turn("right");
	}

	function NpcARestore() {
		nNpcA.script.instance.turnToDefault();
	}

	function NpcBRestore() {
		nNpcB.script.instance.turnToDefault();
	}

	function NpcCRestore() {
		nNpcC.script.instance.turnToDefault();
	}

	function NpcDRestore() {
		nNpcD.script.instance.turnToDefault();
	}

	function NpcGRestore() {
		nNpcG.script.instance.turnToDefault();
	}

	function NpcERestore() {
		nNpcE.visible = false;
		nNpcEIdle.visible = true;
	}
}
