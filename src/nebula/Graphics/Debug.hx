package nebula.Graphics;

import nebula.Math.Vector;

import nebula.Graphics.Context.ExcaliburGraphicsContext;

import nebula.Color;

import nebula.Math.Ray;
import nebula.Collision.BoundingBox;

class Debug {
  static _drawCalls: ((ctx: ExcaliburGraphicsContext) => Void)[] = [];
  static _ctx: ExcaliburGraphicsContext;
  static z: number = Infinity;
  static registerGraphicsContext(ctx: ExcaliburGraphicsContext) {
    Debug._ctx = ctx;
  }
  static draw(debugDrawCall: (ctx: ExcaliburGraphicsContext) => Void) {
    this._drawCalls.push(debugDrawCall);
  }

  static drawPoint(point: Vector, options?: PointGraphicsOptions) {
    Debug.draw((ctx) => {
      ctx.debug.drawPoint(point, options);
    });
  }

  static drawLine(start: Vector, end: Vector, options?: LineGraphicsOptions) {
    Debug.draw((ctx) => {
      ctx.debug.drawLine(start, end, options);
    });
  }

  static drawLines(points: Vector[], options?: LineGraphicsOptions) {
    if (points.length > 1) {
      Debug.draw((ctx) => {
        for (var i = 0; i < points.length - 1; i++) {
          ctx.debug.drawLine(points[i], points[i + 1], options);
        }
      });
    }
  }

  static drawText(text: String, pos: Vector) {
    Debug.draw((ctx) => {
      ctx.debug.drawText(text, pos);
    });
  }

  static drawPolygon(points: Vector[], options?: { color?: Color }) {
    if (points.length > 1) {
      Debug.draw((ctx) => {
        final firstPoint = points[0];
        final polygon = [...points, firstPoint];
        for (var i = 0; i < polygon.length - 1; i++) {
          ctx.debug.drawLine(polygon[i], polygon[i + 1], options);
        }
      });
    }
  }

  static drawCircle(
    center: Vector,
    radius: Float,
    options?: {
      color?: Color;
      strokeColor?: Color;
      width?: Int;
    }
  ) {
    final { color, strokeColor, width } = {
      color: Color.Black,
      strokeColor: undefined,
      width: undefined,
      ...options
    };
    Debug.draw((ctx) => {
      ctx.drawCircle(center, radius, color, strokeColor, width);
    });
  }

  static drawBounds(boundingBox: BoundingBox, options?: { color?: Color }): Void {
    Debug.draw((ctx) => {
      ctx.debug.drawRect(boundingBox.left, boundingBox.top, boundingBox.width, boundingBox.height, options);
    });
  }

  static drawRay(ray: Ray, options?: { distance?: Int; color?: Color }) {
    final { distance, color } = {
      color: Color.Blue,
      distance: 10,
      ...options
    };
    Debug.draw((ctx) => {
      final start = ray.pos;
      final end = ray.pos.add(ray.dir.scale(distance));

      ctx.debug.drawLine(start, end, { color });
    });
  }

  static flush(ctx: ExcaliburGraphicsContext) {
    ctx.save();
    ctx.z = Debug.z;
    for (final drawCall of Debug._drawCalls) {
      drawCall(ctx);
    }
    ctx.restore();
    Debug.clear();
  }

  static clear() {
    Debug._drawCalls.length = 0;
  }
}
