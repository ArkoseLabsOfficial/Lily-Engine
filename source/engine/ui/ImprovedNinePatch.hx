package engine.ui;

typedef MarginData = {
	@:optional var left:Int;
	@:optional var top:Int;
	@:optional var right:Int;
	@:optional var bottom:Int;
}

class ImprovedNinePatch extends FlxSpriteGroup {
	public var texture(default, set):String;
	public var bgTexture(default, set):String;
	public var bgMaskTexture(default, set):String;
	public var margin:MarginData;

	public var scaleFactor:Float = 1.0;
	public var bgModulate:FlxColor = FlxColor.WHITE;
	public var drawCenter:Bool = true;

	private var targetWidth:Int;
	private var targetHeight:Int;

	public function new(X:Float = 0, Y:Float = 0) {
		super(X, Y);
	}

	public function resize(width:Float, height:Float):Void {
		targetWidth = Math.round(width);
		targetHeight = Math.round(height);
		render();
	}

	private function set_texture(value:String):String {
		if (texture != value) {
			texture = value;
			render();
		}
		return value;
	}

	private function set_bgTexture(value:String):String {
		if (bgTexture != value) {
			bgTexture = value;
			render();
		}
		return value;
	}

	#if ANGLE_RENDERER
	public var applyAngleColorFix:Bool = true; 
	private function fixAngleColors(bmp:BitmapData):Void {
        var tempBmp = new BitmapData(bmp.width, bmp.height, false, 0x000000);
        tempBmp.copyChannel(bmp, bmp.rect, new Point(0, 0), BitmapDataChannel.RED, BitmapDataChannel.RED);
        bmp.copyChannel(bmp, bmp.rect, new Point(0, 0), BitmapDataChannel.BLUE, BitmapDataChannel.RED);
        bmp.copyChannel(tempBmp, tempBmp.rect, new Point(0, 0), BitmapDataChannel.RED, BitmapDataChannel.BLUE);
        tempBmp.dispose();
    }
	#end

	private function set_bgMaskTexture(value:String):String {
		if (bgMaskTexture != value) {
			bgMaskTexture = value;
			render();
		}
		return value;
	}

	public function render():Void {
		clear();
		if (targetWidth <= 0 || targetHeight <= 0)
			return;

		if (bgTexture != null && bgTexture != "") {
			var bgSprite = new FlxSprite(0, 0);
			var bgGraphic = Assets.getImage(bgTexture);

			if (bgGraphic != null) {
				var finalBgBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);

				var bgMat = new Matrix();
				bgMat.scale(targetWidth / bgGraphic.width, targetHeight / bgGraphic.height);
				finalBgBmp.draw(bgGraphic, bgMat, null, null, null, true);

				if (bgMaskTexture != null && bgMaskTexture != "") {
					var maskGraphic = Assets.getImage(bgMaskTexture);
					if (maskGraphic != null) {
						var maskBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);

						var x0:Int = 0;
						var x1:Int = Math.round(margin.left * scaleFactor);
						var x2:Int = targetWidth - Math.round(margin.right * scaleFactor);
						var x3:Int = targetWidth;

						var y0:Int = 0;
						var y1:Int = Math.round(margin.top * scaleFactor);
						var y2:Int = targetHeight - Math.round(margin.bottom * scaleFactor);
						var y3:Int = targetHeight;

						var w0 = x1 - x0;
						var w1 = x2 - x1;
						var w2 = x3 - x2;

						var h0 = y1 - y0;
						var h1 = y2 - y1;
						var h2 = y3 - y2;

						var rS = maskGraphic.width - margin.right;
						var bS = maskGraphic.height - margin.bottom;
						var mX = maskGraphic.width - margin.left - margin.right;
						var mY = maskGraphic.height - margin.top - margin.bottom;

						// clipRect and Matrix translation for avoiding the sub-pixel edge bleeding ;)
						function drawMaskPiece(rx:Float, ry:Float, rw:Float, rh:Float, dw:Int, dh:Int, px:Int, py:Int) {
							if (dw <= 0 || dh <= 0 || rw <= 0 || rh <= 0)
								return;

							var sx = dw / rw;
							var sy = dh / rh;

							var mat = new Matrix();
							mat.scale(sx, sy);
							mat.translate(px - (rx * sx), py - (ry * sy));

							maskBmp.draw(maskGraphic, mat, null, null, new Rectangle(px, py, dw, dh), true);
						}

						drawMaskPiece(0, 0, margin.left, margin.top, w0, h0, x0, y0);
						drawMaskPiece(margin.left, 0, mX, margin.top, w1, h0, x1, y0);
						drawMaskPiece(rS, 0, margin.right, margin.top, w2, h0, x2, y0);
						drawMaskPiece(0, margin.top, margin.left, mY, w0, h1, x0, y1);
						drawMaskPiece(margin.left, margin.top, mX, mY, w1, h1, x1, y1);
						drawMaskPiece(rS, margin.top, margin.right, mY, w2, h1, x2, y1);
						drawMaskPiece(0, bS, margin.left, margin.bottom, w0, h2, x0, y2);
						drawMaskPiece(margin.left, bS, mX, margin.bottom, w1, h2, x1, y2);
						drawMaskPiece(rS, bS, margin.right, margin.bottom, w2, h2, x2, y2);

						finalBgBmp.copyChannel(maskBmp, maskBmp.rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
						maskBmp.dispose();
					}
				}

				#if ANGLE_RENDERER
				if (applyAngleColorFix) {
                    fixAngleColors(finalBgBmp);
                }
				#end

				bgSprite.loadGraphic(finalBgBmp);
				bgSprite.updateHitbox();
				bgSprite.color = bgModulate;
				bgSprite.antialiasing = true;
				add(bgSprite);
			}
		}

