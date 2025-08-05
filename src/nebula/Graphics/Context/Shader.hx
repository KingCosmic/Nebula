package nebula.Graphics.Context;

import nebula.Math.Matrix;
import nebula.Util.Watch;
import nebula.Graphics.Context.UniformBuffer;
import nebula.Graphics.Context.WebglUtil;

type UniformDictionary = Record<
  String,
  Int | Bool | Vector | Color | AffineMatrix | Float32Array | [uniformData: Float32Array, bindingPoint: Int]
>;
/*
 * List of the possible glsl uniform types
 */
type UniformTypeNames =
  | 'uniform1f'
  | 'uniform1i'
  | 'uniform1ui'
  | 'uniform2f'
  | 'uniform2i'
  | 'uniform2ui'
  | 'uniform3f'
  | 'uniform3i'
  | 'uniform3ui'
  | 'uniform4f'
  | 'uniform4i'
  | 'uniform4ui'
  | 'uniform1fv'
  | 'uniform1iv'
  | 'uniform1uiv'
  | 'uniform2fv'
  | 'uniform2iv'
  | 'uniform2uiv'
  | 'uniform3fv'
  | 'uniform3iv'
  | 'uniform3uiv'
  | 'uniform4fv'
  | 'uniform4iv'
  | 'uniform4uiv'
  | 'uniformMatrix2fv'
  | 'uniformMatrix2x3fv'
  | 'uniformMatrix2x4fv'
  | 'uniformMatrix3fv'
  | 'uniformMatrix3x2fv'
  | 'uniformMatrix3x4fv'
  | 'uniformMatrix4fv'
  | 'uniformMatrix4x2fv'
  | 'uniformMatrix4x3fv';

/**
 *
 */
function glTypeToUniformTypeName(gl: WebGL2RenderingContext, glType: Int): UniformTypeNames {
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
      throw new Error(`Unknown uniform type: ${glType}`);
    }
  }
}

type RemoveFirstFromTuple<T extends any[]> = T['length'] extends 0
  ? []
  : ((...b: T) => Void) extends (a: any, ...b: infer I) => Void
    ? I
    : [];

type UniformParameters<TUniformType extends UniformTypeNames> = RemoveFirstFromTuple<Parameters<WebGL2RenderingContext[TUniformType]>>;

interface UniformDefinition {
  name: String;
  glType: Int;
  location: WebGLUniformLocation;
}

interface VertexAttributeDefinition {
  /**
   * string name of the attribute in the shader program, commonly `a_nameofmyvariable`
   */
  name: String;
  /**
   * Number of components for a given attribute
   * Must be 1, 2, 3, or 4
   *
   * For example a vec4 attribute would be `4` floats, so 4
   */
  size: Int;
  /**
   * Supported types in webgl 1
   * * gl.BYTE
   * * gl.SHORT
   * * gl.UNSIGNED_BYTE
   * * gl.UNSIGNED_SHORT
   * * gl.FLOAT
   * https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttribPointer
   */
  glType: Int;
  /**
   * Is the attribute normalized between (0-1)
   */
  normalized: Bool;
  /**
   * Location index in the shader program
   */
  location: Int;
}

interface ShaderOptions {
  /**
   * ExcaliburGraphicsContextWebGL this layout will be attached to, these cannot be reused across webgl contexts.
   */
  graphicsContext: ExcaliburGraphicsContext;

  /**
   * Optionally provide a name for the shader (useful for debugging purposes)
   */
  name?: String;

  /**
   * Vertex shader source code in glsl #version 300 es
   */
  vertexSource: String;

  /**
   * Fragment shader source code in glsl #version 300 es
   */
  fragmentSource: String;

  /**
   * Set initial uniforms
   */
  uniforms?: UniformDictionary;

  /**
   * Set initial images as uniform sampler2D
   */
  images?: Record<string, ImageSource>;

  /**
   * Optionally set the starting texture slot, default 0
   */
  startingTextureSlot?: Int;

  /**
   * Callback to fire directly before linking the program
   */
  onPreLink?: (program: WebGLProgram) => Void;
  /**
   * Callback to fire directly after the progam has finished compiling
   */
  onPostCompile?: (shader: Shader) => Void;
}

class Shader {
  public readonly name: String = 'anonymous shader';
  public readonly vertexSource: String;
  public readonly fragmentSource: String;

