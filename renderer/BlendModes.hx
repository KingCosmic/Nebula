package core.renderer;

/**
* Phaser Blend Modes.
*/
class BlendModes{

    /**
    * Skips the Blend Mode check in the renderer.
    */
    public static var SKIP_CHECK:Int = -1;
    
    /**
    * Normal blend mode. For Canvas and WebGL.
    * This is the default setting and draws new shapes on top of the existing canvas content.
    */
    public static var NORMAL:Int = 0;
    
    /**
    * Add blend mode. For Canvas and WebGL.
    * Where both shapes overlap the color is determined by adding color values.
    */
    public static var ADD:Int = 1;

    /**
    * Multiply blend mode. For Canvas and WebGL.
    * The pixels are of the top layer are multiplied with the corresponding pixel of the bottom layer. A darker picture is the result.
    */
    public static var MULTIPLY:Int = 2;

    /**
    * Screen blend mode. For Canvas and WebGL.
    * The pixels are inverted, multiplied, and inverted again. A lighter picture is the result (opposite of multiply)
    */
    public static var SCREEN:Int = 3;

    /**
    * Overlay blend mode. For Canvas only.
    * A combination of multiply and screen. Dark parts on the base layer become darker, and light parts become lighter.
    */
    public static var OVERLAY:Int = 4;

    /**
    * Darken blend mode. For Canvas only.
    * Retains the darkest pixels of both layers.
    */
    public static var DARKEN:Int = 5;

    /**
    * Lighten blend mode. For Canvas only.
    * Retains the lightest pixels of both layers.
    */
    public static var LIGHTEN:Int = 6;

    /**
    * Color Dodge blend mode. For Canvas only.
    * Divides the bottom layer by the inverted top layer.
    */
    public static var COLOR_DODGE:Int = 7;

    /**
    * Color Burn blend mode. For Canvas only.
    * Divides the inverted bottom layer by the top layer, and then inverts the result.
    */
    public static var COLOR_BURN:Int = 8;

    /**
    * Hard Light blend mode. For Canvas only.
    * A combination of multiply and screen like overlay, but with top and bottom layer swapped.
    */
    public static var HARD_LIGHT:Int = 9;

    /**
    * Soft Light blend mode. For Canvas only.
    * A softer version of hard-light. Pure black or white does not result in pure black or white.
    */
    public static var SOFT_LIGHT:Int = 10;

    /**
    * Difference blend mode. For Canvas only.
    * Subtracts the bottom layer from the top layer or the other way round to always get a positive value.
    */
    public static var DIFFERENCE:Int = 11;

    /**
    * Exclusion blend mode. For Canvas only.
    * Like difference, but with lower contrast.
    */
    public static var EXCLUSION:Int = 12;

    /**
    * Hue blend mode. For Canvas only.
    * Preserves the luma and chroma of the bottom layer, while adopting the hue of the top layer.
    */
    public static var HUE:Int = 13;

    /**
    * Saturation blend mode. For Canvas only.
    * Preserves the luma and hue of the bottom layer, while adopting the chroma of the top layer.
    */
    public static var SATURATION:Int = 14;

    /**
    * Color blend mode. For Canvas only.
    * Preserves the luma of the bottom layer, while adopting the hue and chroma of the top layer.
    */
    public static var COLOR:Int = 15;

    /**
    * Luminosity blend mode. For Canvas only.
    * Preserves the hue and chroma of the bottom layer, while adopting the luma of the top layer.
    */
    public static var LUMINOSITY:Int = 16;

    /**
    * Alpha erase blend mode. For Canvas and WebGL.
    */
    public static var ERASE:Int = 17;

    /**
    * Source-in blend mode. For Canvas only.
    * The new shape is drawn only where both the new shape and the destination canvas overlap. Everything else is made transparent.
    */
    public static var SOURCE_IN:Int = 18;

    /**
    * Source-out blend mode. For Canvas only.
    * The new shape is drawn where it doesn't overlap the existing canvas content.
    */
    public static var SOURCE_OUT:Int = 19;

    /**
    * Source-out blend mode. For Canvas only.
    * The new shape is only drawn where it overlaps the existing canvas content.
    */
    public static var SOURCE_ATOP:Int = 20;

    /**
    * Destination-over blend mode. For Canvas only.
    * New shapes are drawn behind the existing canvas content.
    */
    public static var DESTINATION_OVER:Int = 21;

    /**
    * Destination-in blend mode. For Canvas only.
    * The existing canvas content is kept where both the new shape and existing canvas content overlap. Everything else is made transparent.
    */
    public static var DESTINATION_IN:Int = 22;

    /**
    * Destination-out blend mode. For Canvas only.
    * The existing content is kept where it doesn't overlap the new shape.
    */
    public static var DESTINATION_OUT:Int = 23;

    /**
    * Destination-out blend mode. For Canvas only.
    * The existing canvas is only kept where it overlaps the new shape. The new shape is drawn behind the canvas content.
    */
    public static var DESTINATION_ATOP:Int = 24;

    /**
    * Lighten blend mode. For Canvas only.
    * Where both shapes overlap the color is determined by adding color values.
    */
    public static var LIGHTER:Int = 25;

    /**
    * Copy blend mode. For Canvas only.
    * Only the new shape is shown.
    */
    public static var COPY:Int = 26;

    /**
    * Xor blend mode. For Canvas only.
    * Shapes are made transparent where both overlap and drawn normal everywhere else.
    */
    public static var XOR:Int = 27;
}