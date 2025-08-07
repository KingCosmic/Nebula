package nebula.graphics.context;

import nebula.math.Matrix;
import nebula.util.Watch;
import nebula.math.Vector;
import nebula.math.AffineMatrix;
import nebula.graphics.context.UniformBuffer;
import nebula.graphics.context.WebglUtil;
import haxe.io.Float32Array;

enum UniformValue {
  UInt(value:Int);
  Bool(value:Bool);
  Vec(value:Vector);
  Col(value:Color);
  Mat(value:AffineMatrix);
  Buffer(value:Float32Array); // or haxe.io.Float32Array
  BufferWithBinding(buffer:Float32Array, bindingPoint:Int);
}

typedef UniformDictionary = Map<String, UniformValue>;
// /*
//  * List of the possible glsl uniform types
//  */
// enum UniformTypeNames =
//   | 'uniform1f'
//   | 'uniform1i'
//   | 'uniform1ui'
//   | 'uniform2f'
//   | 'uniform2i'
//   | 'uniform2ui'
//   | 'uniform3f'
//   | 'uniform3i'
//   | 'uniform3ui'
//   | 'uniform4f'
//   | 'uniform4i'
//   | 'uniform4ui'
//   | 'uniform1fv'
//   | 'uniform1iv'
//   | 'uniform1uiv'
//   | 'uniform2fv'
//   | 'uniform2iv'
//   | 'uniform2uiv'
//   | 'uniform3fv'
//   | 'uniform3iv'
//   | 'uniform3uiv'
//   | 'uniform4fv'
//   | 'uniform4iv'
//   | 'uniform4uiv'
//   | 'uniformMatrix2fv'
//   | 'uniformMatrix2x3fv'
//   | 'uniformMatrix2x4fv'
//   | 'uniformMatrix3fv'
//   | 'uniformMatrix3x2fv'
//   | 'uniformMatrix3x4fv'
//   | 'uniformMatrix4fv'
//   | 'uniformMatrix4x2fv'
//   | 'uniformMatrix4x3fv';

/**
 *
 */
function glTypeToUniformTypeName(gl: WebGL2RenderingContext, glType: Int): String {
  switch (glType) {
    case gl.FLOAT: {
      return 'uniform1f';
    }
    case gl.FLOAT_VEC2: {
      return 'uniform2f';
    }
    case gl.FLOAT_VEC3: {
      return 'uniform3f';
    }
    case gl.FLOAT_VEC4: {
      return 'uniform4f';
    }
    case gl.INT: {
      return 'uniform1i';
    }
    case gl.INT_VEC2: {
      return 'uniform2i';
    }
    case gl.INT_VEC3: {
      return 'uniform3i';
    }
    case gl.INT_VEC4: {
      return 'uniform4i';
    }
    case gl.BOOL: {
      return 'uniform1i';
    }
    case gl.BOOL_VEC2: {
      return 'uniform2i';
    }
    case gl.BOOL_VEC3: {
      return 'uniform3i';
    }
    case gl.BOOL_VEC4: {
      return 'uniform4i';
    }
    case gl.FLOAT_MAT2: {
      return 'uniform1f';
    }
    case gl.FLOAT_MAT3: {
      return 'uniform1f';
    }
    case gl.FLOAT_MAT4: {
      return 'uniform1f';
    }
    case gl.SAMPLER_2D: {
      return 'uniform1f';
    }
    case gl.SAMPLER_CUBE: {
      return 'uniform1f';
    }
    case gl.UNSIGNED_INT: {
      return 'uniform1ui';
    }
    case gl.UNSIGNED_INT_VEC2: {
      return 'uniform2ui';
    }
    case gl.UNSIGNED_INT_VEC3: {
      return 'uniform3ui';
    }
    case gl.UNSIGNED_INT_VEC4: {
      return 'uniform4ui';
    }
    case gl.FLOAT_MAT2x3: {
      return 'uniformMatrix2x3fv';
    }
    case gl.FLOAT_MAT2x4: {
      return 'uniformMatrix2x4fv';
    }
    case gl.FLOAT_MAT3x2: {
      return 'uniformMatrix3x2fv';
    }
    case gl.FLOAT_MAT3x4: {
      return 'uniformMatrix3x4fv';
    }
    case gl.FLOAT_MAT4x2: {
      return 'uniformMatrix4x2fv';
    }
    case gl.FLOAT_MAT4x3: {
      return 'uniformMatrix4x3fv';
    }
    case gl.SAMPLER_2D_ARRAY: {
      return 'uniform1fv';
    }
    case gl.SAMPLER_2D_ARRAY_SHADOW: {
      return 'uniform1f';
    }
    case gl.SAMPLER_CUBE_SHADOW: {
      return 'uniform1f';
    }
    case gl.INT_SAMPLER_2D: {
      return 'uniform1f';
    }
    case gl.INT_SAMPLER_3D: {
      return 'uniform1f';
    }
    case gl.INT_SAMPLER_CUBE: {
      return 'uniform1f';
    }
    case gl.INT_SAMPLER_2D_ARRAY: {
      return 'uniform1f';
    }
    case gl.UNSIGNED_INT_SAMPLER_2D: {
      return 'uniform1ui';
    }
    default: {
      throw new Error('Unknown uniform type: ${glType}');
    }
  }
}

