package engine.backend.parser;

import openfl.utils.Assets;
import haxe.Json;
import engine.backend.Game;

class LacieEventReader {
    public static function readEventFile(assetPath:String):Dynamic {
        if (!Assets.exists(assetPath)) {
            trace("Event asset not found: " + assetPath);
            return null;
        }

        var rawContent:String = Assets.getText(assetPath);
        if (rawContent == null) {
            trace("Failed to read asset text or file is empty: " + assetPath);
            return null;
        }

        try {
            var parsedData:Dynamic = Json.parse(rawContent);
            parseDialogue(parsedData);
            return parsedData;
        } catch (e:Dynamic) {
            trace("Failed to parse JSON for asset " + assetPath + ": " + e);
            return null;
        }
    }

    public static function readRoomEvents(roomName:String):Dynamic {
        var assetPath = "data/rooms/" + roomName + "/event.json";
        return readEventFile(assetPath);
    }

    private static function parseDialogue(eventData:Dynamic):Void {
        if (eventData == null || eventData.Dialogue == null) return;

        for (cmd in (eventData.Dialogue : Array<Dynamic>)) {
            var raw:String = cmd.RawCommand;
            
            // Null command check (e.g. closing blocks or empty structural lines)
            if (raw == null) {
                continue;
            }

            if (raw.startsWith("label ")) {
                var labelName:String = cmd.Label;
                // Label execution logic
            } else if (raw.startsWith("chara lock")) {
                Game.party[0].canMove = false;
            } else if (raw.startsWith("hide ui")) {
                // Hide UI logic
            } else if (raw.startsWith("pause ")) {
                var pauseTime:Float = cmd.Time != null ? cmd.Time : 0;
                // Pause execution logic
            } else if (raw.startsWith("choice ")) {
                var choicePrompt:String = cmd.Text;
                var choices:Array<Dynamic> = cmd.Choices;
                // Choice menu display logic
            } else if (raw.startsWith("set ")) {
                if (cmd.Variable != null && cmd.Value != null) {
                    Game.save.setVariable(cmd.Variable, cmd.Value);
                }
            } else if (raw.startsWith("system achievement ")) {
                var achievementId:String = cmd.Value;
                // Achievement unlock logic
            } else if (raw.startsWith("if var ")) {
                var varName:String = cmd.Variable;
                var expectedVal:Dynamic = cmd.Value;
                var currentVal:Dynamic = Game.save.getVariable(varName);
                // Conditional branch evaluation logic
            } else if (raw.startsWith("fade out")) {
                var fadeTime:Float = cmd.Time != null ? cmd.Time : 0;
                // Screen fade out logic
            } else {
                // Regular dialogue line or speaker text assignment
                if (cmd.Text != null) {
                    var speaker:String = cmd.Who != null ? cmd.Who : "";
                    var dialogueText:String = cmd.Text;
                    trace("[" + speaker + "]: " + dialogueText);
                }
            }
        }
    }
}