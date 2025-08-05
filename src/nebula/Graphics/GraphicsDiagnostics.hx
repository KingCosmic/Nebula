package nebula.Graphics;

class GraphicsDiagnostics {
  public static DrawCallCount: Int = 0;
  public static DrawnImagesCount: Int = 0;
  public static clear(): Void {
    GraphicsDiagnostics.DrawCallCount = 0;
    GraphicsDiagnostics.DrawnImagesCount = 0;
  }
}
