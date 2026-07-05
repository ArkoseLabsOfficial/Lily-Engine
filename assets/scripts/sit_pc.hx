import engine.backend.Objective;

// Ensure these variables are attached to the specific object instance 
// rather than being global to the entire script file.
var isSitting = false;
var savedPlayerX:Float = 0;
var savedPlayerY:Float = 0;

function onInteracted(name) {
    if (isSitting == true) return;
    // Only process if this specific object was interacted with
    switch(name) {
        case "trigger_sit_down":
            sit("sitDOWN");
            Objectives.complete("sitPC.sitDOWN");
        case "trigger_sit":
            sit("sitUP");
            Objectives.complete("sitPC.sitUP");
            changeLayer(player, "LowerObjects");
    }
}

function postUpdate(elapsed:Float) {
    // Check for cancel specifically when this instance is in a sitting state
    if (isSitting && Controls.CANCEL) {
        standUp();
    }
}

function sit(anim:String) {
    isSitting = true;
    savedPlayerX = player.x;
    savedPlayerY = player.y;
    
    lockPlayer(true);
    player.playAnim(anim, true);
    
    player.x = this.x + (anim == "sitUP" ? 10.5 : 12.5);
    player.y = this.y + (anim == "sitUP" ? 25 : 30);
}

function standUp() {
    changeLayer(player, "Player");
    player.x = savedPlayerX;
    player.y = savedPlayerY;
    lockPlayer(false);
    isSitting = false;
}