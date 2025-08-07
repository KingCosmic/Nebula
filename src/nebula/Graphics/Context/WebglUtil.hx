package nebula.graphics.context;

class WebglUtil {
  /**
   * Return the size of the GlType in bytes
   * @param gl
   * @param type
   */
  public static function getGlTypeSizeBytes(gl: WebGLRenderingContext, type: Int): Int {
    switch (type) {
      case gl.INT:
      case gl.UNSIGNED_INT:
      case gl.FLOAT:
        return 4;
      case gl.SHORT:
        return 2;
      case gl.UNSIGNED_SHORT:
        return 2;
      case gl.BYTE:
        return 1;
      case gl.UNSIGNED_BYTE:
        return 1;
      default:
        return 1;
    }
  }

  /**
   * Checks if an attribute is present in vertex source
   */
  public static function isAttributeInSource(source: String, variable: String) {
    final attributeRegexTemplate = '(?<type>[a-z0-9]+)\\s+${variable};';
    final regex = new RegExp(attributeRegexTemplate, 'g');
    final matches = regex.exec(source);
    return matches?.length! > 0;
  }

  /**
   * Attempt to discern the glType of an attribute from vertex source
   * @param gl
   * @param source
   * @param variable
   */
  public static function getGLTypeFromSource(gl: WebGLRenderingContext, source: String, variable: String) {
    final attributeRegexTemplate = '(?<type>[a-z0-9]+)\\s+${variable};';
    final regex = new RegExp(attributeRegexTemplate, 'g');
    final matches = regex.exec(source);
    final type = matches?.groups?.type;

    switch (type) {
      case 'float':
      case 'vec2':
      case 'vec3':
      case 'vec4':
        return gl.FLOAT;
      case 'int':
      case 'ivec2':
      case 'ivec3':
      case 'ivec4':
        return gl.INT;
      case 'uint':
      case 'uvec2':
      case 'uvec3':
      case 'uvec4':
        return gl.UNSIGNED_INT;
      case 'bool':
      case 'bvec2':
      case 'bvec3':
      case 'bvec4':
        return gl.BOOL;
      case 'short':
        return gl.SHORT;
      case 'ushort':
        return gl.UNSIGNED_SHORT;
      case 'ubyte':
        return gl.UNSIGNED_BYTE;
      case 'byte':
        return gl.BYTE;
      default:
        return gl.FLOAT;
    }
  }

  /**
   * Based on the type return the number of attribute components
   *
   * https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttribPointer
   * @param gl
   * @param type
   */
  public static function getAttributeComponentSize(gl: WebGLRenderingContext, type: Int): Int {
    switch (type) {
      case gl.LOW_FLOAT:
      case gl.HIGH_FLOAT:
      case gl.FLOAT:
        return 1;
      case gl.FLOAT_VEC2:
        return 2;
      case gl.FLOAT_VEC3:
        return 3;
      case gl.FLOAT_VEC4:
        return 4;
      case gl.BYTE:
        return 1;
      case gl.UNSIGNED_BYTE:
        return 1;
      case gl.UNSIGNED_SHORT:
      case gl.SHORT:
        return 1;
      default:
        return 1;
    }
  }

  /**
   * Based on the attribute return the corresponding supported attrib pointer type
   * https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttribPointer
   * @param gl
   * @param type
   */
  public static function getAttributePointerType(gl: WebGLRenderingContext, type: Int) {
    switch (type) {
      case gl.LOW_FLOAT:
      case gl.HIGH_FLOAT:
      case gl.FLOAT:
      case gl.FLOAT_VEC2:
      case gl.FLOAT_VEC3:
      case gl.FLOAT_VEC4:
        return gl.FLOAT;
      case gl.BYTE:
        return gl.BYTE;
      case gl.UNSIGNED_BYTE:
        return gl.UNSIGNED_BYTE;
      case gl.SHORT:
        return gl.SHORT;
      case gl.UNSIGNED_SHORT:
        return gl.UNSIGNED_SHORT;
      default:
        return gl.FLOAT;
    }
  }

  /**
   *
   */
  public static function getMaxShaderComplexity(gl: WebGL2RenderingContext, numIfs: Int): Int {
    final assembleTestShader = (numIfs: Int) => {
      final testShader = '#version 300 es
      precision mediump float;
      out vec4 fragColor;
      void main() {
        float index = 1.01;
        %%complexity%%
      }';
      var testComplexity = '';
      for (i in 0...numIfs) {
        if (i == 0) {
          testComplexity +='if (index <= ${i}.5) {\n';
        } else {
          testComplexity += '   else if (index <= ${i}.5) {\n';
        }

        testComplexity += '      fragColor = vec4(1.0);\n';
        testComplexity += '   }\n';
      }
      return testShader.replace('%%complexity%%', testComplexity);
    };

    var canCompile = false;
    do {
      final test = assembleTestShader(numIfs);

      final shader = gl.createShader(gl.FRAGMENT_SHADER)!;
      gl.shaderSource(shader, test);
      gl.compileShader(shader);

      canCompile = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
      if (!canCompile) {
        numIfs = (numIfs / 2) | 0;
      }
    } while (!canCompile);
    return numIfs;
  }
}