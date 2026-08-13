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

final class DialogCharTypedEvent extends CancellableEvent {
    public var preTextCharNum:Int;
    public var nextTextCharNum:Int;
}

final class DialogOptionSelectedEvent extends CancellableEvent {
    public var index:Int;
    public var optionId:String;
}