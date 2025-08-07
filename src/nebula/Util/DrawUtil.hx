package nebula.util;

import nebula.Color;

import nebula.math.Vector;

/**
 * A canvas linecap style. "butt" is the default flush style, "round" is a semi-circle cap with a radius half the width of
 * the line, and "square" is a rectangle that is an equal width and half height cap.
 */
enum LineCapStyle {
  Butt;
  Round;
  Square;
}

/**
 * Represents border radius values
 */
interface BorderRadius {
  /**
   * Top-left
   */
  var tl: Int;
  /**
   * Top-right
   */
  var tr: Int;
  /**
   * Bottom-right
   */
  var br: Int;
  /**
   * Bottom-left
   */
  var bl: Int;
}

class DrawUtil {
  /**
   * Draw a line on canvas context
   * @param ctx The canvas context
   * @param color The color of the line
   * @param x1 The start x coordinate
   * @param y1 The start y coordinate
   * @param x2 The ending x coordinate
   * @param y2 The ending y coordinate
   * @param thickness The line thickness
   * @param cap The {@apilink LineCapStyle} (butt, round, or square)
   */
  static public function line(
    ctx: CanvasRenderingContext2D,
    color: Color = Color.Red,
    x1: Int,
    y1: Int,
    x2: Int,
    y2: Int,
    thickness: Int = 1,
    cap: LineCapStyle = 'butt'
  ) {
    ctx.save();
    ctx.beginPath();
    ctx.lineWidth = thickness;
    ctx.lineCap = cap;
    ctx.strokeStyle = color.toString();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.closePath();
    ctx.stroke();
    ctx.restore();
  }

  /**
   * Draw the vector as a point onto the canvas.
   */
  public static function point(ctx: CanvasRenderingContext2D, color: Color = Color.Red, point: Vector): Void {
    ctx.beginPath();
    ctx.strokeStyle = color.toString();
    ctx.arc(point.x, point.y, 5, 0, Math.PI * 2);
    ctx.closePath();
    ctx.stroke();
  }

  /**
   * Draw the vector as a line onto the canvas starting a origin point.
   */
  public static function vector(ctx: CanvasRenderingContext2D, color: Color, origin: Vector, vector: Vector, scale: Float = 1.0): Void {
    final c = color ? color.toString() : 'blue';
    final v = vector.scale(scale);
    ctx.beginPath();
    ctx.strokeStyle = c;
    ctx.moveTo(origin.x, origin.y);
    ctx.lineTo(origin.x + v.x, origin.y + v.y);
    ctx.closePath();
    ctx.stroke();
  }

  /**
   * Draw a round rectangle on a canvas context
   * @param ctx The canvas context
   * @param x The top-left x coordinate
   * @param y The top-left y coordinate
   * @param width The width of the rectangle
   * @param height The height of the rectangle
   * @param radius The border radius of the rectangle
   * @param stroke The {@apilink Color} to stroke rectangle with
   * @param fill The {@apilink Color} to fill rectangle with
   */
  public static function roundRect(
    ctx: CanvasRenderingContext2D,
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    radius: Int = 5,
    stroke: Null<Color> = Color.White,
    fill: Null<Color> = null
  ) {
    var br: BorderRadius;

    if (Std.isOfType(radius, Int)) {
      br = { tl: radius, tr: radius, br: radius, bl: radius };
    } else {
      final defaultRadius: BorderRadius = { tl: 0, tr: 0, br: 0, bl: 0 };

      for (prop in defaultRadius) {
        if (defaultRadius.hasOwnProperty(prop)) {
          final side = prop;
          br[side] = radius[side] || defaultRadius[side];
        }
      }
    }

    ctx.beginPath();
    ctx.moveTo(x + br.tl, y);
    ctx.lineTo(x + width - br.tr, y);
    ctx.quadraticCurveTo(x + width, y, x + width, y + br.tr);
    ctx.lineTo(x + width, y + height - br.br);
    ctx.quadraticCurveTo(x + width, y + height, x + width - br.br, y + height);
    ctx.lineTo(x + br.bl, y + height);
    ctx.quadraticCurveTo(x, y + height, x, y + height - br.bl);
    ctx.lineTo(x, y + br.tl);
    ctx.quadraticCurveTo(x, y, x + br.tl, y);
    ctx.closePath();

    if (fill) {
      ctx.fillStyle = fill.toString();
      ctx.fill();
    }

    if (stroke) {
      ctx.strokeStyle = stroke.toString();
      ctx.stroke();
    }
  }

  /**
   *
   */
  public static function circle(
    ctx: CanvasRenderingContext2D,
    x: Int,
    y: Int,
    radius: Int,
    stroke: Color = Color.White,
    ?fill: Color = null
  ) {
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, Math.PI * 2);
    ctx.closePath();

    if (fill) {
      ctx.fillStyle = fill.toString();
      ctx.fill();
    }

    if (stroke) {
      ctx.strokeStyle = stroke.toString();
      ctx.stroke();
    }
  }
}