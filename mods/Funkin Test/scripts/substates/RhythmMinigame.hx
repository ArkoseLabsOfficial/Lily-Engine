import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;
import openfl.geom.Rectangle;
import flixel.math.FlxMath;
import engine.backend.Discord;
import engine.backend.Game;

importScript("RoomProps");
importScript("JsonParser");
class RhythmNote extends FlxSprite {
	var time:Float = 0;
	var visualTime:Float = 0;
	var noteData:Int = 0;
	var mustPress:Bool = false;
	var isSustainNote:Bool = false;
	var sustainLength:Float = 0;
	var wasGoodHit:Bool = false;
	var tooLate:Bool = false;
	var canBeHit:Bool = false;
	var parentNote:RhythmNote = null;

	function new(x:Float, y:Float) {
		super(x, y);
	}
}

class RhythmMinigame {
	public static function test() {
		trace("test");
	}

	var coolData:Dynamic;
	var bg:FlxSprite;
	var strumLineNotes:FlxTypedGroup;
	var allNotes:FlxTypedGroup;
	var unspawnNotes:Array<RhythmNote> = [];
	var opponentStrums:Array<FlxSprite> = [];
	var playerStrums:Array<FlxSprite> = [];
	var scoreTxt:FlxText;
	var score:Int = 0;
	var combo:Int = 0;
	var misses:Int = 0;
	var songPos:Float = 0;
	var scrollSpeed:Float = 1.0;
	var speedMult:Float = 1.0;
	var stepCrochet:Float = 100;
	var safeZoneOffset:Float = 160;
	var noteOffset:Float = 0;
	var noteColors:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];
	var strumGlowTimers:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];
	var chartData:Dynamic;
	var vocals:FlxSound;
	var isPlaying:Bool = false;

	function new(?datas:Dynamic) {
		coolData = datas;
	}

	var kris:Dynamic;
	var susie:Dynamic;

	function create() {
		kris = Game.room.currentScene.getNode("Main/Kris");
		kris.visible = true;
		susie = Game.room.currentScene.getNode("Main/Susie");
		susie.visible = true;
		coolData = data;
		Discord.updatePresence("Playing Rythm Mini Game", 'Song: ${data.song}');
		RoomProps.music.pause();
		// bg = new FlxSprite().makeGraphic(1920, 1080, 0xFF1A1A1A);
		// add(bg);

		if (Reflect.hasField(GamePrefs, "noteOffset")) {
			noteOffset = GamePrefs.noteOffset;
		}

		strumLineNotes = new FlxTypedGroup();
		FlxG.state.subState.add(strumLineNotes);

		allNotes = new FlxTypedGroup();
		FlxG.state.subState.add(allNotes);

		for (i in 0...8) {
			var isPlayer = (i >= 4);
			var dir = i % 4;

			var strum = new FlxSprite();
			var startX = isPlayer ? 1100 : 200;
			strum.x = startX + (dir * 120);
			strum.y = 100;

			strum.makeGraphic(100, 100, 0xFFFFFFFF, true, "strum_" + i);
			strum.pixels.fillRect(new Rectangle(6, 6, 88, 88), 0x00000000);
			strum.color = 0xFF555555;

			strumLineNotes.add(strum);
			if (isPlayer)
				playerStrums.push(strum);
			else
				opponentStrums.push(strum);
		}

		scoreTxt = new FlxText(0, 1000, 1920, "Score: 0 | Combo: 0 | Misses: 0", 32);
		scoreTxt.setFormat(LilyAssets.font("vcr.ttf"), 32, 0xFFFFFFFF, "center");
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		parseChart();

		var instSnd = LilyAssets.returnSound(null, coolData.inst);
		if (instSnd != null) {
			FlxG.sound.playMusic(instSnd);
			isPlaying = true;
		} else {
			FlxG.log.warn("Inst sound not found: " + coolData.inst);
		}

		if (coolData.voices != null && coolData.voices != "") {
			var vocSnd = LilyAssets.returnSound(null, coolData.voices);
			if (vocSnd != null) {
				vocals = new FlxSound().loadEmbedded(vocSnd);
				FlxG.sound.list.add(vocals);
				vocals.play();
			}
		}
	}

	function parseChart() {
		var rawJson = LilyAssets.getTextFromFile(coolData.chart);
		if (rawJson == null) {
			FlxG.log.error("Failed to load chart: " + coolData.chart);
			return;
		}

		chartData = JsonParser.parse(rawJson).song;

		if (Reflect.hasField(chartData, "speed"))
			scrollSpeed = chartData.speed;
		speedMult = scrollSpeed * 0.45;

		var bpm:Float = 100;
		if (Reflect.hasField(chartData, "bpm"))
			bpm = chartData.bpm;
		stepCrochet = (60 / bpm) * 250;

		for (section in chartData.notes) {
			var gotPlayer = section.mustHitSection;
			for (noteData in section.sectionNotes) {
				var nTime = noteData[0];
				var nDir = Std.int(noteData[1]);
				var nSus = noteData[2];

				var isPlayerNote = gotPlayer;
				if (nDir > 3) {
					isPlayerNote = !isPlayerNote;
					nDir %= 4;
				}

				var note = new RhythmNote(0, -2000);
				note.time = nTime;
				note.visualTime = nTime;
				note.noteData = nDir;
				note.mustPress = isPlayerNote;
				note.sustainLength = nSus;
				note.isSustainNote = false;

				note.makeGraphic(90, 90, 0xFFFFFFFF, true, "noteGraphic_" + Std.string(noteColors[nDir]));
				note.pixels.fillRect(new Rectangle(4, 4, 82, 82), noteColors[nDir]);
				unspawnNotes.push(note);

				if (nSus > 0) {
					var susAmount = Math.floor(nSus / stepCrochet);
					var prevNote = note;

					for (sus in 0...susAmount) {
						var susNote = new RhythmNote(0, -2000);
						susNote.visualTime = nTime + (stepCrochet * sus);
						susNote.time = nTime + (stepCrochet * (sus + 1));

						susNote.noteData = nDir;
						susNote.mustPress = isPlayerNote;
						susNote.isSustainNote = true;
						susNote.parentNote = prevNote;

						var h = Math.ceil(stepCrochet * speedMult) + 1;
						susNote.makeGraphic(30, h, noteColors[nDir], true, "susGraphic_" + h + "_" + Std.string(noteColors[nDir]));
						susNote.alpha = 0.6;
						unspawnNotes.push(susNote);

						prevNote = susNote;
					}
				}
			}
		}

		unspawnNotes.sort(function(a, b) {
			return Std.int(a.time - b.time);
		});
	}

	function updateScore() {
		scoreTxt.text = "Score: " + score + " | Combo: " + combo + " | Misses: " + misses;
	}

	function goodHit(note:RhythmNote) {
		if (!note.wasGoodHit) {
			note.wasGoodHit = true;

			if (note.mustPress) {
				if (!note.isSustainNote) {
					combo++;
					score += 350;
				} else {
					score += 10;
				}
				updateScore();
			}

			if (!note.isSustainNote)
				note.kill();

			var sIndex = note.noteData + (note.mustPress ? 4 : 0);
			strumGlowTimers[sIndex] = 0.15;
		}

		if (note.mustPress) {
			var krisAnim = "down";
			kris.customOffset.y = 0;
			kris.customOffset.x = 0;
			switch (note.noteData) {
				case 0:
					krisAnim = "left";
					kris.customOffset.y = 1;
				case 1:
					krisAnim = "down";
				case 2:
					krisAnim = "up";
					kris.customOffset.y = -3;
					kris.customOffset.x = -3;
				case 3:
					krisAnim = "right";
					kris.customOffset.y = 1;
			}

			kris.play(krisAnim);
		} else {
			var susieAnim = "down";
			susie.customOffset.y = 0;
			susie.customOffset.x = 0;
			switch (note.noteData) {
				case 0:
					susieAnim = "left";
					susie.customOffset.y = 2;
				case 1:
					susieAnim = "down";
				case 2:
					susieAnim = "down";
				case 3:
					susieAnim = "right";
					susie.customOffset.y = 2;
			}

			susie.play(susieAnim);
		}
	}

	function noteMiss(note:RhythmNote) {
		if (note.tooLate)
			return;

		if (note.mustPress) {
			var krisAnim = "down";
			kris.customOffset.y = 0;
			kris.customOffset.x = 0;
			switch (note.noteData) {
				case 0:
					krisAnim = "left";
					kris.customOffset.y = 1;
				case 1:
					krisAnim = "down";
				case 2:
					krisAnim = "up";
					kris.customOffset.y = -3;
					kris.customOffset.x = -3;
				case 3:
					krisAnim = "right";
					kris.customOffset.y = 1;
			}

			kris.play(krisAnim);
		} else {
			var susieAnim = "down";
			susie.customOffset.y = 0;
			susie.customOffset.x = 0;
			switch (note.noteData) {
				case 0:
					susieAnim = "left";
					susie.customOffset.y = 2;
				case 1:
					susieAnim = "down";
				case 2:
					susieAnim = "down";
				case 3:
					susieAnim = "right";
					susie.customOffset.y = 2;
			}

			susie.play(susieAnim);
		}
		note.tooLate = true;

		if (!note.isSustainNote) {
			combo = 0;
			misses++;
			score -= 10;
		}

		note.alpha = 0.3;
		updateScore();
	}

	function update(elapsed:Float) {
		susie.visual.animation.finishCallback = function(animName:String):Void {
			susie.customOffset.y = 0;
			susie.play("up");
		};
		if (isPlaying && FlxG.sound.music != null) {
			songPos = FlxG.sound.music.time + noteOffset;

			if (vocals != null && vocals.playing && Math.abs(vocals.time - FlxG.sound.music.time) > 20) {
				vocals.time = FlxG.sound.music.time;
			}
		} else {
			songPos += elapsed * 1000;
		}

		while (unspawnNotes.length > 0 && unspawnNotes[0].time - songPos < 1500) {
			var n = unspawnNotes.shift();
			allNotes.add(n);
		}

		var justPressed = [
			FlxG.keys.justPressed.D,
			FlxG.keys.justPressed.F,
			FlxG.keys.justPressed.J,
			FlxG.keys.justPressed.K
		];
		var isHolding = [
			FlxG.keys.pressed.D,
			FlxG.keys.pressed.F,
			FlxG.keys.pressed.J,
			FlxG.keys.pressed.K
		];

		for (note in allNotes.members) {
			if (note == null || !note.alive)
				continue;

			var strumGrp = note.mustPress ? playerStrums : opponentStrums;
			var strum = strumGrp[note.noteData];

			var strumCenterY = strum.y + strum.height / 2;
			note.x = strum.x + (strum.width - note.width) / 2;

			var vTime = note.isSustainNote ? note.visualTime : note.time;
			var distance = (songPos - vTime) * speedMult;

			if (!note.isSustainNote) {
				note.y = strumCenterY - (note.height / 2) - distance;
			} else {
				note.y = strumCenterY - distance;
			}

			if (note.mustPress) {
				note.canBeHit = (note.time > songPos - safeZoneOffset && note.time < songPos + safeZoneOffset);

				if (note.time < songPos - safeZoneOffset && !note.wasGoodHit && !note.tooLate) {
					noteMiss(note);
				}

				if (note.isSustainNote && note.canBeHit && !note.tooLate) {
					if (note.parentNote != null && note.parentNote.wasGoodHit) {
						if (isHolding[note.noteData] && note.time <= songPos) {
							goodHit(note);
						} else if (!isHolding[note.noteData] && note.time < songPos - safeZoneOffset) {
							noteMiss(note);
						}
					}
				}
			} else {
				if (note.time <= songPos && !note.wasGoodHit) {
					goodHit(note);
				}
			}

			// Visual Clipping (Still Buggy)
			if (note.isSustainNote) {
				var isBeingHeld = note.mustPress && isHolding[note.noteData] && note.parentNote != null && note.parentNote.wasGoodHit;
				var opponentHit = !note.mustPress && vTime < songPos;

				if (note.wasGoodHit || isBeingHeld || opponentHit) {
					var clipY = (songPos - vTime) * speedMult + 70;
					if (clipY > 0) {
						if (clipY < note.height) {
							note.clipRect = new Rectangle(0, clipY, note.width, note.height - clipY);
						} else {
							note.clipRect = null;

							if (note.mustPress && isBeingHeld && !note.wasGoodHit) {
								goodHit(note);
							} else if (!note.mustPress) {
								var susieAnim = "down";
								susie.customOffset.y = 0;
								susie.customOffset.x = 0;
								switch (note.noteData) {
									case 0:
										susieAnim = "left";
										susie.customOffset.y = 2;
									case 1:
										susieAnim = "down";
									case 2:
										susieAnim = "down";
									case 3:
										susieAnim = "right";
										susie.customOffset.y = 2;
								}

								susie.play(susieAnim);
							}

							note.kill();
						}
					}
				} else if (note.clipRect != null) {
					note.clipRect = null;
				}
			}

			if (note.time < songPos - 300 && note.tooLate) {
				note.kill();
			}
		}

		for (dir in 0...4) {
			if (justPressed[dir]) {
				strumGlowTimers[dir + 4] = 0.15;

				var possibleHits:Array<RhythmNote> = [];
				for (note in allNotes.members) {
					if (note != null && note.alive && note.mustPress && note.canBeHit && !note.wasGoodHit && !note.isSustainNote && note.noteData == dir) {
						possibleHits.push(note);
					}
				}
				if (possibleHits.length > 0) {
					possibleHits.sort(function(a, b) return Std.int(a.time - b.time));
					goodHit(possibleHits[0]);
				}
			} else if (isHolding[dir]) {
				if (strumGlowTimers[dir + 4] < 0.05) {
					strumGlowTimers[dir + 4] = 0.05;
				}
			}
		}

		for (i in 0...8) {
			var s = (i >= 4) ? playerStrums[i - 4] : opponentStrums[i];
			if (strumGlowTimers[i] > 0) {
				strumGlowTimers[i] -= elapsed;
				s.color = noteColors[i % 4];
				s.alpha = 1.0;
			} else {
				s.color = 0xFF555555;
				s.alpha = 0.6;
			}
		}

		if (Controls.CANCEL) {
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			if (vocals != null)
				vocals.stop();
			kris.visible = false;
			susie.visible = false;
			close();
			Discord.updatePresence("RPC Test", "Lily Engine v0.1.0 Alpha");
			FlxG.state.persistentUpdate = false;
		}
	}

	function destroy() {
		if (bg != null)
			bg.destroy();
		if (vocals != null)
			vocals.destroy();
		RoomProps.music.resume();
	}
}
