package nebula.graphics;

class GraphicsDiagnostics {
  public static var DrawCallCount: Int = 0;
  public static var DrawnImagesCount: Int = 0;
  public static function clear(): Void {
    GraphicsDiagnostics.DrawCallCount = 0;
    GraphicsDiagnostics.DrawnImagesCount = 0;
  }
}
