package nebula.Graphics;

import nebula.Graphics.GraphicsComponent;

import nebula.Events;
import nebula.Scene;
import nebula.Screen;

import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.System;

import nebula.Graphics.ParallaxComponent;

import nebula.Math.Vector;
import nebula.Math.CoordPlane;

import nebula.Camera;

import nebula.Collision.BoundingBox;

import nebula.EntityComponentSystem;

class OffscreenSystem extends System {
  static priority: Int = SystemPriority.Higher;

  public systemType = SystemType.Draw;
  private _camera!: Camera;
  private _screen!: Screen;
  private _worldBounds!: BoundingBox;
  query: Query<typeof TransformComponent | typeof GraphicsComponent>;

  public function new(public world: World) {
    super();
    this.query = this.world.query([TransformComponent, GraphicsComponent]);
  }

  public initialize(world: World, scene: Scene): Void {
    this._camera = scene.camera;
    this._screen = scene.engine.screen;
  }

  update(): void {
    this._worldBounds = this._screen.getWorldBounds();
    var transform: TransformComponent;
    var graphics: GraphicsComponent;
    var maybeParallax: ParallaxComponent | undefined;

    for (var i = 0; i < this.query.entities.length; i++) {
      final entity = this.query.entities[i];
      graphics = entity.get(GraphicsComponent);
      transform = entity.get(TransformComponent);
      maybeParallax = entity.get(ParallaxComponent);

      var parallaxOffset: Vector | undefined;
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

  private _isOffscreen(transform: TransformComponent, graphics: GraphicsComponent, parallaxOffset: Vector | undefined) {
    if (graphics.forceOnScreen) {
      return false;
    }
    if (transform.coordPlane === CoordPlane.World) {
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
