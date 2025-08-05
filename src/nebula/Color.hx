package nebula;

/**
 * Provides standard colors (e.g. {@apilink Color.Black})
 * but you can also create custom colors using RGB, HSL, or Hex. Also provides
 * useful color operations like {@apilink Color.lighten}, {@apilink Color.darken}, and more.
 */
class Color {
  /**
   * Red channel
   */
  public var r: Int;
  /**
   * Green channel
   */
  public var g: Int;
  /**
   * Blue channel
   */
  public var b: Int;
  /**
   * Alpha channel (between 0 and 1)
   */
  public var a: Float;

  /**
   * Hue
   */
  public var h: Float;
  /**
   * Saturation
   */
  public var s: Float;
  /**
   * Lightness
   */
  public var l: Float;

  /**
   * Creates a new instance of Color from an r, g, b, a
   * @param r  The red component of color (0-255)
   * @param g  The green component of color (0-255)
   * @param b  The blue component of color (0-255)
   * @param a  The alpha component of color (0-1.0)
   */
  public function new(r: Int, g: Int, b: Int, ?a: Float) {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a != null ? a : 1;
  }

  /**
   * Creates a new instance of Color from an r, g, b, a
   * @param r  The red component of color (0-255)
   * @param g  The green component of color (0-255)
   * @param b  The blue component of color (0-255)
   * @param a  The alpha component of color (0-1.0)
   */
  public static function fromRGB(r: Int, g: Int, b: Int, ?a: Float): Color {
    return new Color(r, g, b, a);
  }

