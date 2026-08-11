package engine.objects;

import lime.math.Vector2;
import godot.nodes.CollisionShape2D;
import godot.nodes.CollisionPolygon2D;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.FlxG;
import engine.backend.game.RoomManager;

class Player extends Character {
	var walkSpeed:Float = 160;
	var runSpeed:Float = 280;

	override public function loadEntity(spriteName:String) {
		super.loadEntity(spriteName);
		solid = false;
	}

	override public function getCollisionBox():FlxRect {
		return FlxRect.get(x - 12, y - 6, 24, 6);
	}

	public function getCollisionBoxAt(targetX:Float, targetY:Float):FlxRect {
		var box = getCollisionBox();

		box.x += targetX - x;
		box.y += targetY - y;

		return box;
	}

	override public function update(elapsed:Float):Void {
		if (canMove && !isFollowingPath) {
			velocity.set(0, 0);
			handleMovement(elapsed);

			if (velocity.x != 0 || velocity.y != 0) {
				if (Math.abs(velocity.x) > Math.abs(velocity.y))
					direction = velocity.x > 0 ? RIGHT : LEFT;
				else
					direction = velocity.y > 0 ? DOWN : UP;
			}
		} else if (isFollowingPath) {
			velocity.set(0, 0);
		}

		if (!isFollowingPath && (velocity.x != 0 || velocity.y != 0)) {
			var stepX = velocity.x * elapsed;
			var stepY = velocity.y * elapsed;

			var simulatedX = x;

			if (velocity.x != 0) {
				if (checkCollision(x + stepX, y)) {
					velocity.x = 0;
				} else {
					simulatedX += stepX;
				}
			}

			if (velocity.y != 0) {
				if (checkCollision(simulatedX, y + stepY)) {
					velocity.y = 0;
				}
			}
		}

		super.update(elapsed);
	}

	public function checkCollisionObject(obj:Dynamic):Bool {
		if (obj == null)
			return false;

		var ox:Float = (obj.x != null) ? obj.x : 0;
		var oy:Float = (obj.y != null) ? obj.y : 0;
		var ow:Float = (obj.width != null) ? obj.width : 0;
		var oh:Float = (obj.height != null) ? obj.height : 0;

		if (ow <= 0 || oh <= 0)
			return false;

		var objRect:FlxRect = FlxRect.get(ox, oy, ow, oh);

		var pBox:FlxRect = getCollisionBox();
		pBox.x -= 5;
		pBox.y -= 5;
		pBox.width += 10;
		pBox.height += 10;

		var overlapping:Bool = pBox.overlaps(objRect);

		pBox.put();
		objRect.put();

		return overlapping;
	}

	function checkCollision(targetX:Float, targetY:Float):Bool {
		var pBox = getCollisionBoxAt(targetX, targetY);
		var hit = false;
		var room = RoomManager.instance;

		if (room != null) {
			var shapes = room.getNodesOfType(CollisionShape2D);
			for (cShape in shapes) {
				var sx = cShape.scale.x;
				var sy = cShape.scale.y;
				var sBox = FlxRect.get(cShape.x - (cShape.offset.x * sx), cShape.y - (cShape.offset.y * sy), cShape.width * sx, cShape.height * sy);

				if (pBox.overlaps(sBox)) {
					hit = true;
					sBox.put();
					break;
				}
				sBox.put();
			}

			if (!hit) {
				var polys = room.getNodesOfType(CollisionPolygon2D);
				for (cPoly in polys) {
					if (checkPolygonCollision(pBox, cPoly)) {
						hit = true;
						break;
					}
				}
			}

			if (!hit) {
				var entities = room.getNodesOfType(Character);
				for (entity in entities) {
					if (entity == null || entity == this || !entity.solidCollision)
						continue;

					var eBox = entity.getCollisionBox();
					if (pBox.overlaps(eBox)) {
						hit = true;
						eBox.put();
						break;
					}
					eBox.put();
				}
			}
		}

		pBox.put();
		return hit;
	}

	function checkPolygonCollision(pBox:FlxRect, cPoly:CollisionPolygon2D):Bool {
		var px = cPoly.x;
		var py = cPoly.y;
		var poly = cPoly.polygon;
		if (poly.length < 3)
			return false;

		var minX = poly[0].x;
		var maxX = poly[0].x;
		var minY = poly[0].y;
		var maxY = poly[0].y;
		for (i in 1...poly.length) {
			if (poly[i].x < minX)
				minX = poly[i].x;
			if (poly[i].x > maxX)
				maxX = poly[i].x;
			if (poly[i].y < minY)
				minY = poly[i].y;
			if (poly[i].y > maxY)
				maxY = poly[i].y;
		}

		var polyBounds = FlxRect.get(px + minX, py + minY, maxX - minX, maxY - minY);
		if (!pBox.overlaps(polyBounds)) {
			polyBounds.put();
			return false;
		}
		polyBounds.put();

		var corners = [
			FlxPoint.weak(pBox.x, pBox.y),
			FlxPoint.weak(pBox.x + pBox.width, pBox.y),
			FlxPoint.weak(pBox.x + pBox.width, pBox.y + pBox.height),
			FlxPoint.weak(pBox.x, pBox.y + pBox.height)
		];

		for (c in corners) {
			if (pointInPoly(c.x, c.y, poly, px, py)) {
				c.put();
				return true;
			}
			c.put();
		}

		for (pt in poly) {
			var testPt = FlxPoint.weak(px + pt.x, py + pt.y);
			if (pBox.containsPoint(testPt)) {
				testPt.put();
				return true;
			}
			testPt.put();
		}

		return false;
	}

	function pointInPoly(testx:Float, testy:Float, poly:Array<Vector2>, px:Float, py:Float):Bool {
		var c = false;
		var j = poly.length - 1;
		for (i in 0...poly.length) {
			var vix = poly[i].x + px;
			var viy = poly[i].y + py;
			var vjx = poly[j].x + px;
			var vjy = poly[j].y + py;

			if (((viy > testy) != (vjy > testy)) && (testx < (vjx - vix) * (testy - viy) / (vjy - viy) + vix)) {
				c = !c;
			}
			j = i;
		}
		return c;
	}

	function handleMovement(elapsed:Float):Void {
		var up = Controls.UP || FlxG.keys.anyPressed([W, UP]);
		var down = Controls.DOWN || FlxG.keys.anyPressed([S, DOWN]);
		var left = Controls.LEFT || FlxG.keys.anyPressed([A, LEFT]);
		var right = Controls.RIGHT || FlxG.keys.anyPressed([D, RIGHT]);

		if (up && down)
			up = down = false;
		if (left && right)
			left = right = false;

		var speed = Controls.RUN ? runSpeed : walkSpeed;

		if (up)
			velocity.y -= speed;
		else if (down)
			velocity.y += speed;
		if (left)
			velocity.x -= speed;
		else if (right)
			velocity.x += speed;

		if (velocity.x != 0 && velocity.y != 0) {
			velocity.normalize();
			velocity.scale(speed);
		}
	}
}
