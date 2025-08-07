package nebula.graphics;

import nebula.math.Vector;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.Color;

import nebula.math.Ray;
import nebula.collision.BoundingBox;

class Debug {
  static var _drawCalls: Array<((ctx: ExcaliburGraphicsContext) -> Void)> = [];
  static var _ctx: ExcaliburGraphicsContext;
  static var z: Int = Infinity;
  static function registerGraphicsContext(ctx: ExcaliburGraphicsContext) {
    Debug._ctx = ctx;
  }
  static function draw(debugDrawCall: (ctx: ExcaliburGraphicsContext) -> Void) {
    this._drawCalls.push(debugDrawCall);
  }

  static function drawPoint(point: Vector, ?options: PointGraphicsOptions) {
    Debug.draw((ctx) => {
      ctx.debug.drawPoint(point, options);
    });
  }

  static function drawLine(start: Vector, end: Vector, ?options: LineGraphicsOptions) {
    Debug.draw((ctx) => {
      ctx.debug.drawLine(start, end, options);
    });
  }

  static function drawLines(points: Array<Vector>, ?options: LineGraphicsOptions) {
    if (points.length > 1) {
      Debug.draw((ctx) -> {
        for (i in 0...points.length - 1) {
          ctx.debug.drawLine(points[i], points[i + 1], options);
        }
      });
    }
  }

  static function drawText(text: String, pos: Vector) {
    Debug.draw((ctx) => {
      ctx.debug.drawText(text, pos);
    });
  }

  static function drawPolygon(points: Array<Vector>, ?options: { color: Null<Color> }) {
    if (points.length > 1) {
      Debug.draw((ctx) -> {
        final firstPoint = points[0];
        final polygon = [...points, firstPoint];
        for (i in 0...polygon.length - 1) {
          ctx.debug.drawLine(polygon[i], polygon[i + 1], options);
        }
      });
    }
  }

  static function drawCircle(
    center: Vector,
    radius: Float,
    ?options: {
      color: Null<Color>,
      strokeColor: Null<Color>,
      width: Null<Int>
    }
  ) {
    final mergedOptions = Object.spreadWith({ color: Color.Black, strokeColor: null, width: null }, options);
    final color = mergedOptions.color,
          strokeColor = mergedOptions.strokeColor,
          width = mergedOptions.width;

    Debug.draw((ctx) => {
      ctx.drawCircle(center, radius, color, strokeColor, width);
    });
  }

  static function drawBounds(boundingBox: BoundingBox, ?options: { color: Null<Color> }): Void {
    Debug.draw((ctx) -> {
      ctx.debug.drawRect(boundingBox.left, boundingBox.top, boundingBox.width, boundingBox.height, options);
    });
  }

  static function drawRay(ray: Ray, ?options: { distance: Null<Int>, color: Null<Color> }) {
    final mergedOptions = Object.spreadWith({ color: Color.Blue, distance: 10 }, options);
    final distance = mergedOptions.distance,
          color = mergedOptions.color;

    Debug.draw((ctx) -> {
      final start = ray.pos;
      final end = ray.pos.add(ray.dir.scale(distance));

      ctx.debug.drawLine(start, end, { color: color });
    });
  }

  static function flush(ctx: ExcaliburGraphicsContext) {
    ctx.save();
    ctx.z = Debug.z;
    for (drawCall in Debug._drawCalls) {
      drawCall(ctx);
    }
    ctx.restore();
    Debug.clear();
  }

  static function clear() {
    Debug._drawCalls.length = 0;
  }
}
