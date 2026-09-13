/**
 * This script allows to use SimpleAnimatedSprite on Script Object.
 * Works with static calls.
 **/
class StaticSimpleAnimatedSprite {
    public var FPS:Float = 4.0;
    public var Playing:Bool = false;
    public var Loop:Bool = true;
    public var LoopFrame:Int = 0;
    public var Autostart:Bool = true;
    public var AnimationFrames:String = "";

    var _timeAccumulator:Float = 0.0;
    var _frameDuration:Float = 0.25;
    var _animationFrame:Int = 0;
    var _framesToUse:Array<Int> = [];
    var _canPlay:Bool = false;
    var object:Dynamic;

    public function onRoomLoaded(roomName:String) {
        if (Autostart) Playing = true;
        UpdateValues();
    }

    public function UpdateValues() {
        _canPlay = false;
        _framesToUse = [];

        if (AnimationFrames != null && AnimationFrames != "") {
            var splitted = AnimationFrames.split(",");
            for (s in splitted) {
                var fStr = StringTools.trim(s);
                if (fStr != "") _framesToUse.push(Std.parseInt(fStr));
            }
        } else {
            if (obj != null) {
                var total = obj.hFrames * obj.vFrames;
                for (i in 0...total) {
                    _framesToUse.push(i);
                }
            }
        }

        _frameDuration = 1.0 / FPS;
        _animationFrame = 0;
        
        if (_framesToUse.length > 0 && obj != null) {
            obj.Frame = _framesToUse[_animationFrame];
        }
        
        _canPlay = true;
    }

    public function update(elapsed:Float) {
        if (!_canPlay || !Playing || obj == null || !obj.visible || _framesToUse.length == 0) return;
        
        _timeAccumulator += elapsed;
        
        if (_timeAccumulator >= _frameDuration) {
            _timeAccumulator -= _frameDuration;
            _animationFrame++;
            
            if (_animationFrame >= _framesToUse.length) {
                _animationFrame = LoopFrame;
                if (!Loop) {
                    _animationFrame = 0;
                    Playing = false;
                    return;
                }
            }
            
            obj.Frame = _framesToUse[_animationFrame];
        }
    }

    public function Play() {
        Playing = true;
    }

    public function Stop() {
        Playing = false;
    }
}