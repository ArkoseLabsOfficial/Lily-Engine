import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxCamera;
import openfl.geom.Rectangle;
import flixel.math.FlxMath;
import sys.FileSystem;
import engine.backend.Discord;
import engine.backend.Game;

importScript("RoomProps");
importScript("JsonParser");

using StringTools;

class SongSelectorMenu {
    var camMenu:FlxCamera;

    var bg:FlxSprite;
    var windowBg:FlxSprite;
    var sidePanelBg:FlxSprite;
    var closeBtn:FlxSprite;
    var closeTxt:FlxText;
    
    var startBtn:FlxSprite;
    var startTxt:FlxText;

    var searchBox:FlxSprite;
    var searchTxt:FlxText;
    var searchText:String = "";
    var isSearchFocused:Bool = false;
    var cursorTimer:Float = 0;
    var showCursor:Bool = false;

    var songGrp:FlxTypedGroup<FlxSprite>;
    var songTextGrp:FlxTypedGroup<FlxText>;
    var songBadgeGrp:FlxTypedGroup<FlxSprite>;
    
    var chartGrp:FlxTypedGroup<FlxSprite>;
    var chartTextGrp:FlxTypedGroup<FlxText>;
    var chartBadgeGrp:FlxTypedGroup<FlxSprite>;

    var allSongs:Array<String> = [];
    var filteredSongs:Array<String> = [];
    var currentCharts:Array<String> = [];
    
    var curSongIndex:Int = -1;
    var curChartIndex:Int = 0;

    var songHitboxes:Array<FlxSprite> = [];
    var chartHitboxes:Array<FlxSprite> = [];

    var scrollY:Float = 0;
    var maxScrollY:Float = 0;
    var targetScrollY:Float = 0;

    function create() {
        Discord.updatePresence("In Menus", "Selecting a Song");
        
        FlxG.mouse.visible = true;

        if (Reflect.hasField(FlxG, "cameras") && FlxG.cameras.list != null) {
            camMenu = new FlxCamera();
            camMenu.bgColor = 0x00000000;
            FlxG.cameras.add(camMenu, false);
        }

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
        setupCamera(bg);
        add(bg);

        windowBg = new FlxSprite(100, 50).makeGraphic(1720, 980, 0xFF141218);
        setupCamera(windowBg);
        add(windowBg);

        sidePanelBg = new FlxSprite(1080, 140).makeGraphic(710, 860, 0xFF211F26);
        setupCamera(sidePanelBg);
        add(sidePanelBg);

        var headerTxt = new FlxText(140, 70, 450, "Song Selector", 36);
        headerTxt.setFormat(Flags.fontFolder + "vcr.ttf", 36, 0xFFE6E1E5, "left");
        setupCamera(headerTxt);
        add(headerTxt);

        var subHeader = new FlxText(140, 115, 450, "Select a track to play", 16);
        subHeader.setFormat(Flags.fontFolder + "vcr.ttf", 16, 0xFFCAC4D0, "left");
        setupCamera(subHeader);
        add(subHeader);

        closeBtn = new FlxSprite(1730, 65).makeGraphic(60, 60, 0xFF601410);
        closeBtn.pixels.fillRect(new Rectangle(2, 2, 56, 56), 0xFF8C1D18);
        setupCamera(closeBtn);
        add(closeBtn);
        
        closeTxt = new FlxText(1730, 78, 60, "✕", 24);
        closeTxt.setFormat(Flags.fontFolder + "vcr.ttf", 24, 0xFFF2B8B5, "center");
        setupCamera(closeTxt);
        add(closeTxt);

        searchBox = new FlxSprite(600, 65);
        setupCamera(searchBox);
        add(searchBox);
        
        searchTxt = new FlxText(620, 80, 420, "Search songs...", 20);
        searchTxt.setFormat(Flags.fontFolder + "vcr.ttf", 20, 0xFF938F99, "left");
        setupCamera(searchTxt);
        add(searchTxt);

        startBtn = new FlxSprite(1110, 890).makeGraphic(650, 80, 0xFF6750A4);
        setupCamera(startBtn);
        add(startBtn);
        
        startTxt = new FlxText(1110, 912, 650, "PLAY SONG", 30);
        startTxt.setFormat(Flags.fontFolder + "vcr.ttf", 30, 0xFFFFFFFF, "center");
        setupCamera(startTxt);
        add(startTxt);

        var chartPanelHeader = new FlxText(1110, 160, 650, "Difficulty Charts", 24);
        chartPanelHeader.setFormat(Flags.fontFolder + "vcr.ttf", 24, 0xFFE6E1E5, "left");
        setupCamera(chartPanelHeader);
        add(chartPanelHeader);

        songGrp = new FlxTypedGroup();
        add(songGrp);
        songTextGrp = new FlxTypedGroup();
        add(songTextGrp);
        songBadgeGrp = new FlxTypedGroup();
        add(songBadgeGrp);

        chartGrp = new FlxTypedGroup();
        add(chartGrp);
        chartTextGrp = new FlxTypedGroup();
        add(chartTextGrp);
        chartBadgeGrp = new FlxTypedGroup();
        add(chartBadgeGrp);

        loadSongs();
        filterSongs();
        drawSearchBox();

        windowBg.alpha = 0;
        sidePanelBg.alpha = 0;
        FlxTween.tween(windowBg, {alpha: 1}, 0.2, {ease: FlxEase.quadOut});
        FlxTween.tween(sidePanelBg, {alpha: 1}, 0.2, {ease: FlxEase.quadOut});
    }

