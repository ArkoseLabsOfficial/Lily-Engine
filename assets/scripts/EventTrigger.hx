class EventTrigger {
	public var triggers:Map<String, String->Array<String>->Void> = [];

	public var _directions:Int = 0;
	public var _enabled:Bool = true;
	public var _event:String = "";
	public var _args:String = "";
	public var _solid:Bool = true;
	public var _trigger:Int = 0;

	public var triggerDirections(get, set):Int;

	function get_triggerDirections():String
		return _directions;

	function set_triggerDirections(v:String):String
		return _directions = v;

	public var triggerEnabled(get, set):Bool;

	function get_triggerEnabled():String
		return _enabled;

	function set_triggerEnabled(v:String):String
		return _enabled = v;

	public var triggerEvent(get, set):String;

	function get_triggerEvent():String
		return _event;

	function set_triggerEvent(v:String):String
		return _event = v;

	public var triggerArgs(get, set):String;

	function get_triggerArgs():String
		return _args;

	function set_triggerArgs(v:String):String
		return _args = v;

	public var triggerSolid(get, set):Bool;

	function get_triggerSolid():Bool
		return _solid;

	function set_triggerSolid(v:Bool):Bool
		return _solid = v;

	public var triggerTrigger(get, set):Int;

	function get_triggerTrigger():Int
		return _trigger;

	function set_triggerTrigger(v:Int):Int
		return _trigger = v;

	function add(obj) {
		parent.add(obj);
	}
}
