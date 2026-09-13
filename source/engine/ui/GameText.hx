package engine.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.text.AntiAliasType;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

enum abstract GameTextAlign(String) from String to String {
	var LEFT = "left";
	var CENTER = "center";
	var RIGHT = "right";
	var JUSTIFY = "justify";
}

enum abstract GameTextBorderStyle(String) from String to String {
	var NONE = "none";
	var SHADOW = "shadow";
	var OUTLINE = "outline";
	var OUTLINE_FAST = "outline_fast";
}

private typedef GameTextLineInfo = {
	var width:Float;
	var ascent:Float;
	var descent:Float;
	var height:Float;
	var topY:Float;
}

class GameText extends FlxSprite {
	public var text(default, set):String = "";
	public var font(default, set):String;
	public var size(default, set):Int = 16;
	public var bold(default, set):Bool = false;
	public var italic(default, set):Bool = false;
	public var underline(default, set):Bool = false;
	public var strikethrough(default, set):Bool = false;
	public var letterSpacing(default, set):Float = 0;

	public var maxWidth(default, set):Float = 0;
	public var wordWrap(default, set):Bool = false;
	public var alignment(default, set):GameTextAlign = GameTextAlign.LEFT;

	public var textColor(default, set):FlxColor = FlxColor.WHITE;

	public var borderStyle(default, set):GameTextBorderStyle = GameTextBorderStyle.NONE;
	public var borderSize(default, set):Int = 1;
	public var borderColor(default, set):FlxColor = FlxColor.BLACK;

	public var infiniteLeft(default, set):Bool = false;
	public var embedFonts(default, set):Bool = false;
	public var smoothing(default, set):Bool = false;

	public var textWidth(get, never):Float;
	public var textHeight(get, never):Float;

	private var _dirty:Bool = true;
	private var _textWidth:Float = 0;
	private var _textHeight:Float = 0;
	private var _canvas:BitmapData;

	public function new(X:Float = 0, Y:Float = 0, Text:String = "", Size:Int = 16, ?Font:String) {
		super(X, Y);
        if (Font == null)
            Font = FlxAssets.FONT_DEFAULT;
		size = Size;
		font = Font;
		text = Text;
        antialiasing = true;
		_dirty = true;
	}

	override public function draw():Void {
		ensureClean();
		super.draw();
	}

	override public function destroy():Void {
		_canvas = null;
		super.destroy();
	}

	public function invalidate():Void {
		_dirty = true;
	}

	private function ensureClean():Void {
		if (_dirty)
			rebuild();
	}

	private function get_textWidth():Float {
		ensureClean();
		return _textWidth;
	}

	private function get_textHeight():Float {
		ensureClean();
		return _textHeight;
	}

	private function set_text(value:String):String {
		if (value == null)
			value = "";
		if (text != value) {
			text = value;
			invalidate();
		}
		return value;
	}

	private function set_font(value:String):String {
		if (value == null || value == "")
			value = FlxAssets.FONT_DEFAULT;

		var resolvedFont = value;
		var isEmbedded = false;

		var f = openfl.Assets.getFont(value);
		if (f != null) {
			resolvedFont = f.fontName;
			isEmbedded = true;
		}

		if (font != resolvedFont || embedFonts != isEmbedded) {
			font = resolvedFont;
			embedFonts = isEmbedded;
			invalidate();
		}
		return value;
	}

	private function set_size(value:Int):Int {
		if (value < 1)
			value = 1;
		if (size != value) {
			size = value;
			invalidate();
		}
		return value;
	}

	private function set_bold(value:Bool):Bool {
		if (bold != value) {
			bold = value;
			invalidate();
		}
		return value;
	}

	private function set_italic(value:Bool):Bool {
		if (italic != value) {
			italic = value;
			invalidate();
		}
		return value;
	}

	private function set_underline(value:Bool):Bool {
		if (underline != value) {
			underline = value;
			invalidate();
		}
		return value;
	}

	private function set_strikethrough(value:Bool):Bool {
		if (strikethrough != value) {
			strikethrough = value;
			invalidate();
		}
		return value;
	}

	private function set_letterSpacing(value:Float):Float {
		if (Math.isNaN(value))
			value = 0;
		if (letterSpacing != value) {
			letterSpacing = value;
			invalidate();
		}
		return value;
	}