enum UniformFunction {
  Uniform1f(v:Float);
  Uniform2fv(v:Array<Float>);
  Uniform1i(v:Int);
  Uniform2iv(v:Array<Int>);
  // Add more as needed
}

function applyUniform(gl:js.html.webgl.WebGL2RenderingContext, location:js.html.webgl.WebGLUniformLocation, func:UniformFunction):Void {
  switch func {
    case Uniform1f(v):
      gl.uniform1f(location, v);
    case Uniform2fv(arr):
      gl.uniform2fv(location, arr);
    case Uniform1i(v):
      gl.uniform1i(location, v);
    case Uniform2iv(arr):
      gl.uniform2iv(location, arr);
  }
}

interface UniformDefinition {
  var name: String;
  var glType: Int;
  var location: WebGLUniformLocation;
}

interface VertexAttributeDefinition {
  /**
   * string name of the attribute in the shader program, commonly `a_nameofmyvariable`
   */
  var name: String;
  /**
   * Number of components for a given attribute
   * Must be 1, 2, 3, or 4
   *
   * For example a vec4 attribute would be `4` floats, so 4
   */
  var size: Int;
  /**
   * Supported types in webgl 1
   * * gl.BYTE
   * * gl.SHORT
   * * gl.UNSIGNED_BYTE
   * * gl.UNSIGNED_SHORT
   * * gl.FLOAT
   * https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttribPointer
   */
  var glType: Int;
  /**
   * Is the attribute normalized between (0-1)
   */
  var normalized: Bool;
  /**
   * Location index in the shader program
   */
  var location: Int;
}

interface ShaderOptions {
  /**
   * ExcaliburGraphicsContextWebGL this layout will be attached to, these cannot be reused across webgl contexts.
   */
  var graphicsContext: ExcaliburGraphicsContext;

  /**
   * Optionally provide a name for the shader (useful for debugging purposes)
   */
  var name: Null<String>;

  /**
   * Vertex shader source code in glsl #version 300 es
   */
  var vertexSource: String;

  /**
   * Fragment shader source code in glsl #version 300 es
   */
  var fragmentSource: String;

  /**
   * Set initial uniforms
   */
  var uniforms: Null<UniformDictionary>;

  /**
   * Set initial images as uniform sampler2D
   */
  var images: Null<Record<String, ImageSource>>;

  /**
   * Optionally set the starting texture slot, default 0
   */
  var startingTextureSlot: Null<Int>;

  /**
   * Callback to fire directly before linking the program
   */
  var onPreLink: Null<(program: WebGLProgram) -> Void>;
  /**
   * Callback to fire directly after the progam has finished compiling
   */
  var onPostCompile: Null<(shader: Shader) -> Void>;
}

