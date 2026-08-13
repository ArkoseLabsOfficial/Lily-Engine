class PartyShortcuts {
    public static function createPartyChar(name:String):Character {
        var character = new Character(0, 0, 0, name);
        character.solidCollision = false;
        character.loadEntity(name);
        var targetNode:Dynamic = Game.room.scene.getNode("Main");
        if (targetNode == null)
            targetNode = Game.room.scene.root;

        if (targetNode != null)
            targetNode.add(character);

        Game.party.push(character);
    }
}