		if (texture != null && texture != "") {
			var g = Assets.getImage(texture);
			if (g != null) {
				var finalTexBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);

				var x0:Int = 0;
				var x1:Int = Math.round(margin.left * scaleFactor);
				var x2:Int = targetWidth - Math.round(margin.right * scaleFactor);
				var x3:Int = targetWidth;

				var y0:Int = 0;
				var y1:Int = Math.round(margin.top * scaleFactor);
				var y2:Int = targetHeight - Math.round(margin.bottom * scaleFactor);
				var y3:Int = targetHeight;

				var w0 = x1 - x0;
				var w1 = x2 - x1;
				var w2 = x3 - x2;

				var h0 = y1 - y0;
				var h1 = y2 - y1;
				var h2 = y3 - y2;

				var rS = g.width - margin.right;
				var bS = g.height - margin.bottom;
				var mX = g.width - margin.left - margin.right;
				var mY = g.height - margin.top - margin.bottom;

				function addF(rx:Float, ry:Float, rw:Float, rh:Float, dw:Int, dh:Int, px:Int, py:Int) {
					if (dw <= 0 || dh <= 0 || rw <= 0 || rh <= 0)
						return;

					var sx = dw / rw;
					var sy = dh / rh;

					var mat = new Matrix();
					mat.scale(sx, sy);
					mat.translate(px - (rx * sx), py - (ry * sy));

					finalTexBmp.draw(g, mat, null, null, new Rectangle(px, py, dw, dh), true);
				}

				addF(0, 0, margin.left, margin.top, w0, h0, x0, y0);
				addF(margin.left, 0, mX, margin.top, w1, h0, x1, y0);
				addF(rS, 0, margin.right, margin.top, w2, h0, x2, y0);
				addF(0, margin.top, margin.left, mY, w0, h1, x0, y1);
				if (drawCenter)
					addF(margin.left, margin.top, mX, mY, w1, h1, x1, y1);
				addF(rS, margin.top, margin.right, mY, w2, h1, x2, y1);
				addF(0, bS, margin.left, margin.bottom, w0, h2, x0, y2);
				addF(margin.left, bS, mX, margin.bottom, w1, h2, x1, y2);
				addF(rS, bS, margin.right, margin.bottom, w2, h2, x2, y2);

				#if ANGLE_RENDERER
				if (applyAngleColorFix) {
                    fixAngleColors(finalTexBmp);
                }
				#end

				var texSprite = new FlxSprite(0, 0);
				texSprite.loadGraphic(finalTexBmp);
				texSprite.antialiasing = true;
				add(texSprite);
			}
		}
	}
}
