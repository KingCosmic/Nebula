package nebula.Graphics;

import nebula.EntityComponentSystem.Component;

import nebula.Math.Vector;

class ParallaxComponent extends Component {
  parallaxFactor = vec(1.0, 1.0);

  public function new(parallaxFactor?: Vector) {
    super();
    this.parallaxFactor = parallaxFactor ?? this.parallaxFactor;
  }
}