  private static _ACTIVE_SHADER_INSTANCE: Shader | null = null;

  private _logger = Logger.getInstance();

  private _gl: WebGL2RenderingContext;
  private _textureLoader: TextureLoader;
  private _textures = new Map<ImageSource, WebGLTexture>();

  public program!: WebGLProgram;
  public attributes: { [variableName: String]: VertexAttributeDefinition } = {};

  private _uniforms: { [variableName: String]: UniformDefinition } = {};
  private _uniformBuffers: { [blockName: String]: UniformBuffer } = {};
  private _compiled = false;
  private _onPreLink?: (program: WebGLProgram) => Void;
  private _onPostCompile?: (shader: Shader) => Void;

  private _dirtyUniforms: Bool = true;
  private _maxTextureSlots: Int;
  private _startingTextureSlot = 0;

  /**
   * Flags uniforms need to be re-uploaded on the next call to .use()
   */
  public flagUniformsDirty(): Void {
    this._dirtyUniforms = true;
  }

  /**
   * Set uniforms key value pairs
   */
  uniforms: UniformDictionary = watch({}, () => this.flagUniformsDirty());

  /**
   * Set images to load into the shader as a sampler2d
   */
  images: Record<String, ImageSource> = {};

  /**
   * Returns whether the shader is compiled
   */
  public get compiled() {
    return this._compiled;
  }

