import openfl.utils.Assets;

class test_all {
    var newBG:FlxSprite = new FlxSprite(-260, -260);
	function onOpen(evt) {
    }
	function onTextStart(evt) {}
	function onSelectionOpen(evt) {
        selectionMenu.remove(selectionMenu.menuFrame);
        
        newBG.loadGraphic("images/rooms/DebugRoom/box1.jpg"); // Loading Assets from String.
        newBG.antialiasing = true;
		newBG.scale.set(0.8, 0.8);
        insert(0, newBG);
    }
	function onOptionSelected(evt) {}
	function onClose(evt) {}
	function onClosePost(evt) {}
	function onOpenPost(evt) {}
	function onCharTyped(evt) {}
	function onCharTypedPost(num) {}
	function onSkip(evt) {}
	function onSkipPost(evt) {}
	function onConfirm(evt) {}
	function onConfirmPost(evt) {}
	function onTextComplete(evt) {}
	function onTextCompletePost(evt) {}
	function onSelectionOpenPost(opts) {}
	function onSelectionClose(evt) {}
	function onSelectionClosePost(evt) {}
	function onOptionSelectedPost(idx, id) {}
}
