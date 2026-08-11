function onUse() {
    FlxG.state.subState.close();
    var hiro = room.getNode('Main/HiroNpc');
    if (player.overlaps(hiro))
        trace('fucked');
}