class Shader {
  public var name: String = 'anonymous shader';
  public var vertexSource: String;
  public var fragmentSource: String;

  private static var _ACTIVE_SHADER_INSTANCE: Null<Shader> = null;

  private var _logger = Logger.getInstance();

  private var _gl: WebGL2RenderingContext;
  private var _textureLoader: TextureLoader;
  private var _textures = new Map<ImageSource, WebGLTexture>();

  public var program: WebGLProgram;
  
  public var attributes: Map<String, VertexAttributeDefinition> = new Map();

  private var _uniforms: Map<String, UniformDefinition> = new Map();
  private var _uniformBuffers: Map<String, UniformBuffer> = new Map();
  private var _compiled = false;
  private var _onPreLink: Null<(program: WebGLProgram) -> Void>;
  private var _onPostCompile: Null<(shader: Shader) -> Void>;

  private var _dirtyUniforms: Bool = true;
  private var _maxTextureSlots: Int;
  private var _startingTextureSlot = 0;

  /**
   * Flags uniforms need to be re-uploaded on the next call to .use()
   */
  public function flagUniformsDirty(): Void {
    this._dirtyUniforms = true;
  }

  /**
   * Set uniforms key value pairs
   */
  var uniforms: UniformDictionary = watch({}, () -> this.flagUniformsDirty());

  /**
   * Set images to load into the shader as a sampler2d
   */
  var images: Record<String, ImageSource> = {};

  /**
   * Returns whether the shader is compiled
   */
  public var compiled(get, never): Bool;
  function get_compiled() {
    return this._compiled;
  }

  /**
   * Create a shader program in excalibur
   * @param options specify shader vertex and fragment source
   */
  public function new(options: ShaderOptions) {
    final name = options.name,
          graphicsContext = options.graphicsContext,
          vertexSource = options.vertexSource,
          fragmentSource = options.fragmentSource,
          onPreLink = options.onPreLink,
          onPostCompile = options.onPostCompile,
          uniforms = options.uniforms,
          images = options.images,
          startingTextureSlot = options.startingTextureSlot;

    this.name = name ?? this.name;
    if (!(Std.isTypeOf(graphicsContext, ExcaliburGraphicsContextWebGL))) {
      throw new Error('ExcaliburGraphicsContext provided to a shader ${this.name} must be WebGL');
    }
    this._gl = graphicsContext.__gl;
    this._startingTextureSlot = startingTextureSlot ?? this._startingTextureSlot;
    this._maxTextureSlots = this._gl.getParameter(this._gl.MAX_TEXTURE_IMAGE_UNITS) - this._startingTextureSlot;
    this.vertexSource = vertexSource;
    this.fragmentSource = fragmentSource;
    this.uniforms = watch(uniforms ?? this.uniforms, () -> this.flagUniformsDirty());
    this.images = images ?? this.images;
    final keys = Object.keys(this.images);
    if (keys.length >= this._maxTextureSlots) {
      this._logger.warn(
        'Max number texture slots ${this._maxTextureSlots} have been reached for material "${this.name}", ' +
          'no more textures will be uploaded due to hardware constraints.'
      );
    }
    this._textureLoader = graphicsContext.textureLoader;
    this._onPreLink = onPreLink;
    this._onPostCompile = onPostCompile;
  }

  /**
   * Deletes the webgl program from the gpu
   */
  function dispose() {
    final gl = this._gl;
    gl.deleteProgram(this.program);
    this._gl = null;
  }

  /**
   * Binds the shader program
   */
  function use() {
    final gl = this._gl;
    gl.useProgram(this.program);
    Shader._ACTIVE_SHADER_INSTANCE = this;
    if (this._dirtyUniforms) {
      this._setUniforms();
      this._dirtyUniforms = false;
    }

    this._setImages();
  }

  function unuse() {
    final gl = this._gl;
    Shader._ACTIVE_SHADER_INSTANCE = null;
    gl.useProgram(null);
  }