    function setupCamera(obj:Dynamic) {
        if (camMenu != null && Reflect.hasField(obj, "cameras")) {
            obj.cameras = [camMenu];
        }
    }

    function drawSearchBox() {
        var w = 450;
        var h = 55;
        var borderColor = isSearchFocused ? 0xFFD0BCFF : 0xFF49454F;
        var borderThickness = isSearchFocused ? 3 : 1;
        var fillColor = isSearchFocused ? 0xFF2B2930 : 0xFF1D1B20;

        searchBox.makeGraphic(w, h, borderColor);
        searchBox.pixels.fillRect(new Rectangle(borderThickness, borderThickness, w - (borderThickness * 2), h - (borderThickness * 2)), fillColor);
        updateSearchTextDisplay();
    }

    function updateSearchTextDisplay() {
        if (searchText == "" && !isSearchFocused) {
            searchTxt.text = "Search songs...";
            searchTxt.color = 0xFF938F99;
        } else {
            var cursor = (isSearchFocused && showCursor) ? "|" : "";
            searchTxt.text = searchText + cursor;
            searchTxt.color = 0xFFE6E1E5;
        }
    }

    function loadSongs() {
        allSongs = [];
        if (Assets.exists("songs/")) {
            var folders = Assets.readDirectory("songs/");
            for (folder in folders) {
                if (Assets.isDirectory("songs/" + folder)) {
                    allSongs.push(folder);
                }
            }
        }
    }

    function filterSongs() {
        filteredSongs = [];
        for (song in allSongs) {
            if (searchText == "" || song.toLowerCase().indexOf(searchText.toLowerCase()) != -1) {
                filteredSongs.push(song);
            }
        }
        
        curSongIndex = filteredSongs.length > 0 ? 0 : -1;
        scrollY = 0;
        targetScrollY = 0;

        if (curSongIndex != -1) {
            loadChartsForSong(filteredSongs[curSongIndex]);
        } else {
            currentCharts = [];
        }
        
        drawUI();
    }

    function loadChartsForSong(songName:String) {
        currentCharts = [];
        curChartIndex = 0;
        
        var chartPath = "songs/" + songName + "/charts/";
        if (Assets.exists(chartPath)) {
            var files = Assets.readDirectory(chartPath);
            for (file in files) {
                if (StringTools.endsWith(file, ".json")) {
                    currentCharts.push(file);
                }
            }
        }
    }

