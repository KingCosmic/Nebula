package nebula.Director;

import nebula.Engine;

import nebula.Color;

import nebula.Graphics;

import nebula.Director.Transition;

interface FadeOptions {
  duration?: Float;
  color?: Color;
}

class FadeInOut extends Transition {
  screenCover!: Rectangle;
  color: Color;
  constructor(options: FadeOptions & TransitionOptions) {
    super({
      ...options,
      duration: options.duration ?? 2000
    });
    this.name = `FadeInOut#${this.id}`;
    this.color = options.color ?? Color.Black;
  }

  public onInitialize(engine: Engine) {
    this.transform.pos = engine.screen.unsafeArea.topLeft;
    this.screenCover = new Rectangle({
      width: engine.screen.resolution.width,
      height: engine.screen.resolution.height,
      color: this.color
    });
    this.graphics.add(this.screenCover);
    this.graphics.opacity = this.progress;
  }

  override onReset() {
    this.graphics.opacity = this.progress;
  }

  override onStart(progress: Float) {
    this.graphics.opacity = progress;
  }

  override onEnd(progress: Float) {
    this.graphics.opacity = progress;
  }

  override onUpdate(progress: Float) {
    this.graphics.opacity = progress;
  }
}