  function isCurrentlyBound() {
    return Shader._ACTIVE_SHADER_INSTANCE == this;
  }

  private function _setUniforms() {
    final gl = this._gl;
    final entries = Object.entries(this.uniforms);
    if (entries.length) {
      final uniforms = this.getUniformDefinitions();
      for (key => value in entries) {
        if (Std.isTypeOf(value, Float32Array)) {
          this.setUniformBuffer(key, value);
        } else if (Array.isArray(value) && Std.isTypeOf(value[0], Float32Array) && Std.isTypeOf(value[1], Int)) {
          this.setUniformBuffer(key, value[0], value[1]);
        } else if (Std.isTypeOf(value, Float)) {
          this.trySetUniformFloat(key, value);
        } else if (Std.isTypeOf(value, Bool)) {
          this.trySetUniformBoolean(key, value);
        } else if (Std.isTypeOf(value, Vector)) {
          this.trySetUniformFloatVector(key, value);
        } else if (Std.isTypeOf(value, Color)) {
          this.trySetUniformFloatColor(key, value);
        } else if (Std.isTypeOf(value, AffineMatrix)) {
          this.setUniformAffineMatrix(key, value);
        } else {
          final uniform = uniforms.find((u) -> u.name == key);
          if (uniform) {
            final typeName = glTypeToUniformTypeName(gl, uniform.glType);
            this.trySetUniform(typeName, key, value);
          } else {
            this._logger.warnOnce(
              'Could not locate uniform named ${key},' +
                ' this can happen if the uniform is unused in the shader code some GPUs will remove this as an optimization.'
            );
          }
        }
      }
    }
  }

  private function _loadImageSource(image: ImageSource): Null<WebGLTexture> {
    final imageElement = image.image;
    final maybeFiltering = imageElement.getAttribute(ImageSourceAttributeConstants.Filtering);
    final filtering = maybeFiltering ? parseImageFiltering(maybeFiltering) : null;
    final wrapX = parseImageWrapping(imageElement.getAttribute(ImageSourceAttributeConstants.WrappingX));
    final wrapY = parseImageWrapping(imageElement.getAttribute(ImageSourceAttributeConstants.WrappingY));

    final force = imageElement.getAttribute('forceUpload') == 'true' ? true : false;
    final texture = this._textureLoader.load(
      imageElement,
      {
        filtering: filtering,
        wrapping: { x: wrapX, y: wrapY }
      },
      force
    );
    // remove force attribute after upload
    imageElement.removeAttribute('forceUpload');
    if (!this._textures.has(image)) {
      this._textures.set(image, texture!);
    }

    return texture;
  }

  function _setImages(suppressWarning = false) {
    final gl = this._gl;
    // first 2 textures slots are usually taken by 1 default graphic 2 screen texture
    var textureSlot = this._startingTextureSlot;
    for (textureName => image in this.images) {
      if (!image.isLoaded()) {
        if (!suppressWarning) {
          this._logger.warnOnce(
            'Image named ${textureName} in not loaded, nothing will be uploaded to the shader.' +
              ' Did you forget to add this to a loader? https://excaliburjs.com/docs/loaders/'
          );
        }
        continue;
      } // skip unloaded images, maybe warn
      final texture = this._loadImageSource(image);
      if (!texture) {
        if (!suppressWarning) {
          this._logger.warnOnce('Image ${textureName} (${image.image.src}) could not be loaded for some reason in shader ${this.name}');
        }
      }
      gl.activeTexture(gl.TEXTURE0 + textureSlot);
      gl.bindTexture(gl.TEXTURE_2D, texture);
      this.trySetUniformInt(textureName, textureSlot);

      textureSlot++;
    }
  }

