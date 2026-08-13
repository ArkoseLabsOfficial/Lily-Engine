package openfl.utils;

import openfl.utils._internal.Log;
import openfl.display.BitmapData;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.media.Sound;
import openfl.text.Font;

#if sys
import sys.FileSystem;
import sys.FileStat;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
#end

#if lime
import lime.app.Promise;
import lime.app.Future;
import lime.utils.AssetLibrary as LimeAssetLibrary;
import lime.utils.Assets as LimeAssets;
#end
#if lime_vorbis
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
#end

using StringTools;

/**
    The Assets class provides a cross-platform interface to access
    embedded images, fonts, sounds and other resource files.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display.BitmapData)
@:access(openfl.display.Sprite)
@:access(openfl.text.Font)
@:access(openfl.utils.AssetLibrary)
class Assets
{
    public static var cache:IAssetCache = new AssetCache();

    @:noCompletion private static var dispatcher:EventDispatcher #if !macro = new EventDispatcher() #end;
    private static var libraryBindings:Map<String, AssetLibrary> = new Map();

    public static function addEventListener(type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
    {
        #if lime
        if (!LimeAssets.onChange.has(LimeAssets_onChange))
        {
            LimeAssets.onChange.add(LimeAssets_onChange);
        }
        #end

        dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
    }

    public static function dispatchEvent(event:Event):Bool
    {
        return dispatcher.dispatchEvent(event);
    }


    #if html5
    public static function cleanAssetPath(path:String):String {
        if (path == null) return "";
        
        if (path.startsWith("./")) {
            path = path.substr(2);
        } else if (path.startsWith("/")) {
            path = path.substr(1);
        }

        var qIndex = path.indexOf("?");
        if (qIndex != -1) {
            path = path.substr(0, qIndex);
        }
        
        return path;
    }
    #end
    
    /**
     * The core path solver. Automatically checks `mods/` then `assets/` and finally normal Lime Assets.
     */
    public static function getGameFilePath(file:String):String {
        #if html5
        file = cleanAssetPath(file);
        #end
        #if sys
        if (GamePrefs.currentMod != "") {
            var activeModPath = 'mods/' + GamePrefs.currentMod + '/' + file;
            if (FileSystem.exists(activeModPath))
                return activeModPath;
        }

        var modPath = 'mods/$file';
        if (FileSystem.exists(modPath))
            return modPath;

        var assetPath = 'assets/$file';
        if (FileSystem.exists(assetPath))
            return assetPath;
        #end

        #if lime
        var checkPath = function(targetPath:String):Bool {
            if (LimeAssets.exists(targetPath)) return true;

            return list().filter(asset -> asset.startsWith(targetPath) && asset != targetPath).length > 0;
        };

        if (GamePrefs.currentMod != "") {
            var activeModPath = 'mods/' + GamePrefs.currentMod + '/' + file;
            if (checkPath(activeModPath))
                return activeModPath;
        }

        if (checkPath('mods/$file'))
            return 'mods/$file';
            
        if (checkPath('assets/$file'))
            return 'assets/$file';
        
        #end

        return file;
    }

    // FileSystem Ports

    #if (linux && sys)
    private static function getCaseInsensitivePath(path:String):String
    {
        if (exists(path))
            return path;

        var parts:Array<String> = path.split("/");
        var current:String = "";

        if (path.charAt(0) == "/")
            current = "/";

        for (part in parts)
        {
            if (part == "")
                continue;

            var searchTarget = (current == "" || current == "/") ? part : current + "/" + part;
            
            if (exists(searchTarget)) {
                current = searchTarget;
                continue;
            }

            if (current != "" && (!exists(current) || !isDirectory(current)))
                return null;

            var files:Array<String> = readDirectory(current == "" ? "./" : current);

            var found:Bool = false;
            for (f in files)
            {
                if (f.toLowerCase() == part.toLowerCase())
                {
                    if (current == "" || current == "/")
                        current += f;
                    else
                        current += "/" + f;
                    found = true;
                    break;
                }
            }

            if (!found)
                return null;
        }

        return exists(current) ? current : null;
    }
    #end

    public static function isDirectory(path:String):Bool
    {
        path = getGameFilePath(path);
        #if sys
        var actualPath:String = path;
        #if linux
        var casePath = getCaseInsensitivePath(path);
        if (casePath != null) actualPath = casePath;
        #end
        if (FileSystem.exists(actualPath) && FileSystem.isDirectory(actualPath))
            return true;
        #end

        return list().filter(asset -> asset.startsWith(path) && asset != path).length > 0;
    }

    public static function readDirectory(path:String):Array<String>
    {
        path = getGameFilePath(path);
        #if sys
        var actualPath:String = path;
        #if linux
        var casePath = getCaseInsensitivePath(path);
        if (casePath != null) actualPath = casePath;
        #end
        
        if (FileSystem.exists(actualPath) && FileSystem.isDirectory(actualPath))
            return FileSystem.readDirectory(actualPath);
        #end

        var filteredList:Array<String> = list().filter(f -> f.startsWith(path));
        var results:Array<String> = [];
        for (i in filteredList.copy())
        {
            var slashsCount:Int = path.split('/').length;
            if (path.endsWith('/'))
                slashsCount -= 1;

            if (i.split('/').length - 1 != slashsCount)
                filteredList.remove(i);
        }
        for (item in filteredList)
        {
            #if lime
            @:privateAccess
            for (library in LimeAssets.libraries.keys())
            {
                var libPath:String = '$library:$item';
                if (library != 'default' && exists(libPath) && !results.contains(libPath))
                    results.push(libPath);
                else if (exists(item) && !results.contains(item))
                    results.push(item);
            }
            #else
            if (exists(item) && !results.contains(item))
                results.push(item);
            #end
        }
        return results.map(f -> f.substr(f.lastIndexOf("/") + 1));
    }

    // End
    

    // Helper Functions

    public static function getImage(id:String, useCache:Bool = true):BitmapData
        return getBitmapData('${Flags.imageFolder}$id.png', useCache);

    public static function imageExists(id:String):Bool
        return exists('${Flags.imageFolder}$id.png');

    public static function getSparrowAtlas(key:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(Assets.getImage(key), Assets.getText('${Flags.imageFolder}$key.xml'));

	public static function getPackerAtlas(key:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSpriteSheetPacker(Assets.getImage(key), Assets.getText('${Flags.imageFolder}$key.txt'));

	public static function getAsepriteAtlas(key:String):FlxAtlasFrames
		return FlxAtlasFrames.fromTexturePackerJson(Assets.getImage(key), Assets.getText('${Flags.imageFolder}$key.json'));

    // End

    public static function exists(id:String, type:AssetType = null):Bool
    {
        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path)) return true;
        #end

        #if lime
        if (LimeAssets.exists(path, cast type)) return true;

        return list().filter(asset -> asset.startsWith(path) && asset != path).length > 0;
        #else
        return false;
        #end
    }

    public static function getBitmapData(id:String, useCache:Bool = true):BitmapData
    {
        #if (lime && tools && !display)
        if (useCache && cache.enabled && cache.hasBitmapData(id))
        {
            var bitmapData = cache.getBitmapData(id);

            if (isValidBitmapData(bitmapData))
            {
                return bitmapData;
            }
        }

        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path))
        {
            var bitmapData = BitmapData.fromFile(path);
            if (bitmapData != null)
            {
                if (useCache && cache.enabled) cache.setBitmapData(id, bitmapData);
                return bitmapData;
            }
        }
        #end

        var image = null;
        try {
            image = LimeAssets.getImage(path, false);
        } catch(e:Dynamic) {
            //trace(e);
        }

        if (image != null)
        {
            #if flash
            var bitmapData = image.src;
            #else
            var bitmapData = BitmapData.fromImage(image);
            #end

            if (useCache && cache.enabled)
            {
                cache.setBitmapData(id, bitmapData);
            }

            return bitmapData;
        }
        #end

        return null;
    }

    public static function getBytes(id:String):ByteArray
    {
        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path)) return ByteArray.fromBytes(File.getBytes(path));
        #end

        #if lime
        return LimeAssets.getBytes(path);
        #else
        return null;
        #end
    }

    public static function getFont(id:String, useCache:Bool = true):Font
    {
        #if (lime && tools && !display && !macro)
        if (useCache && cache.enabled && cache.hasFont(id))
        {
            return cache.getFont(id);
        }

        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path))
        {
            var font = Font.fromFile(path);
            if (font != null)
            {
                if (useCache && cache.enabled) cache.setFont(id, font);
                return font;
            }
        }
        #end

        var limeFont = LimeAssets.getFont(path, false);

        if (limeFont != null)
        {
            #if flash
            var font = limeFont.src;
            #else
            var font = new Font();
            font.__fromLimeFont(limeFont);
            #end

            if (useCache && cache.enabled)
            {
                cache.setFont(id, font);
            }

            return font;
        }
        #end

        return new Font();
    }

    public static function getLibrary(name:String):#if lime LimeAssetLibrary #else AssetLibrary #end
    {
        #if lime
        return LimeAssets.getLibrary(name);
        #else
        return null;
        #end
    }

    public static function getMovieClip(id:String):MovieClip
    {
        #if (lime && tools && !display)
        var libraryName = id.substring(0, id.indexOf(":"));
        var symbolName = id.substr(id.indexOf(":") + 1);
        var limeLibrary = getLibrary(libraryName);

        if (limeLibrary != null)
        {
            if ((limeLibrary is AssetLibrary))
            {
                var library:AssetLibrary = cast limeLibrary;

                if (library.exists(symbolName, cast AssetType.MOVIE_CLIP))
                {
                    if (library.isLocal(symbolName, cast AssetType.MOVIE_CLIP))
                    {
                        return library.getMovieClip(symbolName);
                    }
                    else
                    {
                        Log.error("MovieClip asset \"" + id + "\" exists, but only asynchronously");
                        return null;
                    }
                }
            }

            Log.error("There is no MovieClip asset with an ID of \"" + id + "\"");
        }
        else
        {
            Log.error("There is no asset library named \"" + libraryName + "\"");
        }
        #end

        return null;
    }

    public static function getMusic(id:String, useCache:Bool = true):Sound
    {
        #if (lime_vorbis && lime > "7.9.0")
        var resolvedPath = getPath(id);
        
        if (resolvedPath != null)
        {
            var vorbisFile = VorbisFile.fromFile(resolvedPath);
            var buffer = AudioBuffer.fromVorbisFile(vorbisFile);
            return Sound.fromAudioBuffer(buffer);
        }
        #end
        
        return getSound(id, useCache);
    }

    public static function getPath(id:String):String
    {
        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path)) return path;
        #end

        #if lime
        try {
            var limePath = LimeAssets.getPath(path);
            if (limePath != null)
                return limePath;
        } catch(e:Dynamic) {
            //trace(e);
        }

        return null;
        #else
        return null;
        #end
    }

    public static function getSound(id:String, useCache:Bool = true):Sound
    {
        #if (lime && tools && !display)
        if (useCache && cache.enabled && cache.hasSound(id))
        {
            var sound = cache.getSound(id);

            if (isValidSound(sound))
            {
                return sound;
            }
        }

        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path))
        {
            var sound = Sound.fromBytes(File.getBytes(path));
            if (sound != null)
            {
                if (useCache && cache.enabled) cache.setSound(id, sound);
                return sound;
            }
        }
        #end

        var buffer = LimeAssets.getAudioBuffer(path, false);

        if (buffer != null)
        {
            #if flash
            var sound = buffer.src;
            #else
            var sound = Sound.fromAudioBuffer(buffer);
            #end

            if (useCache && cache.enabled)
            {
                cache.setSound(id, sound);
            }

            return sound;
        }
        #end

        return null;
    }

    public static function getText(id:String):String
    {
        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path)) return File.getContent(path);
        #end

        #if lime
        return LimeAssets.getText(path);
        #else
        return null;
        #end
    }

    public static function hasEventListener(type:String):Bool
    {
        return dispatcher.hasEventListener(type);
    }

    public static function hasLibrary(name:String):Bool
    {
        #if lime
        return LimeAssets.hasLibrary(name);
        #else
        return false;
        #end
    }

    public static function initBinding(className:String, instance:Dynamic = null):Void
    {
        if (libraryBindings.exists(className))
        {
            var library = libraryBindings.get(className);
            #if !flash
            if (instance == null)
            {
                Sprite.__constructor = function(instance:Sprite)
                {
                    instance.__bind(library, className);
                }
            }
            else
            {
                Sprite.__constructor = null;
                instance.__bind(library, className);
            }
            #else
            library.bind(className);
            #end
        }
        else
        {
            Log.warn("No asset is registered as \"" + className + "\"");
        }
    }

    public static function isLocal(id:String, type:AssetType = null, useCache:Bool = true):Bool
    {
        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path)) return true;
        #end

        #if (lime && tools && !display)
        if (useCache && cache.enabled)
        {
            if (type == AssetType.IMAGE || type == null)
            {
                if (cache.hasBitmapData(id)) return true;
            }

            if (type == AssetType.FONT || type == null)
            {
                if (cache.hasFont(id)) return true;
            }

            if (type == AssetType.SOUND || type == AssetType.MUSIC || type == null)
            {
                if (cache.hasSound(id)) return true;
            }
        }

        var libraryName = id.substring(0, id.indexOf(":"));
        var symbolName = id.substr(id.indexOf(":") + 1);
        var library = getLibrary(libraryName);

        if (library != null)
        {
            return library.isLocal(symbolName, cast type);
        }
        #end

        return false;
    }

    @:analyzer(ignore) private static function isValidBitmapData(bitmapData:BitmapData):Bool
    {
        #if (lime && tools && !display)
        #if flash
        try
        {
            bitmapData.width;
            return true;
        }
        catch (e:Dynamic)
        {
            return false;
        }
        #else
        return (bitmapData != null && #if !lime_hybrid bitmapData.image != null #else bitmapData.__handle != null #end);
        #end
        #else
        return true;
        #end
    }

    @:noCompletion private static function isValidSound(sound:Sound):Bool
    {
        #if ((tools && !display) && (cpp || neko || nodejs))
        return true;
        #else
        return true;
        #end
    }

    public static function list(type:AssetType = null):Array<String>
    {
        #if lime
        return LimeAssets.list(cast type);
        #else
        return [];
        #end
    }

    public static function loadBitmapData(id:String, useCache:Null<Bool> = true):Future<BitmapData>
    {
        if (useCache == null) useCache = true;

        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path))
        {
            var bitmap = getBitmapData(id, useCache);
            if (bitmap != null) return Future.withValue(bitmap);
        }
        #end

        #if (lime && tools && !display)
        var promise = new Promise<BitmapData>();

        if (useCache && cache.enabled && cache.hasBitmapData(id))
        {
            var bitmapData = cache.getBitmapData(id);

            if (isValidBitmapData(bitmapData))
            {
                promise.complete(bitmapData);
                return promise.future;
            }
        }

        LimeAssets.loadImage(path, false).onComplete(function(image)
        {
            if (image != null)
            {
                #if flash
                var bitmapData = image.src;
                #else
                var bitmapData = BitmapData.fromImage(image);
                #end

                if (useCache && cache.enabled)
                {
                    cache.setBitmapData(id, bitmapData);
                }

                promise.complete(bitmapData);
            }
            else
            {
                promise.error("[Assets] Could not load Image \"" + id + "\" at path: " + path);
            }
        }).onError(promise.error).onProgress(promise.progress);

        return promise.future;
        #else
        return Future.withValue(getBitmapData(id, useCache));
        #end
    }

    public static function loadBytes(id:String):Future<ByteArray>
    {
        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path)) return Future.withValue(getBytes(id));
        #end

        #if lime
        var promise = new Promise<ByteArray>();
        var future = LimeAssets.loadBytes(path);

        future.onComplete(function(bytes) promise.complete(bytes));
        future.onProgress(function(progress, total) promise.progress(progress, total));
        future.onError(function(msg) promise.error(msg));

        return promise.future;
        #else
        return Future.withValue(getBytes(id));
        #end
    }

    public static function loadFont(id:String, useCache:Null<Bool> = true):Future<Font>
    {
        if (useCache == null) useCache = true;

        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path))
        {
            var font = getFont(id, useCache);
            if (font != null) return Future.withValue(font);
        }
        #end

        #if (lime && tools && !display && !macro)
        var promise = new Promise<Font>();

        if (useCache && cache.enabled && cache.hasFont(id))
        {
            promise.complete(cache.getFont(id));
            return promise.future;
        }

        LimeAssets.loadFont(path)
            .onComplete(function(limeFont)
            {
                #if flash
                var font = limeFont.src;
                #else
                var font = new Font();
                font.__fromLimeFont(limeFont);
                #end

                if (useCache && cache.enabled)
                {
                    cache.setFont(id, font);
                }

                promise.complete(font);
            })
            .onError(promise.error)
            .onProgress(promise.progress);

        return promise.future;
        #else
        return Future.withValue(getFont(id, useCache));
        #end
    }

    public static function loadLibrary(name:String):#if java Future<LimeAssetLibrary> #else Future<AssetLibrary> #end
    {
        #if lime
        return LimeAssets.loadLibrary(name).then(function(library)
        {
            var _library:AssetLibrary = null;

            if (library != null)
            {
                if ((library is AssetLibrary))
                {
                    _library = cast library;
                }
                else
                {
                    @:privateAccess LimeAssets.libraries.remove(name);
                    _library = new AssetLibrary();
                    _library.__proxy = library;
                    LimeAssets.registerLibrary(name, _library);
                }
            }

            return Future.withValue(_library);
        });
        #else
        return cast Future.withError("Cannot load library");
        #end
    }

    public static function loadMusic(id:String, useCache:Null<Bool> = true):Future<Sound>
    {
        if (useCache == null) useCache = true;

        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path))
        {
            var music = getMusic(id, useCache);
            if (music != null) return Future.withValue(music);
        }
        #end

        #if lime
        #if !html5
        var promise = new Promise<Sound>();

        LimeAssets.loadAudioBuffer(path, useCache)
            .onComplete(function(buffer)
            {
                if (buffer != null)
                {
                    #if flash
                    var sound = buffer.src;
                    #else
                    var sound = Sound.fromAudioBuffer(buffer);
                    #end

                    if (useCache && cache.enabled)
                    {
                        cache.setSound(id, sound);
                    }

                    promise.complete(sound);
                }
                else
                {
                    promise.error("[Assets] Could not load Sound \"" + id + "\" at path: " + path);
                }
            })
            .onError(promise.error)
            .onProgress(promise.progress);
        return promise.future;
        #else
        var future = new Future<Sound>(function() return getMusic(id, useCache));
        return future;
        #end
        #else
        return Future.withValue(getMusic(id, useCache));
        #end
    }

    public static function loadMovieClip(id:String):Future<MovieClip>
    {
        #if (lime && tools && !display)
        var promise = new Promise<MovieClip>();

        var libraryName = id.substring(0, id.indexOf(":"));
        var symbolName = id.substr(id.indexOf(":") + 1);
        var limeLibrary = getLibrary(libraryName);

        if (limeLibrary != null)
        {
            if ((limeLibrary is AssetLibrary))
            {
                var library:AssetLibrary = cast limeLibrary;

                if (library.exists(symbolName, cast AssetType.MOVIE_CLIP))
                {
                    promise.completeWith(library.loadMovieClip(symbolName));
                    return promise.future;
                }
            }

            promise.error("[Assets] There is no MovieClip asset with an ID of \"" + id + "\"");
        }
        else
        {
            promise.error("[Assets] There is no asset library named \"" + libraryName + "\"");
        }

        return promise.future;
        #else
        return Future.withValue(getMovieClip(id));
        #end
    }

    public static function loadSound(id:String, useCache:Null<Bool> = true):Future<Sound>
    {
        if (useCache == null) useCache = true;

        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path))
        {
            var sound = getSound(id, useCache);
            if (sound != null) return Future.withValue(sound);
        }
        #end

        #if lime
        var promise = new Promise<Sound>();

        LimeAssets.loadAudioBuffer(path, useCache)
            .onComplete(function(buffer)
            {
                if (buffer != null)
                {
                    #if flash
                    var sound = buffer.src;
                    #else
                    var sound = Sound.fromAudioBuffer(buffer);
                    #end

                    if (useCache && cache.enabled)
                    {
                        cache.setSound(id, sound);
                    }

                    promise.complete(sound);
                }
                else
                {
                    promise.error("[Assets] Could not load Sound \"" + id + "\" at path: " + path);
                }
            })
            .onError(promise.error)
            .onProgress(promise.progress);
        return promise.future;
        #else
        return Future.withValue(getSound(id, useCache));
        #end
    }

    public static function loadText(id:String):Future<String>
    {
        var path = getGameFilePath(id);

        #if sys
        if (FileSystem.exists(path)) return Future.withValue(getText(id));
        #end

        #if lime
        var future = LimeAssets.loadText(path);
        return future;
        #else
        return Future.withValue(getText(id));
        #end
    }

    public static function registerBinding(className:String, library:AssetLibrary):Void
    {
        libraryBindings.set(className, library);
    }

    public static function registerLibrary(name:String, library:AssetLibrary):Void
    {
        #if lime
        LimeAssets.registerLibrary(name, library);
        #end
    }

    public static function removeEventListener(type:String, listener:Dynamic, capture:Bool = false):Void
    {
        dispatcher.removeEventListener(type, listener, capture);
    }

    @:noCompletion private static function resolveClass(name:String):Class<Dynamic>
    {
        return Type.resolveClass(name);
    }

    @:noCompletion private static function resolveEnum(name:String):Enum<Dynamic>
    {
        var value = Type.resolveEnum(name);

        #if flash
        if (value == null)
        {
            return cast Type.resolveClass(name);
        }
        #end

        return value;
    }

    public static function unloadLibrary(name:String):Void
    {
        #if lime
        LimeAssets.unloadLibrary(name);
        #end
    }

    public static function unregisterBinding(className:String, library:AssetLibrary):Void
    {
        if (libraryBindings.exists(className) && libraryBindings.get(className) == library)
        {
            libraryBindings.remove(className);
        }
    }

    // Event Handlers
    @:noCompletion private static function LimeAssets_onChange():Void
    {
        dispatchEvent(new Event(Event.CHANGE));
    }
}