	private function set_maxWidth(value:Float):Float {
		if (maxWidth != value) {
			maxWidth = value;
			invalidate();
		}
		return value;
	}

	private function set_wordWrap(value:Bool):Bool {
		if (wordWrap != value) {
			wordWrap = value;
			invalidate();
		}
		return value;
	}

	private function set_alignment(value:GameTextAlign):GameTextAlign {
		if (value == null)
			value = GameTextAlign.LEFT;
		if (alignment != value) {
			alignment = value;
			invalidate();
		}
		return value;
	}

	private function set_textColor(value:FlxColor):FlxColor {
		if (textColor != value) {
			textColor = value;
			invalidate();
		}
		return value;
	}

	private function set_borderStyle(value:GameTextBorderStyle):GameTextBorderStyle {
		if (value == null)
			value = GameTextBorderStyle.NONE;
		if (borderStyle != value) {
			borderStyle = value;
			invalidate();
		}
		return value;
	}

	private function set_borderSize(value:Int):Int {
		if (value < 0)
			value = 0;
		if (borderSize != value) {
			borderSize = value;
			invalidate();
		}
		return value;
	}

	private function set_borderColor(value:FlxColor):FlxColor {
		if (borderColor != value) {
			borderColor = value;
			invalidate();
		}
		return value;
	}

	private function set_infiniteLeft(value:Bool):Bool {
		if (infiniteLeft != value) {
			infiniteLeft = value;
			invalidate();
		}
		return value;
	}

	private function set_embedFonts(value:Bool):Bool {
		if (embedFonts != value) {
			embedFonts = value;
			invalidate();
		}
		return value;
	}

	private function set_smoothing(value:Bool):Bool {
		if (smoothing != value) {
			smoothing = value;
			invalidate();
		}
		return value;
	}