  /**
   * Create a shader program in excalibur
   * @param options specify shader vertex and fragment source
   */
  public function new(options: ShaderOptions) {
    final { name, graphicsContext, vertexSource, fragmentSource, onPreLink, onPostCompile, uniforms, images, startingTextureSlot } =
      options;
    this.name = name ?? this.name;
    if (!(graphicsContext instanceof ExcaliburGraphicsContextWebGL)) {
      throw new Error('ExcaliburGraphicsContext provided to a shader ${this.name} must be WebGL');
    }
    this._gl = graphicsContext.__gl;
    this._startingTextureSlot = startingTextureSlot ?? this._startingTextureSlot;
    this._maxTextureSlots = this._gl.getParameter(this._gl.MAX_TEXTURE_IMAGE_UNITS) - this._startingTextureSlot;
    this.vertexSource = vertexSource;
    this.fragmentSource = fragmentSource;
    this.uniforms = watch(uniforms ?? this.uniforms, () => this.flagUniformsDirty());
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
  dispose() {
    final gl = this._gl;
    gl.deleteProgram(this.program);
    this._gl = null as any;
  }

  /**
   * Binds the shader program
   */
  use() {
    final gl = this._gl;
    gl.useProgram(this.program);
    Shader._ACTIVE_SHADER_INSTANCE = this;
    if (this._dirtyUniforms) {
      this._setUniforms();
      this._dirtyUniforms = false;
    }

    this._setImages();
  }

  unuse() {
    final gl = this._gl;
    Shader._ACTIVE_SHADER_INSTANCE = null;
    gl.useProgram(null);
  }

  isCurrentlyBound() {
    return Shader._ACTIVE_SHADER_INSTANCE === this;
  }

  private _setUniforms() {
    final gl = this._gl;
    final entries = Object.entries(this.uniforms);
    if (entries.length) {
      final uniforms = this.getUniformDefinitions();
      for (final [key, value] of entries) {
        if (value instanceof Float32Array) {
          this.setUniformBuffer(key, value);
        } else if (Array.isArray(value) && value[0] instanceof Float32Array && typeof value[1] === 'number') {
          this.setUniformBuffer(key, value[0], value[1]);
        } else if (typeof value === 'number') {
          this.trySetUniformFloat(key, value);
        } else if (typeof value === 'boolean') {
          this.trySetUniformBoolean(key, value);
        } else if (value instanceof Vector) {
          this.trySetUniformFloatVector(key, value);
        } else if (value instanceof Color) {
          this.trySetUniformFloatColor(key, value);
        } else if (value instanceof AffineMatrix) {
          this.setUniformAffineMatrix(key, value);
        } else {
          final uniform = uniforms.find((u) => u.name === key);
          if (uniform) {
            final typeName = glTypeToUniformTypeName(gl, uniform.glType) as UniformTypeNames;
            this.trySetUniform(typeName as any, key, value);
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

  private _loadImageSource(image: ImageSource): Null<WebGLTexture> {
    final imageElement = image.image;
    final maybeFiltering = imageElement.getAttribute(ImageSourceAttributeConstants.Filtering);
    final filtering = maybeFiltering ? parseImageFiltering(maybeFiltering) : undefined;
    final wrapX = parseImageWrapping(imageElement.getAttribute(ImageSourceAttributeConstants.WrappingX) as any);
    final wrapY = parseImageWrapping(imageElement.getAttribute(ImageSourceAttributeConstants.WrappingY) as any);

    final force = imageElement.getAttribute('forceUpload') === 'true' ? true : false;
    final texture = this._textureLoader.load(
      imageElement,
      {
        filtering,
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

  _setImages(suppressWarning = false) {
    final gl = this._gl;
    // first 2 textures slots are usually taken by 1 default graphic 2 screen texture
    var textureSlot = this._startingTextureSlot;
    for (final [textureName, image] of Object.entries(this.images)) {
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
  compile(): WebGLProgram {
    if (this._compiled) {
      return this.program;
    }
    final gl = this._gl;
    final vertexShader = this._compileShader(gl, this.vertexSource, gl.VERTEX_SHADER);
    final fragmentShader = this._compileShader(gl, this.fragmentSource, gl.FRAGMENT_SHADER);
    this.program = this._createProgram(gl, vertexShader, fragmentShader);

    final attributes = this.getAttributeDefinitions();
    for (final attribute of attributes) {
      this.attributes[attribute.name] = attribute;
    }
    final uniforms = this.getUniformDefinitions();
    for (final uniform of uniforms) {
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
  getUniformDefinitions(): UniformDefinition[] {
    final gl = this._gl;
    final uniformCount = gl.getProgramParameter(this.program, gl.ACTIVE_UNIFORMS);
    final uniforms: UniformDefinition[] = [];
    for (var i = 0; i < uniformCount; i++) {
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

  getAttributeDefinitions(): VertexAttributeDefinition[] {
    final gl = this._gl;
    final attributeCount = gl.getProgramParameter(this.program, gl.ACTIVE_ATTRIBUTES);
    final attributes: VertexAttributeDefinition[] = [];
    for (var i = 0; i < attributeCount; i++) {
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

  addImageSource(samplerName: String, image: ImageSource) {
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

  removeImageSource(samplerName: String) {
    final image = this.images[samplerName];
    if (image) {
      this._textureLoader.delete(image.image);
      delete this.images[samplerName];
    }
  }

  /**
   * Set a texture in a gpu texture slot
   * @param slotNumber
   * @param texture
   */
  setTexture(slotNumber: Int, texture: WebGLTexture): Void {
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
  setUniformBuffer(name: String, data: Float32Array, bindingPoint: Int = 0): Void {
    final gl = this._gl;
    final index = gl.getUniformBlockIndex(this.program, name);
    if (index === gl.INVALID_INDEX) {
      this._logger.warnOnce('Invalid block name ${name}');
    }
    var uniformBuffer: UniformBuffer;
    if (this._uniformBuffers[name]) {
      uniformBuffer = this._uniformBuffers[name];
      uniformBuffer.bufferData.set(data);
      uniformBuffer.upload();
    } else {
      uniformBuffer = new UniformBuffer({
        gl,
        data
      });
      this._uniformBuffers[name] = uniformBuffer;
    }
    gl.uniformBlockBinding(this.program, index, bindingPoint);
    gl.bindBufferBase(gl.UNIFORM_BUFFER, bindingPoint, uniformBuffer.buffer);
  }

  trySetUniformBuffer(name: String, data: Float32Array, bindingPoint: Int = 0): Bool {
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
  setUniformInt(name: String, value: Int): Void {
    this.setUniform('uniform1i', name, ~~value);
  }

  /**
   * Set an integer uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  trySetUniformInt(name: String, value: Int): Bool {
    return this.trySetUniform('uniform1i', name, ~~value);
  }

  /**
   * Set an integer array uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  setUniformIntArray(name: String, value: Int[]): Void {
    this.setUniform('uniform1iv', name, value);
  }

  /**
   * Set an integer array uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  trySetUniformIntArray(name: String, value: Int[]): Boolean {
    return this.trySetUniform('uniform1iv', name, value);
  }

  /**
   * Set a boolean uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  setUniformBoolean(name: String, value: Bool): Void {
    this.setUniform('uniform1i', name, value ? 1 : 0);
  }

  /**
   * Set a boolean uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  trySetUniformBoolean(name: String, value: Bool): Bool {
    return this.trySetUniform('uniform1i', name, value ? 1 : 0);
  }

  /**
   * Set a float uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  setUniformFloat(name: String, value: Float): Void {
    this.setUniform('uniform1f', name, value);
  }

  /**
   * Set a float uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  trySetUniformFloat(name: String, value: Float): Boolean {
    return this.trySetUniform('uniform1f', name, value);
  }

  /**
   * Set a float array uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  setUniformFloatArray(name: String, value: Float[]): Void {
    this.setUniform('uniform1fv', name, value);
  }
  /**
   * Set a float array uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  trySetUniformFloatArray(name: String, value: Float[]): Bool {
    return this.trySetUniform('uniform1fv', name, value);
  }

  /**
   * Set a {@apilink Vector} uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  setUniformFloatVector(name: String, value: Vector): Void {
    this.setUniform('uniform2f', name, value.x, value.y);
  }

  /**
   * Set a {@apilink Vector} uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  trySetUniformFloatVector(name: String, value: Vector): Bool {
    return this.trySetUniform('uniform2f', name, value.x, value.y);
  }

  /**
   * Set a {@apilink Color} uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  setUniformFloatColor(name: String, value: Color): Void {
    this.setUniform('uniform4f', name, value.r / 255, value.g / 255, value.b / 255, value.a);
  }

  /**
   * Set a {@apilink Color} uniform for the current shader, WILL NOT THROW on error.
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  trySetUniformFloatColor(name: String, value: Color): Bool {
    return this.trySetUniform('uniform4f', name, value.r / 255, value.g / 255, value.b / 255, value.a);
  }

  /**
   * Set an {@apilink Matrix} uniform for the current shader
   *
   * **Important** Must call ex.Shader.use() before setting a uniform!
   * @param name
   * @param value
   */
  setUniformMatrix(name: String, value: Matrix): Void {
    this.setUniform('uniformMatrix4fv', name, false, value.data);
  }

  setUniformAffineMatrix(name: String, value: AffineMatrix): Void {
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
  trySetUniformMatrix(name: String, value: Matrix): Bool {
    return this.trySetUniform('uniformMatrix4fv', name, false, value.data);
  }

  /**
   * Set any available uniform type in webgl
   *
   * For example setUniform('uniformMatrix2fv', 'u_my2x2_mat`, ...);
   */
  function setUniform<TUniformType extends UniformTypeNames>(
    uniformType: TUniformType,
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
      (this._gl as any)[uniformType].apply(this._gl, args);
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
  function trySetUniform<TUniformType extends UniformTypeNames>(
    uniformType: TUniformType,
    name: String,
    ...value: UniformParameters<TUniformType>
  ): boolean {
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
      (this._gl as any)[uniformType].apply(this._gl, args);
    } else {
      return false;
    }
    return true;
  }

  private _createProgram(gl: WebGLRenderingContext, vertexShader: WebGLShader, fragmentShader: WebGLShader): WebGLProgram {
    final program = gl.createProgram();
    if (program === null) {
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
      throw Error(`Could not link the program: [${gl.getProgramInfoLog(program)}]`);
    }

    return program;
  }

  private _compileShader(gl: WebGLRenderingContext, source: String, type: Int): WebGLShader {
    final typeName = gl.VERTEX_SHADER === type ? 'vertex' : 'fragment';
    final shader = gl.createShader(type);
    if (shader === null) {
      throw Error(`Could not build shader: [${source}]`);
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

  private _processSourceForError(source: String, errorInfo: String) {
    if (!source) {
      return errorInfo;
    }
    final lines = source.split('\n');
    final errorLineStart = errorInfo.search(/\d:\d/);
    final errorLineEnd = errorInfo.indexOf(' ', errorLineStart);
    final [_, error2] = errorInfo
      .slice(errorLineStart, errorLineEnd)
      .split(':')
      .map((v) => Number(v));
    for (var i = 0; i < lines.length; i++) {
      lines[i] = `${i + 1}: ${lines[i]}${error2 === i + 1 ? ' <----- ERROR!' : ''}`;
    }

    return '\n\nSource:\n' + lines.join('\n');
  }
}
