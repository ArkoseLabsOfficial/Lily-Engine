import engine.objects.Character;
import engine.backend.Game;

class CharacterShortcuts {
    public var character:Character;

    public function createCharacter(name:String):Character {
        character = new Character(0, 0, 0, name);
        character.loadEntity(name);
        var targetNode:Dynamic = Game.room.scene.getNode("Main");
        if (targetNode == null)
            targetNode = Game.room.scene.root;

        if (targetNode != null)
            targetNode.add(character);
    }

    public function addAsFollower(mainChar:Dynamic) {
        Game.baseRoom.addFollower(character, mainChar);
    }

    public function removeAsFollower() {
        Game.baseRoom.removeFollower(character);
    }
}