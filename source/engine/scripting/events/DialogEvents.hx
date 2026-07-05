package engine.scripting.events;

final class DialogJumpEvent extends CancellableEvent {
    public var dialogId:String;
}

final class DialogEntryEvent extends CancellableEvent {
    public var entry:Dynamic;
    public var text:String;
}

final class DialogSelectionEvent extends CancellableEvent {
    public var selections:Array<Dynamic>;
}