	private function rebuild():Void {
		_dirty = false;
		var processedText:String = text == null ? "" : text;

		var field:TextField = new TextField();
		field.selectable = false;
		field.mouseEnabled = false;
		field.type = TextFieldType.DYNAMIC;
		field.multiline = true;
		field.background = false;
		field.border = false;
		field.embedFonts = embedFonts;
		field.antiAliasType = AntiAliasType.ADVANCED;

		var openflAlign = switch (alignment) {
			case GameTextAlign.CENTER: TextFormatAlign.CENTER;
			case GameTextAlign.RIGHT: TextFormatAlign.RIGHT;
			case GameTextAlign.JUSTIFY: TextFormatAlign.JUSTIFY;
			default: TextFormatAlign.LEFT;
		};

		if (maxWidth > 0) {
			field.wordWrap = wordWrap;
			field.width = maxWidth;
			field.autoSize = TextFieldAutoSize.NONE;
		} else {
			field.wordWrap = false;
			field.autoSize = TextFieldAutoSize.LEFT;
		}

		var fmt:TextFormat = new TextFormat();
		fmt.font = font;
		fmt.size = size;
		fmt.bold = bold;
		fmt.italic = italic;
		fmt.underline = false;
		fmt.letterSpacing = letterSpacing;
		fmt.color = rgbOf(textColor);
		fmt.align = openflAlign;

		field.defaultTextFormat = fmt;
		field.text = processedText;
		field.setTextFormat(fmt);
		field.textColor = rgbOf(textColor);

		var lineInfos:Array<GameTextLineInfo> = [];
		var maxLineWidth:Float = 0;
		var lineY:Float = 0;

		var lineCount:Int = field.numLines;
		if (lineCount <= 0)
			lineCount = 1;

		for (i in 0...lineCount) {
			var lm = field.getLineMetrics(i);
			var w:Float = lm.width;
			var ascent:Float = lm.ascent;
			var descent:Float = lm.descent;
			var h:Float = lm.height;

			if (w < 0)
				w = 0;
			if (ascent <= 0)
				ascent = size * 0.8;
			if (descent < 0)
				descent = 0;
			if (h <= 0)
				h = ascent + descent + 2;

			lineInfos.push({
				width: w,
				ascent: ascent,
				descent: descent,
				height: h,
				topY: lineY
			});
			lineY += h;
			if (w > maxLineWidth)
				maxLineWidth = w;
		}

		var totalHeight:Float = lineY;
		if (totalHeight <= 0)
			totalHeight = size;

		_textWidth = maxLineWidth;
		_textHeight = totalHeight;

		var useBorder:Bool = borderStyle != GameTextBorderStyle.NONE && borderSize > 0 && alphaOf(borderColor) > 0;
		var pad:Int = (useBorder ? borderSize : 0) + 2;

		var canvasW:Int = Math.ceil(Math.max(maxWidth > 0 ? maxWidth : maxLineWidth, 1.0)) + pad * 2;
		var canvasH:Int = Math.ceil(Math.max(totalHeight, size + 0.0)) + pad * 2;

		if (canvasW < 1)
			canvasW = 1;
		if (canvasH < 1)
			canvasH = 1;

		if (_canvas == null || _canvas.width != canvasW || _canvas.height != canvasH) {
			if (graphic != null) {
				FlxG.bitmap.remove(graphic);
			}
			var key:String = FlxG.bitmap.getUniqueKey("game_text");
			makeGraphic(canvasW, canvasH, FlxColor.TRANSPARENT, false, key);
			_canvas = graphic.bitmap;
		} else {
			_canvas.fillRect(_canvas.rect, 0);
		}

		var baseX:Float = pad - 2;
		var baseY:Float = pad - 2;

		var drawTextPass = function(c:FlxColor, dx:Float, dy:Float):Void {
			var a:Float = alphaOf(c);
			if (a <= 0)
				return;
			fmt.color = rgbOf(c);
			field.setTextFormat(fmt);
			field.defaultTextFormat = fmt;
			field.textColor = rgbOf(c);
			var m:Matrix = new Matrix();
			m.translate(baseX + dx, baseY + dy);
			var ct:ColorTransform = new ColorTransform(1, 1, 1, a);
			_canvas.draw(field, m, ct, null, null, smoothing);
		};

		var drawDecorationsPass = function(c:FlxColor, dx:Float, dy:Float):Void {
			if (!underline && !strikethrough)
				return;
			if (alphaOf(c) <= 0)
				return;
			for (line in lineInfos) {
				if (line.width <= 0)
					continue;
				var glyphHeight:Float = line.ascent + line.descent;
				var thickness = Math.max(1, Math.floor(glyphHeight / 12));
				var lineX:Float = pad + dx;
				if (underline) {
					var uy:Float = pad + line.topY + line.ascent + Math.max(1, line.descent * 0.25) + dy;
					_canvas.fillRect(new Rectangle(lineX, uy, line.width, thickness), c);
				}
				if (strikethrough) {
					var sy:Float = pad + line.topY + (line.ascent * 0.65) - (thickness * 0.5) + dy;
					_canvas.fillRect(new Rectangle(lineX, sy, line.width, thickness), c);
				}
			}
		};

		var borderOffsets:Array<Array<Int>> = [];
		if (useBorder) {
			if (borderStyle == GameTextBorderStyle.SHADOW) {
				borderOffsets.push([borderSize, borderSize]);
			} else if (borderStyle == GameTextBorderStyle.OUTLINE_FAST) {
				borderOffsets.push([-borderSize, 0]);
				borderOffsets.push([borderSize, 0]);
				borderOffsets.push([0, -borderSize]);
				borderOffsets.push([0, borderSize]);
			} else if (borderStyle == GameTextBorderStyle.OUTLINE) {
				for (dx in -borderSize...borderSize + 1)
					for (dy in -borderSize...borderSize + 1)
						if (dx != 0 || dy != 0)
							borderOffsets.push([dx, dy]);
			}
		}

		for (o in borderOffsets) {
			drawTextPass(borderColor, o[0], o[1]);
			drawDecorationsPass(borderColor, o[0], o[1]);
		}

		drawTextPass(textColor, 0, 0);
		drawDecorationsPass(textColor, 0, 0);

		var ox:Float = pad;
		if (maxWidth == 0) {
			switch (alignment) {
				case GameTextAlign.CENTER:
					ox = pad + maxLineWidth / 2;
				case GameTextAlign.RIGHT:
					ox = pad + maxLineWidth;
				default:
			}
		}

		if (infiniteLeft) {
			ox = pad + maxLineWidth;
		}

		offset.set(ox, pad);
	}

	private inline function rgbOf(c:FlxColor):Int {
		return c & 0x00FFFFFF;
	}

	private inline function alphaOf(c:FlxColor):Float {
		return ((c >>> 24) & 0xFF) / 255;
	}
}
