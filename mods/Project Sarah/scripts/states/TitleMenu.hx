import Main;
import hxfilemanager.FileDialog;
import hxfilemanager.Model.DialogKind;
import openfl.ui.Mouse;
import Sys;

importScript("GameProperties");

function create() {
	/*
	Main.fileDialog.open(DialogKind.PickFile, {
		title: "Open",
		primaryLabel: "Open",
		filters: [
			{label: "All Files", exts: []},
			{label: "Images (*.png *.jpg *.jpeg *.bmp)", exts: ["png", "jpg", "jpeg", "bmp"]},
			{label: "PNG (*.png)", exts: ["png"]},
			{label: "JPEG (*.jpg *.jpeg)", exts: ["jpg", "jpeg"]}
		],
		startPath: Sys.getCwd(),
		thumbnails: true
	});

	Main.fileDialog.onConfirm.clear();
	Main.fileDialog.onConfirm.add(function(p:String, f:Dynamic) {
		trace('Path: $p | Filter: $f');
		bg.loadGraphic(p);
	});
	Main.fileDialog.onCancel.clear();
	Main.fileDialog.onCancel.add(function() {
		trace('Dialog Cancelled');
	});
	*/
}

public function onStartingNewGame() {
	GameProperties.reset();
}
