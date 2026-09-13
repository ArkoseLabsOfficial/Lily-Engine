import flixel.util.FlxTimer;

class FakeASync {
    public var waitCalled:Bool = false;
    public var nextTask:Void->Void = null;

    public function new() {}

    public function await(tasks:Array<(Float->Void)->Void>):Void {
        start(tasks);
    }

    public function start(tasks:Array<(Float->Void)->Void>):Void {
        var index = 0;
        var myTasks = tasks;

        var wait = function(seconds:Float):Void {
            waitCalled = true;
            new FlxTimer().start(seconds, function(timer:FlxTimer) {
                nextTask();
            });
        };

        nextTask = function() {
            if (index >= myTasks.length) {
                return;
            }
            waitCalled = false;
            var task = myTasks[index++];
            task(wait);
            if (!waitCalled) {
                nextTask();
            }
        };

        nextTask();
    }
}