import engine.backend.Game;

public var location:String = "Unknown";
public var party:Array<String> = [];
public var BGMusic:String = "";

public function onRoomLoaded():Void {
    Game.save.location = location;
    //followPath2D("StartPath/Start", room.player, 150);
    if (BGMusic != "" && BGMusic != null)
        LilyAssets.play('bgm/$BGMusic');

    Game.objectives.addObjective("main_investigation");
    Game.objectives.failObjective("main_investigation.explore_hall.open_drawer");
}