  /**
   * Compile the current shader against a webgl context
   */
  function compile(): WebGLProgram {
    if (this._compiled) {
      return this.program;
    }
    final gl = this._gl;
    final vertexShader = this._compileShader(gl, this.vertexSource, gl.VERTEX_SHADER);
    final fragmentShader = this._compileShader(gl, this.fragmentSource, gl.FRAGMENT_SHADER);
    this.program = this._createProgram(gl, vertexShader, fragmentShader);

    final attributes = this.getAttributeDefinitions();
    for (attribute in attributes) {
      this.attributes[attribute.name] = attribute;
    }
    final uniforms = this.getUniformDefinitions();
    for (uniform in uniforms) {
      this._uniforms[uniform.name] = uniform;
    }

    this._compiled = true;
    if (this._onPostCompile) {
      this._onPostCompile(this);
    }

    gl.useProgram(this.program);
    Shader._ACTIVE_SHADER_INSTANCE = this;
    if (this._dirtyUniforms) {
      this._setUniforms();
      this._dirtyUniforms = false;
    }

    this._setImages(true);
    this.unuse();

    return this.program;
  }

  /**
   * Get's the uniform definitons
   */
  function getUniformDefinitions(): Array<UniformDefinition> {
    final gl = this._gl;
    final uniformCount = gl.getProgramParameter(this.program, gl.ACTIVE_UNIFORMS);
    final uniforms: Array<UniformDefinition> = [];
    for (i in 0...uniformCount) {
      final uniform = gl.getActiveUniform(this.program, i)!;
      final uniformLocation = gl.getUniformLocation(this.program, uniform.name)!;
      uniforms.push({
        name: uniform.name,
        glType: uniform.type,
        location: uniformLocation
      });
    }
    return uniforms;
  }

  function getAttributeDefinitions(): Array<VertexAttributeDefinition> {
    final gl = this._gl;
    final attributeCount = gl.getProgramParameter(this.program, gl.ACTIVE_ATTRIBUTES);
    final attributes: Array<VertexAttributeDefinition> = [];
    for (i in 0...attributeCount) {
      final attribute = gl.getActiveAttrib(this.program, i)!;
      final attributeLocation = gl.getAttribLocation(this.program, attribute.name);
      attributes.push({
        name: attribute.name,
        glType: getAttributePointerType(gl, attribute.type),
        size: getAttributeComponentSize(gl, attribute.type),
        location: attributeLocation,
        normalized: false
      });
    }
    return attributes;
  }

  function addImageSource(samplerName: String, image: ImageSource) {
    final keys = Object.keys(this.images);
    if (keys.length < this._maxTextureSlots) {
      this.images[samplerName] = image;
    } else {
      this._logger.warn(
        'Max number texture slots ${this._maxTextureSlots} have been reached for material "${this.name}", ' +
          'no more textures will be uploaded due to hardware constraints.'
      );
    }
  }

  function removeImageSource(samplerName: String) {
    final image = this.images[samplerName];
    if (image) {
      this._textureLoader.delete(image.image);
      this.images.delete(samplerName);
    }
  }

  /**
   * Set a texture in a gpu texture slot
   * @param slotNumber
   * @param texture
   */
  function setTexture(slotNumber: Int, texture: WebGLTexture): Void {
    final gl = this._gl;
    gl.activeTexture(gl.TEXTURE0 + slotNumber);
    gl.bindTexture(gl.TEXTURE_2D, texture);
  }

  /**
   * Set a uniform buffer block with a Float32Array
   * @param name The of the binding block
   * @param data Float32Array
   * @param [bindingPoint]
   */
  function setUniformBuffer(name: String, data: Float32Array, bindingPoint: Int = 0): Void {
    final gl = this._gl;
    final index = gl.getUniformBlockIndex(this.program, name);
    if (index == gl.INVALID_INDEX) {
      this._logger.warnOnce('Invalid block name ${name}');
    }
    var uniformBuffer: UniformBuffer;
    if (this._uniformBuffers[name]) {
      uniformBuffer = this._uniformBuffers[name];
      uniformBuffer.bufferData.set(data);
      uniformBuffer.upload();
    } else {
      uniformBuffer = new UniformBuffer({
        gl: gl,
        data: data
      });
      this._uniformBuffers[name] = uniformBuffer;
    }
    gl.uniformBlockBinding(this.program, index, bindingPoint);
    gl.bindBufferBase(gl.UNIFORM_BUFFER, bindingPoint, uniformBuffer.buffer);
  }

