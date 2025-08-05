package nebula.Util;

interface NativeEventable {
  function addEventListener(name: String, handler: (...any: Array<Any>) -> Any): Any;
  function removeEventListener(name: String, handler: (...any: Array<Any>) -> Any): Any;
}

public class BrowserComponent<NativeEventable> {
  private var _paused = false;
  private var _nativeHandlers: Map<String, (h: Any) -> Void> = new Map();

  function on(eventName: String, handler: (evt: Any) -> Void): Void {
    if (this._nativeHandlers[eventName]) {
      this.off(eventName, this._nativeHandlers[eventName]);
    }
    this._nativeHandlers[eventName] = this._decorate(handler);
    this.nativeComponent.addEventListener(eventName, this._nativeHandlers[eventName]);
  }
  function off(eventName: String, handler?: (event: Any) => Void): Void {
    if (!handler) {
      handler = this._nativeHandlers[eventName];
    }
    this.nativeComponent.removeEventListener(eventName, handler);
    this._nativeHandlers[eventName] = null;
  }

  private function _decorate(handler: (evt: Any) -> Void): (evt: Any) -> Void {
    return (evt: Any) -> {
      if (!this._paused) {
        handler(evt);
      }
    };
  }

  public function pause() {
    this._paused = true;
  }

  public function resume() {
    this._paused = false;
  }

  public function clear() {
    for (event in this._nativeHandlers) {
      this.off(event);
    }
  }

  public function new(nativeComponent: T) {}
}

class BrowserEvents {
  private var _windowComponent: BrowserComponent<Window>;
  private var _documentComponent: BrowserComponent<Document>;
  public function new(
    _windowGlobal: Window,
    _documentGlobal: Document
  ) {
    this._windowComponent = new BrowserComponent(this._windowGlobal);
    this._documentComponent = new BrowserComponent(this._documentGlobal);
  }

  public var window(get, never): BrowserComponent<Window>;
  function get_window(): BrowserComponent<Window> {
    return this._windowComponent;
  }

  public var document(get, never): BrowserComponent<Document>;
  function get_document(): BrowserComponent<Document> {
    return this._documentComponent;
  }

  public function pause() {
    this.window.pause();
    this.document.pause();
  }

  public function resume() {
    this.window.resume();
    this.document.resume();
  }

  public function clear() {
    this.window.clear();
    this.document.clear();
  }
}
