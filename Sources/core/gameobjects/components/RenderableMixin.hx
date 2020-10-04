package core.gameobjects.components;


/**
 * This is the *minimal* things a gameobject needs to implement
 * to be renderable by the camera and core systems
 */
@mixin interface RenderableMixin extends Alpha extends BlendMode extends Depth extends Flip extends GetBounds extends Mask extends Origin extends Pipeline extends ScrollFactor extends Size extends TextureCrop extends Tint extends TransformMixin extends Visible {}