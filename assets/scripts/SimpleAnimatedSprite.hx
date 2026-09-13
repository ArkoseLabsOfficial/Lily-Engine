class SimpleAnimatedSprite {
	public var fps:Float = 4.0;
	public var playing:Bool = false;
	public var loop:Bool = true;
	public var loopFrame:Int = 0;
	public var autostart:Bool = true;
	public var animationFrames:String = "";

	var endFrame:Int = -1;
	var _timeAccumulator:Float = 0.0;
	var _frameDuration:Float = 0.25;
	var _animationFrame:Int = 0;
	var _framesToUse:Array<Int> = [];
	var _canPlay:Bool = false;

	public var onFinished:Void->Void = function() {};

	public function onRoomLoaded(roomName:String) {
		if (autostart)
			playing = true;
		UpdateValues();
	}

	public function UpdateValues() {
		_canPlay = false;
		_framesToUse = [];

		if (animationFrames != null && animationFrames != "") {
			var splitted = animationFrames.split(",");
			for (s in splitted) {
				var fStr = StringTools.trim(s);
				if (fStr != "")
					_framesToUse.push(Std.parseInt(fStr));
			}
		} else {
			if (obj != null) {
				var total = obj.hFrames * obj.vFrames;
				for (i in 0...total) {
					_framesToUse.push(i);
				}
			}
		}

		_frameDuration = 1.0 / fps;
		_animationFrame = 0;

		if (_framesToUse.length > 0 && obj != null) {
			obj.Frame = _framesToUse[_animationFrame];
		}

		_canPlay = true;
	}

	public function update(elapsed:Float) {
		if (!_canPlay || !playing || obj == null || !obj.visible || _framesToUse.length == 0)
			return;

		_timeAccumulator += elapsed;

		if (_timeAccumulator >= _frameDuration) {
			_timeAccumulator -= _frameDuration;
			_animationFrame++;

			if (_animationFrame == endFrame) {
				_animationFrame = loopFrame;
				if (!loop) {
					onFinished();
					_animationFrame = 0;
					playing = false;
					return;
				}
			}

			if (_animationFrame >= _framesToUse.length) {
				_animationFrame = loopFrame;
				if (!loop) {
					onFinished();
					_animationFrame = 0;
					playing = false;
					return;
				}
			}

			obj.Frame = _framesToUse[_animationFrame];
		}
	}

	public function Play() {
		playing = true;
	}

	public function Stop() {
		playing = false;
	}
}
