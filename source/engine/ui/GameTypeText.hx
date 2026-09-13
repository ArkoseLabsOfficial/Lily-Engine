package engine.ui;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import openfl.media.Sound;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;

#if !flash
@:sound("assets/sounds/type.ogg")
class TypeSound extends Sound {}
#else
@:sound("assets/sounds/type.wav")
class TypeSound extends Sound {}
#end


/**
 * Why?... Why Not?.
 * KralOyuncu.
  **/
class GameTypeText extends GameText {
	public var delay:Float = 0.05;
	public var eraseDelay:Float = 0.02;
	public var showCursor:Bool = false;
	public var cursorCharacter:String = "|";
	public var cursorBlinkSpeed:Float = 0.5;
	public var prefix:String = "";
	public var autoErase:Bool = false;
	public var waitTime:Float = 1.0;
	public var paused:Bool = false;

	public var sounds:Array<FlxSound>;
	public var useDefaultSound:Bool = false;
	public var finishSounds = false;

	public var skipKeys:Array<FlxKey> = [];

	public var completeCallback:Void->Void;
	public var eraseCallback:Void->Void;

	var _finalText:String = "";
	var _timer:Float = 0.0;
	var _waitTimer:Float = 0.0;
	var _length:Int = 0;
	var _typing:Bool = false;
	var _erasing:Bool = false;
	var _waiting:Bool = false;
	var _cursorTimer:Float = 0.0;
	var _typingVariation:Bool = false;
	var _typeVarPercent:Float = 0.5;

	static var helperString:String = "";

	var _sound:FlxSound;

	public function new(X:Float = 0, Y:Float = 0, Text:String = "", Size:Int = 16, ?Font:String) {
		super(X, Y, "", Size, Font);
		_finalText = Text;
	}

	override public function update(elapsed:Float):Void {
		#if FLX_KEYBOARD
		if (skipKeys != null && skipKeys.length > 0 && FlxG.keys.anyJustPressed(skipKeys)) {
			skip();
		}
		#end

		if (_waiting && !paused) {
			_waitTimer -= elapsed;
			if (_waitTimer <= 0) {
				_waiting = false;
				_erasing = true;
			}
		}

		if (!_waiting && !paused) {
			if (_length < _finalText.length && _typing)
				_timer += elapsed;
			if (_length > 0 && _erasing)
				_timer += elapsed;
		}

		if (_typing || _erasing) {
			if (_typing && _timer >= delay) {
				_length += Std.int(_timer / delay);
				if (_length > _finalText.length)
					_length = _finalText.length;
			}

			if (_erasing && _timer >= eraseDelay) {
				_length -= Std.int(_timer / eraseDelay);
				if (_length < 0)
					_length = 0;
			}

			if ((_typing && _timer >= delay) || (_erasing && _timer >= eraseDelay)) {
				if (_typingVariation) {
					if (_typing)
						_timer = FlxG.random.float(-delay * _typeVarPercent / 2, delay * _typeVarPercent / 2);
					else
						_timer = FlxG.random.float(-eraseDelay * _typeVarPercent / 2, eraseDelay * _typeVarPercent / 2);
				} else {
					_timer %= delay;
				}

				if (sounds != null && !useDefaultSound) {
					if (!finishSounds)
						for (sound in sounds)
							sound.stop();
					FlxG.random.getObject(sounds).play(!finishSounds);
				} else if (useDefaultSound && _sound != null) {
					_sound.play(!finishSounds);
				}
			}
		}

		helperString = prefix + _finalText.substr(0, _length);

		if (showCursor) {
			_cursorTimer += elapsed;
			var isBreakLine = (prefix + _finalText).charAt(helperString.length) == "\n";
			if (_cursorTimer > cursorBlinkSpeed / 2 && !isBreakLine)
				helperString += cursorCharacter.charAt(0);
			if (_cursorTimer > cursorBlinkSpeed)
				_cursorTimer = 0;
		}

		if (helperString != text) {
			text = helperString;

			if (_length >= _finalText.length && _typing && !_waiting && !_erasing)
				onComplete();
			if (_length == 0 && _erasing && !_typing && !_waiting)
				onErased();
		}

		super.update(elapsed);
	}