    function drawUI() {
        songGrp.clear();
        songTextGrp.clear();
        songBadgeGrp.clear();
        songHitboxes = [];

        var columns = 3;
        var cardW = 280;
        var cardH = 120;
        var paddingX = 300;
        var paddingY = 140;
        var startX = 140;
        var startY = 160;

        var totalRows = Math.ceil(filteredSongs.length / columns);
        var totalHeight = totalRows * paddingY;
        maxScrollY = Math.max(0, totalHeight - 750);

        for (i in 0...filteredSongs.length) {
            var col = i % columns;
            var row = Math.floor(i / columns);

            var bx = startX + (col * paddingX);
            var by = startY + (row * paddingY) - scrollY;

            if (by + cardH < 140 || by > 980) continue;

            var isSelected = (i == curSongIndex);
            
            var cardBg = isSelected ? 0xFF381E72 : 0xFF2B2930;
            var cardBorder = isSelected ? 0xFFD0BCFF : 0xFF49454F;

            var box = new FlxSprite(bx, by).makeGraphic(cardW, cardH, cardBorder);
            box.pixels.fillRect(new Rectangle(2, 2, cardW - 4, cardH - 4), cardBg);
            setupCamera(box);
            songGrp.add(box);
            songHitboxes.push(box);

            var avatarBg = isSelected ? 0xFFD0BCFF : 0xFF4A4458;
            var avatarTextCol = isSelected ? 0xFF381E72 : 0xFFE8DEF8;

            var avatar = new FlxSprite(bx + 16, by + 18).makeGraphic(50, 50, avatarBg);
            setupCamera(avatar);
            songBadgeGrp.add(avatar);

            var initial = filteredSongs[i].substring(0, 1).toUpperCase();
            var badgeTxt = new FlxText(bx + 16, by + 28, 50, initial, 24);
            badgeTxt.setFormat(Flags.fontFolder + "vcr.ttf", 24, avatarTextCol, "center");
            setupCamera(badgeTxt);
            songTextGrp.add(badgeTxt);

            var label = filteredSongs[i];
            if (label.length > 13) label = label.substring(0, 11) + "..";

            var txt = new FlxText(bx + 80, by + 22, 180, label, 22);
            txt.setFormat(Flags.fontFolder + "vcr.ttf", 22, isSelected ? 0xFFEADDFF : 0xFFE6E1E5, "left");
            setupCamera(txt);
            songTextGrp.add(txt);

            var subTxt = new FlxText(bx + 80, by + 52, 180, "Track #" + (i + 1), 15);
            subTxt.setFormat(Flags.fontFolder + "vcr.ttf", 15, isSelected ? 0xFFD0BCFF : 0xFF938F99, "left");
            setupCamera(subTxt);
            songTextGrp.add(subTxt);
        }

        chartGrp.clear();
        chartTextGrp.clear();
        chartBadgeGrp.clear();
        chartHitboxes = [];

        var cStartY = 210;
        for (i in 0...currentCharts.length) {
            var isSelected = (i == curChartIndex);
            var cName = currentCharts[i].replace(".json", "").toUpperCase();

            var chipFill = 0xFF1D1B20;
            var chipText = 0xFFE6E1E5;

            if (cName.indexOf("EASY") != -1) {
                chipFill = 0xFF1B5E20; chipText = 0xFF81C784;
            } else if (cName.indexOf("HARD") != -1) {
                chipFill = 0xFFE65100; chipText = 0xFFFFB74D;
            } else if (cName.indexOf("EXPERT") != -1 || cName.indexOf("EXTREME") != -1) {
                chipFill = 0xFF4A148C; chipText = 0xFFE1BEE7;
            } else {
                chipFill = 0xFF0D47A1; chipText = 0xFF90CAF9;
            }

            var boxBg = isSelected ? 0xFF36343B : 0xFF1D1B20;
            var borderBg = isSelected ? 0xFFD0BCFF : 0xFF49454F;

            var box = new FlxSprite(1110, cStartY + (i * 90)).makeGraphic(650, 75, borderBg);
            box.pixels.fillRect(new Rectangle(2, 2, 646, 71), boxBg);
            setupCamera(box);
            chartGrp.add(box);
            chartHitboxes.push(box);

            var chip = new FlxSprite(1125, cStartY + 20 + (i * 90)).makeGraphic(120, 35, chipFill);
            setupCamera(chip);
            chartBadgeGrp.add(chip);

            var chipTxt = new FlxText(1125, cStartY + 28 + (i * 90), 120, "DIFF", 14);
            chipTxt.setFormat(Flags.fontFolder + "vcr.ttf", 14, chipText, "center");
            setupCamera(chipTxt);
            chartTextGrp.add(chipTxt);

            var txt = new FlxText(1260, cStartY + 24 + (i * 90), 480, cName, 24);
            txt.setFormat(Flags.fontFolder + "vcr.ttf", 24, isSelected ? 0xFFFFFFFF : 0xFFCAC4D0, "left");
            setupCamera(txt);
            chartTextGrp.add(txt);
        }
    }

