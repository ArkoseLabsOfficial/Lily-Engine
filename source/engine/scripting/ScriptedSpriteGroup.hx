package engine.scripting;

@:noOverride("multiTransformChildren", "transformChildren")
class ScriptedSpriteGroup extends FlxSpriteGroup {
    public function compileFix() {
        trace("class compiled");
    }
}