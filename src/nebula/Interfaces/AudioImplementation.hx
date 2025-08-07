package nebula.interfaces;

import nebula.interfaces.Audio;

interface ExResponseType {
  Any;
  Blob;
  Json;
  Text;
  Document;
  ArrayBuffer;
}

class ExResponse {
  public static var type: ExResponseTypesLookup = {
    any: '',
    blob: 'blob',
    json: 'json',
    text: 'text',
    document: 'document',
    arraybuffer: 'arraybuffer'
  };
}

enum BlobOrBuffer {
  Blob;
  ArrayBuffer;
}

enum StringOrAudioBuffer {
  String;
  AudioBuffer;
}

/**
 * Represents an audio implementation like {@apilink WebAudioInstance}
 */
interface AudioImplementation {
  /**
   * XHR response type
   */
  var responseType: ExResponseType;

  /**
   * Processes raw data and transforms into sound data
   */
  function processData(data: BlobOrBuffer): Promise<StringOrAudioBuffer>;

  /**
   * Factory method that returns an instance of a played audio track
   */
  function createInstance(data: StringOrAudioBuffer): Audio;
}