  /**
   * Creates a new instance of Color from a rgb string
   * @param string  CSS color string of the form rgba(255, 255, 255, 1) or rgb(255, 255, 255)
   */
  public static function fromRGBString(string: String): Color {
    var rgbaRegEx = ~/^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*(\d+(?:\.\d+)?))?\)/i;

    if (rgbaRegEx.match(string)) {
      var r = Std.parseInt(rgbaRegEx.matched(1));
      var g = Std.parseInt(rgbaRegEx.matched(2));
      var b = Std.parseInt(rgbaRegEx.matched(3));
      var a = 1.0;

      var alpha = rgbaRegEx.matched(4);
      if (alpha != '') {
        a = Std.parseInt(rgbaRegEx.matched(3));
      }
      return new Color(r, g, b, a);
    } else {
      trace('Invalid rgb/a string: ' + string);

      return Color.Black;
    }
  }

  /**
   * Creates a new instance of Color from a hex string
   * @param hex  CSS color string of the form #ffffff, the alpha component is optional
   */
  public static function fromHex(hex: String): Color {
    var hexRegEx = ~/^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})?$/i;
    if (hexRegEx.match(hex)) {
      var r = Std.parseInt("0x" + hexRegEx.matched(1));
      var g = Std.parseInt("0x" + hexRegEx.matched(2));
      var b = Std.parseInt("0x" + hexRegEx.matched(3));
      var a = 1.0;

      var alpha = hexRegEx.matched(4);
      if (alpha != '') {
        a = Std.parseInt("0x" + hexRegEx.matched(3)) / 255;
      }
      return new Color(r, g, b, a);
    } else {
      trace('Invalid hex string: ' + hex);

      return Color.Black;
    }
  }

  /**
   * Creates a new instance of Color from hsla values
   * @param h  Hue is represented [0-1]
   * @param s  Saturation is represented [0-1]
   * @param l  Luminance is represented [0-1]
   * @param a  Alpha is represented [0-1]
   */
  // public static function fromHSL(h: Float, s: Float, l: Float, a: Float = 1.0): Color {
  //   final temp = new HSLColor(h, s, l, a);
  //   return temp.toRGBA();
  // }

  /**
   * Lightens the current color by a specified amount
   * @param factor  The amount to lighten by [0-1]
   */
  // public function lighten(factor: Float = 0.1): Color {
  //   var temp: HSLColor = HSLColor.fromRGBA(this.r, this.g, this.b, this.a);
  //   temp.l += (1 - temp.l) * factor;
  //   return temp.toRGBA();
  // }

  /**
   * Darkens the current color by a specified amount
   * @param factor  The amount to darken by [0-1]
   */
  // public function darken(factor: Float = 0.1): Color {
  //   var temp = HSLColor.fromRGBA(this.r, this.g, this.b, this.a);
  //   temp.l -= temp.l * factor;
  //   return temp.toRGBA();
  // }

  /**
   * Saturates the current color by a specified amount
   * @param factor  The amount to saturate by [0-1]
   */
  // public function saturate(factor: Float = 0.1): Color {
  //   var temp = HSLColor.fromRGBA(this.r, this.g, this.b, this.a);
  //   temp.s += temp.s * factor;
  //   return temp.toRGBA();
  // }

  /**
   * Desaturates the current color by a specified amount
   * @param factor  The amount to desaturate by [0-1]
   */
  // public function desaturate(factor: Float = 0.1): Color {
  //   var temp = HSLColor.fromRGBA(this.r, this.g, this.b, this.a);
  //   temp.s -= temp.s * factor;
  //   return temp.toRGBA();
  // }

  /**
   * Multiplies a color by another, results in a darker color
   * @param color  The other color
   */
  public function multiply(color: Color): Color {
    var newR = Math.floor((((color.r / 255) * this.r) / 255) * 255);
    var newG = Math.floor((((color.g / 255) * this.g) / 255) * 255);
    var newB = Math.floor((((color.b / 255) * this.b) / 255) * 255);
    var newA = color.a * this.a;
    return new Color(newR, newG, newB, newA);
  }

  /**
   * Screens a color by another, results in a lighter color
   * @param color  The other color
   */
  public function screen(color: Color): Color {
    var color1 = color.invert();
    var color2 = color.invert();
    return color1.multiply(color2).invert();
  }

  /**
   * Inverts the current color
   */
  public function invert(): Color {
    return new Color(255 - this.r, 255 - this.g, 255 - this.b, 1.0 - this.a);
  }

  /**
   * Averages the current color with another
   * @param color  The other color
   */
  public function average(color: Color): Color {
    var newR = Math.floor((color.r + this.r) / 2);
    var newG = Math.floor((color.g + this.g) / 2);
    var newB = Math.floor((color.b + this.b) / 2);
    var newA = (color.a + this.a) / 2;
    return new Color(newR, newG, newB, newA);
  }

  public function equal(color: Color): Bool {
    return this.toString() == color.toString();
  }

  /**
   * Returns a CSS string representation of a color.
   * @param format Color representation, accepts: rgb, hsl, or hex
   */
  public function toString(format: String = 'rgb') {
    switch (format) {
      case 'rgb':
        return this.toRGBA();
      case 'hsl':
        // return this.toHSLA();
        return '';
      case 'hex':
        return this.toHex();
      default:
        trace('Invalid Color format');
        return '';
    }
  }

  /**
   * Returns Hex Value of a color component
   * @param c color component
   * @see https://stackoverflow.com/questions/5623838/rgb-to-hex-and-hex-to-rgb
   */
  private function _componentToHex(c: Float) {
    // Handle negative and fractional numbers
    var hex = "0x" + Std.string(Math.max(Math.round(c), 0));
    return hex.length == 1 ? '0' + hex : hex;
  }

  /**
   * Return Hex representation of a color.
   */
  public function toHex() {
    var hexRepresentation = '#' + this._componentToHex(this.r) + this._componentToHex(this.g) + this._componentToHex(this.b);
    if (this.a != 1) {
      hexRepresentation += this._componentToHex(this.a * 255);
    }
    return hexRepresentation;
  }

  public function toFixed(num:Float, decimals:Int):String {
    var factor = Math.pow(10, decimals);
    return Std.string((Math.round(num * factor) / factor));
  }

  /**
   * Return RGBA representation of a color.
   */
  public function toRGBA() {
    var result = Std.string(this.toFixed(this.r, 0) + ', ' + Std.string(this.toFixed(this.g, 0)) + ', ' + Std.string(this.toFixed(this.b, 0)));
    if (this.a != null) {
      return 'rgba(' + result + ', ' + Std.string(this.a) + ')';
    }
    return 'rgb(' + result + ')';
  }

  /**
   * Return HSLA representation of a color.
   */
  public function toHSLA() {
    // return HSLColor.fromRGBA(this.r, this.g, this.b, this.a).toString();
  }

  /**
   * Returns a CSS string representation of a color.
   */
  public function fillStyle() {
    return this.toString();
  }

  /**
   * Returns a clone of the current color.
   */
  public function clone(?dest: Color): Color {
    var result: Color = (dest != null) ? dest : new Color(this.r, this.g, this.b, this.a);
    result.r = this.r;
    result.g = this.g;
    result.b = this.b;
    result.a = this.a;
    return result;
  }

  /**
   * Black (#000000)
   */
  public static var Black(get, never): Color;
  static function get_Black(): Color {
    return Color.fromHex('#000000');
  }

  /**
   * White (#FFFFFF)
   */
  public static var White(get, never): Color;
  static function get_White(): Color {
    return Color.fromHex('#FFFFFF');
  }

  /**
   * Gray (#808080)
   */
  public static var Gray(get, never): Color;
  static function get_Gray(): Color {
    return Color.fromHex('#808080');
  }

  /**
   * Light gray (#D3D3D3)
   */
  public static var LightGray(get, never): Color;
  static function get_LightGray(): Color {
    return Color.fromHex('#D3D3D3');
  }

  /**
   * Dark gray (#A9A9A9)
   */
  public static var DarkGray(get, never): Color;
  static function get_DarkGray(): Color {
    return Color.fromHex('#A9A9A9');
  }

  /**
   * Yellow (#FFFF00)
   */
  public static var Yellow(get, never): Color;
  static function get_Yellow(): Color {
    return Color.fromHex('#FFFF00');
  }

  /**
   * Orange (#FFA500)
   */
  public static var Orange(get, never): Color;
  static function get_Orange(): Color {
    return Color.fromHex('#FFA500');
  }

  /**
   * Red (#FF0000)
   */
  public static var Red(get, never): Color;
  static function get_Red(): Color {
    return Color.fromHex('#FF0000');
  }

  /**
   * Vermilion (#FF5B31)
   */
  public static var Vermilion(get, never): Color;
  static function get_Vermilion(): Color {
    return Color.fromHex('#FF5B31');
  }

  /**
   * Rose (#FF007F)
   */
  public static var Rose(get, never): Color;
  static function get_Rose(): Color {
    return Color.fromHex('#FF007F');
  }

  /**
   * Pink (#FFC0CB)
   */
  public static var Pink(get, never): Color;
  static function get_Pink(): Color {
    return Color.fromHex('#FFC0CB');
  }

  /**
   * Magenta (#FF00FF)
   */
  public static var Magenta(get, never): Color;
  static function get_Magenta(): Color {
    return Color.fromHex('#FF00FF');
  }

  /**
   * Violet (#7F00FF)
   */
  public static var Violet(get, never): Color;
  static function get_Violet(): Color {
    return Color.fromHex('#7F00FF');
  }

  /**
   * Purple (#800080)
   */
  public static var Purple(get, never): Color;
  static function get_Purple(): Color {
    return Color.fromHex('#800080');
  }

  /**
   * Blue (#0000FF)
   */
  public static var Blue(get, never): Color;
  static function get_Blue(): Color {
    return Color.fromHex('#0000FF');
  }

  /**
   * Azure (#007FFF)
   */
  public static var Azure(get, never): Color;
  static function get_Azure(): Color {
    return Color.fromHex('#007FFF');
  }

  /**
   * Cyan (#00FFFF)
   */
  public static var Cyan(get, never): Color;
  static function get_Cyan(): Color {
    return Color.fromHex('#00FFFF');
  }

  /**
   * Viridian (#59978F)
   */
  public static var Viridian(get, never): Color;
  static function get_Viridian(): Color {
    return Color.fromHex('#59978F');
  }

  /**
   * Teal (#008080)
   */
  public static var Teal(get, never): Color;
  static function get_Teal(): Color {
    return Color.fromHex('#008080');
  }

  /**
   * Green (#00FF00)
   */
  public static var Green(get, never): Color;
  static function get_Green(): Color {
    return Color.fromHex('#00FF00');
  }

  /**
   * Chartreuse (#7FFF00)
   */
  public static var Chartreuse(get, never): Color;
  static function get_Chartreuse(): Color {
    return Color.fromHex('#7FFF00');
  }

  /**
   * Transparent (#FFFFFF00)
   */
  public static var Transparent(get, never): Color;
  static function get_Transparent(): Color {
    return Color.fromHex('#FFFFFF00');
  }

  /**
   * ExcaliburBlue (#176BAA)
   */
  public static var ExcaliburBlue(get, never): Color;
  static function get_ExcaliburBlue(): Color {
    return Color.fromHex('#176BAA');
  }

  /**
   * Brown (#964B00)
   */
  public static var Brown(get, never): Color;
  static function get_Brown(): Color {
    return Color.fromHex('#964B00');
  }
}

