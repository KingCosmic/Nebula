package nebula.interfaces;

/**
 * An interface describing loadable resources in Excalibur. Built-in loadable
 * resources include {@apilink Texture}, {@apilink Sound}, and a generic {@apilink Resource}.
 */
interface Loadable<T> {
  /**
   * Data associated with a loadable
   */
  var data: T;

  /**
   * Begins loading the resource and returns a promise to be resolved on completion
   */
  function load(): Any;

  /**
   * Returns true if the loadable is loaded
   */
  function isLoaded(): Bool;
}