  function trySetUniformBuffer(name: String, data: Float32Array, bindingPoint: Int = 0): Bool {
    if (!this._compiled) {
      this._logger.warn('Must compile shader before setting a uniform block ${name} at binding point ${bindingPoint}');
      return false;
    }
    if (!this.isCurrentlyBound()) {
      this._logger.warn(
        'Currently accessed shader instance is not the current active shader in WebGL,' +
          ' must call `shader.use()` before setting uniforms'
      );
      return false;
    }
    final gl = this._gl;
    final index = gl.getUniformBlockIndex(this.program, name);
    if (index) {
      this.setUniformBuffer(name, data, bindingPoint);
      return true;
    }
    return false;
  }

  /**
   * Set an integer uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function setUniformInt(name: String, value: Int): Void {
    this.setUniform('uniform1i', name, ~~value);
  }

  /**
   * Set an integer uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function trySetUniformInt(name: String, value: Int): Bool {
    return this.trySetUniform('uniform1i', name, ~~value);
  }

  /**
   * Set an integer array uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function setUniformIntArray(name: String, value: Array<Int>): Void {
    this.setUniform('uniform1iv', name, value);
  }

  /**
   * Set an integer array uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function trySetUniformIntArray(name: String, value: Array<Int>): Boolean {
    return this.trySetUniform('uniform1iv', name, value);
  }

  /**
   * Set a boolean uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function setUniformBoolean(name: String, value: Bool): Void {
    this.setUniform('uniform1i', name, value ? 1 : 0);
  }

  /**
   * Set a boolean uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function trySetUniformBoolean(name: String, value: Bool): Bool {
    return this.trySetUniform('uniform1i', name, value ? 1 : 0);
  }

  /**
   * Set a float uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function setUniformFloat(name: String, value: Float): Void {
    this.setUniform('uniform1f', name, value);
  }

  /**
   * Set a float uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function trySetUniformFloat(name: String, value: Float): Boolean {
    return this.trySetUniform('uniform1f', name, value);
  }

  /**
   * Set a float array uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function setUniformFloatArray(name: String, value: Array<Float>): Void {
    this.setUniform('uniform1fv', name, value);
  }
  /**
   * Set a float array uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function trySetUniformFloatArray(name: String, value: Array<Float>): Bool {
    return this.trySetUniform('uniform1fv', name, value);
  }

  /**
   * Set a {@apilink Vector} uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function setUniformFloatVector(name: String, value: Vector): Void {
    this.setUniform('uniform2f', name, value.x, value.y);
  }

  /**
   * Set a {@apilink Vector} uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function trySetUniformFloatVector(name: String, value: Vector): Bool {
    return this.trySetUniform('uniform2f', name, value.x, value.y);
  }

  /**
   * Set a {@apilink Color} uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function setUniformFloatColor(name: String, value: Color): Void {
    this.setUniform('uniform4f', name, value.r / 255, value.g / 255, value.b / 255, value.a);
  }

  /**
   * Set a {@apilink Color} uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function trySetUniformFloatColor(name: String, value: Color): Bool {
    return this.trySetUniform('uniform4f', name, value.r / 255, value.g / 255, value.b / 255, value.a);
  }

  /**
   * Set an {@apilink Matrix} uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function setUniformMatrix(name: String, value: Matrix): Void {
    this.setUniform('uniformMatrix4fv', name, false, value.data);
  }

  function setUniformAffineMatrix(name: String, value: AffineMatrix): Void {
    // prettier-ignore
    this.setUniform('uniformMatrix4fv', name, false, [
      value.data[0], value.data[1], 0, 0,
      value.data[2], value.data[3], 0, 0,
      0, 0, 1, 0,
      value.data[4], value.data[5], 0, 1
    ]);
  }

  /**
   * Set an {@apilink Matrix} uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  function trySetUniformMatrix(name: String, value: Matrix): Bool {
    return this.trySetUniform('uniformMatrix4fv', name, false, value.data);
  }

  /**
   * Set any available uniform type in webgl
   *
   * For example setUniform('uniformMatrix2fv', 'u_my2x2_mat`, ...);
   */
  function setUniform(
    uniformType: TUnifoStringrmType,
    name: String,
    ...value: UniformParameters<TUniformType>
  ): Void {
    if (!this._compiled) {
      throw Error('Must compile shader before setting a uniform ${uniformType}:${name}');
    }
    if (!this.isCurrentlyBound()) {
      throw Error(
        'Currently accessed shader instance is not the current active shader in WebGL,' +
          ' must call `shader.use()` before setting uniforms'
      );
    }
    final gl = this._gl;
    final location = gl.getUniformLocation(this.program, name);
    if (location) {
      final args = [location, ...value];
      this._gl[uniformType].apply(this._gl, args);
    } else {
      throw Error(
        'Uniform ${uniformType}:${name} doesn\'t exist or is not used in the shader source code,' +
          ' unused uniforms are optimized away by most browsers'
      );
    }
  }