/**
 * Internal HSL Color representation
 *
 * http://en.wikipedia.org/wiki/HSL_and_HSV
 * http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
 */
class HSLColor {
  public var h: Float = 0.0;
  public var s: Float = 0.0;
  public var l: Float = 0.0;
  public var a: Float = 0.0;

  public function new(
    h: Float,
    s: Float,
    l: Float,
    a: Float
  ) {}

  public static function hue2rgb(p: Float, q: Float, t: Float): Float {
    if (t < 0) {
      t += 1;
    }
    if (t > 1) {
      t -= 1;
    }
    if (t < 1 / 6) {
      return p + (q - p) * 6 * t;
    }
    if (t < 1 / 2) {
      return q;
    }
    if (t < 2 / 3) {
      return p + (q - p) * (2 / 3 - t) * 6;
    }
    return p;
  }

  // public static function fromRGBA(r: Float, g: Float, b: Float, a: Float): HSLColor {
  //   r /= 255;
  //   g /= 255;
  //   b /= 255;
  //   var max = Math.max(r, g, b),
  //     min = Math.min(r, g, b);
  //   var h, s;
  //   var l = (max + min) / 2;

  //   if (max == min) {
  //     h = s = 0; // achromatic
  //   } else {
  //     var d = max - min;
  //     s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  //     switch (max) {
  //       case r:
  //         h = (g - b) / d + (g < b ? 6 : 0);
  //         break;
  //       case g:
  //         h = (b - r) / d + 2;
  //         break;
  //       case b:
  //         h = (r - g) / d + 4;
  //         break;
  //     }
  //     h /= 6;
  //   }

  //   return new HSLColor(h, s, l, a);
  // }

  // public function toRGBA(): Color {
  //   var r: Int, g: Int, b: Int;

  //   if (this.s == 0) {
  //     r = g = b = this.l; // achromatic
  //   } else {
  //     var q = this.l < 0.5 ? this.l * (1 + this.s) : this.l + this.s - this.l * this.s;
  //     var p = 2 * this.l - q;
  //     r = HSLColor.hue2rgb(p, q, this.h + 1 / 3);
  //     g = HSLColor.hue2rgb(p, q, this.h);
  //     b = HSLColor.hue2rgb(p, q, this.h - 1 / 3);
  //   }

  //   return new Color(r * 255, g * 255, b * 255, this.a);
  // }

  // public function toString(): String {
  //   var h = this.h.toFixed(0),
  //     s = this.s.toFixed(0),
  //     l = this.l.toFixed(0),
  //     a = this.a.toFixed(0);
  //   return 'hsla(${h}, ${s}, ${l}, ${a})';
  // }
}