    function updateSearchInput(elapsed:Float) {
        if (!isSearchFocused) return;

        cursorTimer += elapsed;
        if (cursorTimer >= 0.5) {
            cursorTimer = 0;
            showCursor = !showCursor;
            updateSearchTextDisplay();
        }

        var keysToCheck = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","SPACE","BACKSPACE","MINUS"];
        var changed = false;

        for (k in keysToCheck) {
            if (Reflect.getProperty(FlxG.keys.justPressed, k)) {
                if (k == "BACKSPACE") {
                    if (searchText.length > 0) searchText = searchText.substring(0, searchText.length - 1);
                } else if (k == "SPACE") {
                    searchText += " ";
                } else if (k == "MINUS") {
                    searchText += "-";
                } else {
                    searchText += k.toLowerCase();
                }
                changed = true;
            }
        }

        if (FlxG.keys.justPressed.ENTER) {
            isSearchFocused = false;
            showCursor = false;
            drawSearchBox();
            return;
        }

        if (changed) {
            filterSongs();
            updateSearchTextDisplay();
        }
    }

    function update(elapsed:Float) {
        updateSearchInput(elapsed);

        if (FlxG.mouse.wheel != 0) {
            targetScrollY -= FlxG.mouse.wheel * 60;
            if (targetScrollY < 0) targetScrollY = 0;
            if (targetScrollY > maxScrollY) targetScrollY = maxScrollY;
        }

        if (Math.abs(scrollY - targetScrollY) > 0.5) {
            scrollY = FlxMath.lerp(scrollY, targetScrollY, elapsed * 12);
            drawUI();
        }

        if (FlxG.mouse.justPressed) {
            if (FlxG.mouse.overlaps(searchBox, camMenu)) {
                if (!isSearchFocused) {
                    isSearchFocused = true;
                    cursorTimer = 0;
                    showCursor = true;
                    drawSearchBox();
                }
            } else {
                if (isSearchFocused) {
                    isSearchFocused = false;
                    showCursor = false;
                    drawSearchBox();
                }
            }

            if (FlxG.mouse.overlaps(closeBtn, camMenu)) {
                close();
                Discord.updatePresence("RPC Test", "Lily Engine v0.1.0 Alpha");
                return;
            }

            if (FlxG.mouse.overlaps(startBtn, camMenu)) {
                playSelected();
                return;
            }

            for (i in 0...songHitboxes.length) {
                if (FlxG.mouse.overlaps(songHitboxes[i], camMenu)) {
                    if (curSongIndex != i) {
                        curSongIndex = i;
                        loadChartsForSong(filteredSongs[curSongIndex]);
                        drawUI();
                    }
                    break;
                }
            }

            for (i in 0...chartHitboxes.length) {
                if (FlxG.mouse.overlaps(chartHitboxes[i], camMenu)) {
                    if (curChartIndex != i) {
                        curChartIndex = i;
                        drawUI();
                    }
                    break;
                }
            }
        }

        if (FlxG.mouse.overlaps(startBtn, camMenu)) {
            startBtn.color = 0xFF7D5260;
        } else {
            startBtn.color = 0xFFFFFFFF;
        }

        if (Controls.BACK) {
            if (isSearchFocused) {
                isSearchFocused = false;
                showCursor = false;
                drawSearchBox();
            } else {
                close();
                Discord.updatePresence("RPC Test", "Lily Engine v0.1.0 Alpha");
            }
        }
    }

    function playSelected() {
        if (curSongIndex != -1 && currentCharts.length > 0) {
            var sName = filteredSongs[curSongIndex];
            var cName = currentCharts[curChartIndex];
            
            var payload = {
                song: sName,
                chart: "songs/" + sName + "/charts/" + cName,
                inst: "songs/" + sName + "/song/Inst",
                voices: "songs/" + sName + "/song/Voices"
            };

            close(); 
            var minigame = new ScriptedSubState("RhythmMinigame", payload);
            FlxG.state.openSubState(minigame); 
        }
    }
}