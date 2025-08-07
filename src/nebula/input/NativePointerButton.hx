package nebula.input;

/**
 * Native browser button enumeration
 */
enum abstract NativePointerButton(Int) from Int to Int {
  public static inline var NoButton  = -1;
  public static inline var Left      = 0;
  public static inline var Middle    = 1;
  public static inline var Right     = 2;
  public static inline var Unknown   = 3;
}
