package engine.objects;

import lime.math.Vector2;
import godot.nodes.CollisionShape2D;
import godot.nodes.CollisionPolygon2D;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.FlxG;

class Player extends Character {
	public var disableRunning:Bool = false;

	public function new(x:Float, y:Float, zIndex:Int, name:String) {
		super(x, y, zIndex, name);
		baseSpeed = 160;
		runMultiplier = 1.75;
		runningThreshold = 200;
	}

	override public function update(elapsed:Float):Void {
		var up = Controls.UP_P;
		var down = Controls.DOWN_P;
		var left = Controls.LEFT_P;
		var right = Controls.RIGHT_P;
		if (movementEnabled && !isFollowingPath) {
			var move = getMovementDelta(elapsed);

			if (left)
				direction = LEFT;
			else if (right)
				direction = RIGHT;
			else if (up)
				direction = UP;
			else if (down)
				direction = DOWN;

			if (move.x != 0 || move.y != 0) {
				var stepX = move.x;
				var stepY = move.y;

				if (stepX != 0 && !isCollidingAt(x + stepX, y))
					x += Math.round(stepX);

				if (stepY != 0 && !isCollidingAt(x, y + stepY))
					y += Math.round(stepY);
			}

			move.put();
		}

		super.update(elapsed);
	}

	override function updatePathMovement(elapsed:Float):Void {
		if (pathTarget == null)
			return;

		var dx = pathTarget.x - x;
		var dy = pathTarget.y - y;
		var distSq = dx * dx + dy * dy;
		var step = baseSpeed * elapsed;

		if (distSq <= step * step) {
			x = Math.round(pathTarget.x);
			y = Math.round(pathTarget.y);
			isFollowingPath = false;
			pathTarget.put();
			pathTarget = null;

			if (onPathComplete != null) {
				var cb = onPathComplete;
				onPathComplete = null;
				cb();
			}
		} else {
			var dist = Math.sqrt(distSq);
			x += Math.round((dx / dist) * step);
			y += Math.round((dy / dist) * step);
		}
	}

	public function checkCollisionObject(other:Dynamic):Bool {
		if (other == null)
			return false;

		var ox:Float = (other.x != null) ? other.x : 0;
		var oy:Float = (other.y != null) ? other.y : 0;
		var ow:Float = (other.width != null) ? other.width : 0;
		var oh:Float = (other.height != null) ? other.height : 0;

		if (ow <= 0 || oh <= 0)
			return false;

		var objRect = FlxRect.get(ox, oy, ow, oh);
		var pBoxes = getCollisionBoxes();
		var overlapping = false;

		for (pBox in pBoxes) {
			pBox.x -= 5;
			pBox.y -= 5;
			pBox.width += 10;
			pBox.height += 10;

			if (pBox.overlaps(objRect)) {
				overlapping = true;
				break;
			}
		}

		for (pBox in pBoxes)
			pBox.put();
		objRect.put();

		return overlapping;
	}

	function isCollidingAt(targetX:Float, targetY:Float):Bool {
		var hit = false;
		var pBoxes = getCollisionBoxes();

		for (pBox in pBoxes) {
			pBox.x += targetX - x;
			pBox.y += targetY - y;
		}

		if (Game.room != null) {
			for (shape in Game.room.scene.getNodesOfType(CollisionShape2D)) {
				var sx = shape.scale.x;
				var sy = shape.scale.y;
				var sBox = FlxRect.get(shape.x - (shape.offset.x * sx), shape.y - (shape.offset.y * sy), shape.width * sx, shape.height * sy);

				for (pBox in pBoxes) {
					if (pBox.overlaps(sBox)) {
						hit = true;
						break;
					}
				}
				sBox.put();
				if (hit)
					break;
			}

			if (!hit) {
				for (poly in Game.room.scene.getNodesOfType(CollisionPolygon2D)) {
					for (pBox in pBoxes) {
						if (isPolygonOverlapping(pBox, poly)) {
							hit = true;
							break;
						}
					}
					if (hit)
						break;
				}
			}

			if (!hit) {
				for (entity in Game.room.scene.getNodesOfType(Character)) {
					if (entity == null || entity == this || !entity.isSolid)
						continue;

					var eBoxes = entity.getCollisionBoxes();

					for (pBox in pBoxes) {
						for (eBox in eBoxes) {
							if (pBox.overlaps(eBox)) {
								hit = true;
								break;
							}
						}
						if (hit)
							break;
					}
					for (eBox in eBoxes)
						eBox.put();
					if (hit)
						break;
				}
			}
		}

		for (pBox in pBoxes)
			pBox.put();
		return hit;
	}

	function isPolygonOverlapping(rect:FlxRect, polyNode:CollisionPolygon2D):Bool {
		var px = polyNode.x;
		var py = polyNode.y;
		var poly = polyNode.polygon;
		if (poly.length < 3)
			return false;

		var minX = poly[0].x;
		var maxX = poly[0].x;
		var minY = poly[0].y;
		var maxY = poly[0].y;
		for (i in 1...poly.length) {
			var pt = poly[i];
			if (pt.x < minX)
				minX = pt.x;
			if (pt.x > maxX)
				maxX = pt.x;
			if (pt.y < minY)
				minY = pt.y;
			if (pt.y > maxY)
				maxY = pt.y;
		}

		var polyBounds = FlxRect.get(px + minX, py + minY, maxX - minX, maxY - minY);
		if (!rect.overlaps(polyBounds)) {
			polyBounds.put();
			return false;
		}
		polyBounds.put();

		var corners = [
			FlxPoint.weak(rect.x, rect.y),
			FlxPoint.weak(rect.x + rect.width, rect.y),
			FlxPoint.weak(rect.x + rect.width, rect.y + rect.height),
			FlxPoint.weak(rect.x, rect.y + rect.height)
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
			if (rect.containsPoint(testPt)) {
				testPt.put();
				return true;
			}
			testPt.put();
		}

		return false;
	}

	function pointInPoly(testX:Float, testY:Float, poly:Array<Vector2>, offsetX:Float, offsetY:Float):Bool {
		var inside = false;
		var j = poly.length - 1;
		for (i in 0...poly.length) {
			var ix = poly[i].x + offsetX;
			var iy = poly[i].y + offsetY;
			var jx = poly[j].x + offsetX;
			var jy = poly[j].y + offsetY;

			if (((iy > testY) != (jy > testY)) && (testX < (jx - ix) * (testY - iy) / (jy - iy) + ix))
				inside = !inside;

			j = i;
		}
		return inside;
	}

	function getMovementDelta(elapsed:Float):FlxPoint {
		var up = Controls.UP || FlxG.keys.anyPressed([W, UP]);
		var down = Controls.DOWN || FlxG.keys.anyPressed([S, DOWN]);
		var left = Controls.LEFT || FlxG.keys.anyPressed([A, LEFT]);
		var right = Controls.RIGHT || FlxG.keys.anyPressed([D, RIGHT]);

		if (up && down)
			up = down = false;
		if (left && right)
			left = right = false;

		var speed = (!disableRunning && Controls.RUN) ? (baseSpeed * runMultiplier) : baseSpeed;
		var dx:Float = 0;
		var dy:Float = 0;

		if (up)
			dy -= speed;
		else if (down)
			dy += speed;
		if (left)
			dx -= speed;
		else if (right)
			dx += speed;

		if (dx != 0 && dy != 0) {
			var norm = 1 / Math.sqrt(2);
			dx *= norm;
			dy *= norm;
		}

		return FlxPoint.get(dx * elapsed, dy * elapsed);
	}
}
