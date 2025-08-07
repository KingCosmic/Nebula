package nebula.graphics;

import nebula.graphics.GraphicsComponent;

import nebula.Events;
import nebula.Scene;
import nebula.Screen;

import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.System;

import nebula.graphics.ParallaxComponent;

import nebula.math.Vector;
import nebula.math.CoordPlane;

import nebula.Camera;

import nebula.collision.BoundingBox;

class OffscreenSystem extends System {
  static var priority: Int = SystemPriority.Higher;

  public var systemType = SystemType.Draw;
  private var _camera: Camera;
  private var _screen: Screen;
  private var _worldBounds: BoundingBox;
  var query: Query;

  public function new(world: World) {
    super();
    this.query = this.world.query([TransformComponent, GraphicsComponent]);
  }

  public function initialize(world: World, scene: Scene): Void {
    this._camera = scene.camera;
    this._screen = scene.engine.screen;
  }

  function update(): Void {
    this._worldBounds = this._screen.getWorldBounds();
    var transform: TransformComponent;
    var graphics: GraphicsComponent;
    var maybeParallax: Null<ParallaxComponent>;

    for (i in 0...this.query.entities.length) {
      final entity = this.query.entities[i];
      graphics = entity.get(GraphicsComponent);
      transform = entity.get(TransformComponent);
      maybeParallax = entity.get(ParallaxComponent);

      var parallaxOffset: Null<Vector>;
      if (maybeParallax) {
        // We use the Tiled formula
        // https://doc.mapeditor.org/en/latest/manual/layers/#parallax-scrolling-factor
        // cameraPos * (1 - parallaxFactor)
        final oneMinusFactor = Vector.One.sub(maybeParallax.parallaxFactor);
        parallaxOffset = this._camera.pos.scale(oneMinusFactor);
      }

      // Figure out if entities are offscreen
      final entityOffscreen = this._isOffscreen(transform, graphics, parallaxOffset);
      if (entityOffscreen && !entity.hasTag('ex.offscreen')) {
        entity.events.emit('exitviewport', new ExitViewPortEvent(entity));
        entity.addTag('ex.offscreen');
      }

      if (!entityOffscreen && entity.hasTag('ex.offscreen')) {
        entity.events.emit('enterviewport', new EnterViewPortEvent(entity));
        entity.removeTag('ex.offscreen');
      }
    }
  }

  private function _isOffscreen(transform: TransformComponent, graphics: GraphicsComponent, ?parallaxOffset: Vector) {
    if (graphics.forceOnScreen) {
      return false;
    }
    if (transform.coordPlane == CoordPlane.World) {
      var bounds = graphics.localBounds;
      if (parallaxOffset) {
        bounds = bounds.translate(parallaxOffset);
      }
      final transformedBounds = bounds.transform(transform.get().matrix);
      final graphicsOffscreen = !this._worldBounds.overlaps(transformedBounds);
      return graphicsOffscreen;
    } else {
      // TODO screen coordinates
      return false;
    }
  }
}