  /**
   * Set any available uniform type in webgl. Will try to set the uniform, will return false if the uniform didn't exist,
   * true if it was set.
   *
   * WILL NOT THROW on error
   *
   * For example setUniform('uniformMatrix2fv', 'u_my2x2_mat`, ...);
   *
   */
  function trySetUniform(
    uniformType: String,
    name: String,
    ...value: UniformParameters<String>
  ): Bool {
    if (!this._compiled) {
      this._logger.warn('Must compile shader before setting a uniform ${uniformType}:${name}');
      return false;
    }
    if (!this.isCurrentlyBound()) {
      this._logger.warn(
        'Currently accessed shader instance is not the current active shader in WebGL,' +
          ' must call `shader.use()` before setting uniforms'
      );
      return false;
    }
    final gl = this._gl;
    final location = gl.getUniformLocation(this.program, name);
    if (location) {
      final args = [location, ...value];
      this._gl[uniformType].apply(this._gl, args);
    } else {
      return false;
    }
    return true;
  }

  private function _createProgram(gl: WebGLRenderingContext, vertexShader: WebGLShader, fragmentShader: WebGLShader): WebGLProgram {
    final program = gl.createProgram();
    if (program == null) {
      throw Error('Could not create graphics shader program');
    }

    // attach the shaders.
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);

    if (this._onPreLink) {
      this._onPreLink(program);
    }

    // link the program.
    gl.linkProgram(program);

    final success = gl.getProgramParameter(program, gl.LINK_STATUS);
    if (!success) {
      throw Error('Could not link the program: [${gl.getProgramInfoLog(program)}]');
    }

    return program;
  }

  private function _compileShader(gl: WebGLRenderingContext, source: String, type: Int): WebGLShader {
    final typeName = gl.VERTEX_SHADER == type ? 'vertex' : 'fragment';
    final shader = gl.createShader(type);
    if (shader == null) {
      throw Error('Could not build shader: [${source}]');
    }

    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    final success = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    if (!success) {
      final errorInfo = gl.getShaderInfoLog(shader);
      throw Error('Could not compile ${typeName} shader:\n\n${errorInfo}${this._processSourceForError(source, errorInfo!)}');
    }
    return shader;
  }

  private function _processSourceForError(source: String, errorInfo: String) {
    if (!source) {
      return errorInfo;
    }
    final lines = source.split('\n');
    final errorLineStart = errorInfo.search(~/\d:\d/);
    final errorLineEnd = errorInfo.indexOf(' ', errorLineStart);
    final error2 = errorInfo[1]
      .slice(errorLineStart, errorLineEnd)
      .split(':')
      .map((v) -> Number(v));
    
    for (i in 0...lines.length) {
      lines[i] = '${i + 1}: ${lines[i]}${error2 == i + 1 ? ' <----- ERROR!' : ''}';
    }

    return '\n\nSource:\n' + lines.join('\n');
  }
}
