package engine.ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class GameCamera extends FlxCamera {
    public function new(X:Float = 0, Y:Float = 0, Width:Int = 0, Height:Int = 0, Zoom:Float = 0) {
        super(X, Y, Width, Height, Zoom);
        this.pixelPerfectRender = true;
        this.antialiasing = false;
    }

    override public function updateFollow():Void {
        if (target == null) return;

        if (deadzone == null) {
            target.getMidpoint(_point);
            _point.addPoint(targetOffset);
            _scrollTarget.set(_point.x - (width / zoom) * 0.5, _point.y - (height / zoom) * 0.5);
        } else {
            var targetX:Float = target.x + targetOffset.x;
            var targetY:Float = target.y + targetOffset.y;

            if (style == SCREEN_BY_SCREEN) {
                if (targetX >= viewRight) {
                    _scrollTarget.x += viewWidth;
                } else if (targetX + target.width < viewLeft) {
                    _scrollTarget.x -= viewWidth;
                }

                if (targetY >= viewBottom) {
                    _scrollTarget.y += viewHeight;
                } else if (targetY + target.height < viewTop) {
                    _scrollTarget.y -= viewHeight;
                }
                bindScrollPos(_scrollTarget);
            } else {
                var edge:Float;
                edge = targetX - deadzone.x;
                if (_scrollTarget.x > edge) _scrollTarget.x = edge;
                
                edge = targetX + target.width - deadzone.x - deadzone.width;
                if (_scrollTarget.x < edge) _scrollTarget.x = edge;

                edge = targetY - deadzone.y;
                if (_scrollTarget.y > edge) _scrollTarget.y = edge;
                
                edge = targetY + target.height - deadzone.y - deadzone.height;
                if (_scrollTarget.y < edge) _scrollTarget.y = edge;
            }

            if ((target is FlxSprite)) {
                if (_lastTargetPosition == null) {
                    _lastTargetPosition = FlxPoint.get(target.x, target.y);
                }
                _scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
                _scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

                _lastTargetPosition.x = target.x;
                _lastTargetPosition.y = target.y;
            }
        }

        if (followLerp >= 60 / FlxG.updateFramerate) {
            scroll.x = Math.round(_scrollTarget.x);
            scroll.y = Math.round(_scrollTarget.y);
        } else {
            var lerpVal = 1 - Math.exp(-(followLerp * 20) * FlxG.elapsed);
            if (lerpVal > 1) lerpVal = 1;

            scroll.x += (_scrollTarget.x - scroll.x) * lerpVal;
            scroll.y += (_scrollTarget.y - scroll.y) * lerpVal;
            scroll.set(Math.round(scroll.x), Math.round(scroll.y));
        }
    }
}