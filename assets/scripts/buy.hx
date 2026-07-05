function onInteracted(name) {
    trace("helo");
    trace(name);
    if (name == "Cashier_Trigger")
        openBuyDialog();        
}

function openBuyDialog() {
    playDialogue("dialog1", "start");
}