class SimpleAnimatedSpriteV2 {
    public var Playing(default, set):Bool = false;
    public var Loop:Bool = true;
    public var Autostart:Bool = true;
    public var FrameDurations(default, set):String = "";

    var _timeAccumulator:Float = 0.0;
    var _frameDuration:Float = 0.1;
    var _animationFrame:Int = 0;
    var _frameDurations:Array<Float> = [];
    var _canPlay:Bool = false;
    public var onFinished:Void->Void = function() {};

    function set_Playing(value:Bool):Bool {
        Playing = value;
        UpdateValues();
        return value;
    }

    function set_FrameDurations(value:String):String {
        UpdateFrameDurations(value);
        return value;
    }

    public function onRoomLoaded(roomName:String) {
        if (Autostart) {
            Playing = true;
        }
        UpdateValues();
    }

    private function UpdateFrameDurations(value:String) {
        _frameDurations = [];
        if (value != null && value != "") {
            var splitted = value.split(",");
            for (s in splitted) {
                var fStr = StringTools.trim(s);
                if (fStr != "") {
                    var parsed = Std.parseFloat(fStr);
                    // Convert milliseconds to seconds (e.g. 100ms -> 0.1s)
                    _frameDurations.push(parsed / 1000.0);
                }
            }
        }
        UpdateValues();
    }

    public function UpdateValues() {
        _canPlay = false;

        var totalFrames = 0;
        if (obj != null) {
            totalFrames = obj.hFrames * obj.vFrames;
        }

        if (_frameDurations.length != totalFrames) {
            var fixedDurations:Array<Float> = [];
            for (i in 0...totalFrames) {
                fixedDurations.push(0.1); // Default frame duration fallback
            }
            for (i in 0..._frameDurations.length) {
                if (i < fixedDurations.length) {
                    fixedDurations[i] = _frameDurations[i];
                }
            }
            _frameDurations = fixedDurations;
        }

        _animationFrame = 0;
        if (_frameDurations.length > 0) {
            _frameDuration = _frameDurations[_animationFrame];
        }

        if (_frameDurations.length > 0 && obj != null) {
            obj.Frame = _animationFrame;
        }

        _canPlay = true;
    }

    public function update(elapsed:Float) {
        if (!_canPlay || !Playing || obj == null || !obj.visible || _frameDurations.length == 0) return;

        _timeAccumulator += elapsed;
        _frameDuration = _frameDurations[_animationFrame];

        // Catch-up loop to handle game lag smoothly
        while (_timeAccumulator >= _frameDuration) {
            _timeAccumulator -= _frameDuration;
            _animationFrame++;

            if (_animationFrame >= _frameDurations.length) {
                _animationFrame = 0;
                if (!Loop) {
                    onFinished();
                    Playing = false;
                    break;
                }
            }

            _frameDuration = _frameDurations[_animationFrame];
            obj.Frame = _animationFrame;
        }
    }

    public function Play() {
        Playing = true;
    }

    public function Stop() {
        Playing = false;
    }
}