	override public function destroy():Void {
		_sound = null;
		super.destroy();
	}

	public function start(?Delay:Float, ForceRestart:Bool = false, AutoErase:Bool = false, ?SkipKeys:Array<FlxKey>, ?Callback:Void->Void):Void {
		if (Delay != null)
			delay = Delay;

		_typing = true;
		_erasing = false;
		paused = false;
		_waiting = false;

		if (ForceRestart) {
			text = "";
			_length = 0;
		}

		autoErase = AutoErase;
		if (SkipKeys != null)
			skipKeys = SkipKeys;
		if (Callback != null)
			completeCallback = Callback;

		insertBreakLines();

		if (useDefaultSound)
			loadDefaultSound();
	}

	public function erase(?Delay:Float, ForceRestart:Bool = false, ?SkipKeys:Array<FlxKey>, ?Callback:Void->Void):Void {
		_erasing = true;
		_typing = false;
		paused = false;
		_waiting = false;

		if (Delay != null)
			eraseDelay = Delay;

		if (ForceRestart) {
			_length = _finalText.length;
			text = _finalText;
		}

		if (SkipKeys != null)
			skipKeys = SkipKeys;
		eraseCallback = Callback;

		if (useDefaultSound)
			loadDefaultSound();
	}

	public function resetText(Text:String):Void {
		text = prefix;
		_finalText = Text;
		_typing = false;
		_erasing = false;
		paused = false;
		_waiting = false;
		_length = 0;
	}

	public function setTypingVariation(Amount:Float = 0.5, On:Bool = true):Void {
		_typingVariation = On;
		_typeVarPercent = FlxMath.bound(Amount, 0, 1);
	}

	public function skip():Void {
		if (_erasing || _waiting) {
			_length = 0;
			_waiting = false;
		} else if (_typing) {
			_length = _finalText.length;
		}
	}

	function insertBreakLines() {
		if (maxWidth <= 0 || !wordWrap)
			return;

		var last = _finalText.length;
		var n0:Int = 0;
		var n1:Int = 0;

		var field:TextField = new TextField();
		field.selectable = false;
		field.multiline = true;
		field.wordWrap = true;
		field.autoSize = TextFieldAutoSize.NONE;
		field.width = maxWidth;

		var fmt:TextFormat = new TextFormat();
		fmt.font = font;
		fmt.size = size;
		fmt.bold = bold;
		fmt.italic = italic;
		fmt.letterSpacing = letterSpacing;
		field.defaultTextFormat = fmt;
		field.embedFonts = embedFonts;

		var currentFinalText = _finalText;

		while (true) {
			last = currentFinalText.substr(0, last).lastIndexOf(" ");
			if (last <= 0)
				break;

			field.text = prefix + currentFinalText;
			field.setTextFormat(fmt);
			n0 = field.numLines;

			var nextText = currentFinalText.substr(0, last) + "\n" + currentFinalText.substr(last + 1);
			field.text = prefix + nextText;
			field.setTextFormat(fmt);
			n1 = field.numLines;

			if (n0 == n1) {
				currentFinalText = nextText;
			}
		}
		_finalText = currentFinalText;
	}

	function onComplete():Void {
		_timer = 0;
		_typing = false;

		if (useDefaultSound && _sound != null) {
			_sound.stop();
		} else if (sounds != null) {
			for (sound in sounds)
				sound.stop();
		}

		if (completeCallback != null)
			completeCallback();

		if (autoErase && waitTime <= 0) {
			_erasing = true;
		} else if (autoErase) {
			_waitTimer = waitTime;
			_waiting = true;
		}
	}

	function onErased():Void {
		_timer = 0;
		_erasing = false;
		if (eraseCallback != null)
			eraseCallback();
	}

	function loadDefaultSound():Void {
		if (_sound != null)
			return;
		#if FLX_SOUND_SYSTEM
		#if (flixel < version("6.2.0"))
		_sound = FlxG.sound.load(new TypeSound());
		#else
		_sound = FlxG.sound.create(new TypeSound());
		#end
		#else
		_sound = new FlxSound();
		#if (flixel < version("6.2.0"))
		_sound.loadEmbedded(new TypeSound());
		#else
		_sound.load(new TypeSound());
		#end
		#end
	}
}
