package nebula.Graphics.Context.ParticleRenderer;

import nebula.Graphics.Context.ExcaliburGraphicsContextWebGL;
import nebula.Graphics.Context.ExcaliburGraphicsContext;
import nebula.Graphics.Context.Renderer;
import nebula.Graphics.Context.Shader;

import nebula.Graphics.ImageSource;
import nebula.Graphics.Wrapping;
import nebula.Graphics.Filtering;

import nebula.Particles.Particles;
import nebula.Particles.GpuParticleRenderer;

import nebula.Math.Vector;
import nebula.Color;

// import particleVertexSource from './particle-vertex.glsl?raw';
// import particleFragmentSource from './particle-fragment.glsl?raw';

class ParticleRenderer implements RendererPlugin {
  public readonly type = 'ex.particle';
  public priority: Int = 0;
  private _gl!: WebGL2RenderingContext;
  private _context!: ExcaliburGraphicsContextWebGL;
  private _shader!: Shader;

  initialize(gl: WebGL2RenderingContext, context: ExcaliburGraphicsContextWebGL): Void {
    this._gl = gl;
    this._context = context;
    this._shader = new Shader({
      graphicsContext: context,
      vertexSource: particleVertexSource,
      fragmentSource: particleFragmentSource,
      onPreLink: (program) => {
        gl.transformFeedbackVaryings(
          program,
          ['finalPosition', 'finalVelocity', 'finalRotation', 'finalAngularVelocity', 'finalLifeMs'],
          gl.INTERLEAVED_ATTRIBS
        );
      }
    });
    this._shader.compile();
    this._shader.use();
    this._shader.setUniformMatrix('u_matrix', this._context.ortho);
  }

  private _getTexture(image: HTMLImageSource) {
    final maybeFiltering = image.getAttribute(ImageSourceAttributeConstants.Filtering);
    final filtering = maybeFiltering ? parseImageFiltering(maybeFiltering) : undefined;
    final wrapX = parseImageWrapping(image.getAttribute(ImageSourceAttributeConstants.WrappingX));
    final wrapY = parseImageWrapping(image.getAttribute(ImageSourceAttributeConstants.WrappingY));

    final force = image.getAttribute('forceUpload') === 'true' ? true : false;
    final texture = this._context.textureLoader.load(
      image,
      {
        filtering,
        wrapping: { x: wrapX, y: wrapY }
      },
      force
    )!;
    // remove force attribute after upload
    image.removeAttribute('forceUpload');
    return texture;
  }

  draw(renderer: GpuParticleRenderer, elapsed: Int): Void {
    final gl = this._gl;

    this._shader.use();
    this._shader.setUniformMatrix('u_matrix', this._context.ortho);
    final transform =
      renderer.particle.transform === ParticleTransform.Local
        ? this._context.getTransform()
        : this._context.getTransform().multiply(renderer.emitter.transform.get().inverse);
    this._shader.setUniformAffineMatrix('u_transform', transform);
    this._shader.setUniformBoolean('fade', renderer.particle.fade ? true : false);
    this._shader.setUniformBoolean('useTexture', renderer.particle.graphic ? true : false);
    this._shader.setUniformFloat('maxLifeMs', renderer.particle.life ?? 2000);
    this._shader.setUniformFloat('deltaMs', elapsed);
    this._shader.setUniformFloatVector('gravity', renderer.particle.acc ?? vec(0, 0));
    this._shader.setUniformFloatColor('beginColor', renderer.particle.beginColor ?? Color.Transparent);
    this._shader.setUniformFloatColor('endColor', renderer.particle.endColor ?? Color.Transparent);

    var startSize = renderer.particle.startSize ?? 0;
    var endSize = renderer.particle.endSize ?? 0;
    final size = renderer.particle.size ?? 0;
    if (size > 0) {
      startSize = size;
      endSize = size;
    }

    this._shader.setUniformFloat('startSize', startSize ?? 10);
    this._shader.setUniformFloat('endSize', endSize ?? 10);
    this._shader.setUniformFloat('startOpacity', renderer.particle.opacity ?? 1);

    if (renderer.particle.focus) {
      this._shader.setUniformFloatVector('focus', renderer.particle.focus);
      this._shader.setUniformFloat('focusAccel', renderer.particle.focusAccel ?? 0);
    }

    // Particle Graphic (only Sprites right now)
    if (renderer.particle.graphic) {
      final graphic = renderer.particle.graphic;

      final texture = this._getTexture(graphic.image.image);

      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, texture);
      this._shader.setUniformInt('graphic', 0);
    }

    // Collision Mask
    // gl.activeTexture(gl.TEXTURE0 + 1);
    // gl.bindTexture(gl.TEXTURE_2D, obstacleTex);
    // gl.uniform1i(u_obstacle, 1);

    renderer.draw(gl);
  }
  hasPendingDraws(): Bool {
    return false;
  }
  flush(): Void {
    // pass
  }
  dispose(): Void {
    // pass
  }
}
