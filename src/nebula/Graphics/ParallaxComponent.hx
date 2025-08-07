package nebula.graphics;

import nebula.entitycomponentsystem.Component;

import nebula.math.Vector;

class ParallaxComponent extends Component {
  var parallaxFactor = vec(1.0, 1.0);

  public function new(?parallaxFactor: Vector) {
    super();
    this.parallaxFactor = parallaxFactor ?? this.parallaxFactor;
  }
}
