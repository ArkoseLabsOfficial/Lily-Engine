class EventTrigger {
	public var triggers:Map<String, String->Array<String>->Void> = [];
	public var Enabled:Bool = true;
    // (Left=1, Up=2, Right=4, Down=8) and use if you wanna use both thing use something like (4 + 8 = 12 is a right-down for example).
	public var Directions:Int = 0;

    public var _event:String = "";
    public var _solid:Bool = true;
    public var _trigger:Int = 0;

    public var Event(get, set):String;
    function get_Event():String return _event;
    function set_Event(v:String):String return _event = v;

    public var Solid(get, set):Bool;
    function get_Solid():Bool return _solid;
    function set_Solid(v:Bool):Bool return _solid = v;

    public var Trigger(get, set):Int;
    function get_Trigger():Int return _trigger;
    function set_Trigger(v:Int):Int return _trigger = v;
}
