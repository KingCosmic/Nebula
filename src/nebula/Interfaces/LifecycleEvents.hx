package nebula.interfaces;

import nebula.Engine;
import nebula.Events;
import nebula.Scene;
import nebula.graphics.context.ExcaliburGraphicsContext;

interface Initialize {
  function _initialize(engine: Engine): Void;
}
interface Add {
  function onAdd(scene: Scene): Void;
}
interface Remove {
  function onRemove(engine: Engine): Void;
}

/**
 * Type guard checking for internal initialize method
 * @internal
 * @param a
 */
function has_initialize(a: Any) {
  return !!a._initialize;
}

/**
 *
 */
function has_add(a: Any) {
  return !!a.onAdd;
}

/**
 *
 */
function has_remove(a: Any) {
  return !!a.onRemove;
}

interface OnInitialize {
  function onInitialize(engine: Engine): Void;
}

/**
 *
 */
function hasOnInitialize(a: Any) {
  return !!a.onInitialize;
}


interface Preupdate {
  function _preupdate(engine: Engine, elapsed: Int): Void;
}

/**
 *
 */
function has_preupdate(a: Any) {
  return !!a._preupdate;
}

interface OnPreUpdate {
  function onPreUpdate(engine: Engine, elapsed: Int): Void;
}

/**
 *
 */
function hasOnPreUpdate(a: Any) {
  return !!a.onPreUpdate;
}


interface Postupdate {
  function _postupdate(engine: Engine, elapsed: Int): Void;
}

/**
 *
 */
function has_postupdate(a: Any) {
  return !!a.onPostUpdate;
}

interface OnPostUpdate {
  function onPostUpdate(engine: Engine, elapsed: Int): Void;
}

/**
 *
 */
function hasOnPostUpdate(a: Any) {
  return !!a.onPostUpdate;
}

interface CanInitialize {
  /**
   * Overridable implementation
   */
  function onInitialize(engine: Engine): Void;
}

interface OnAdd {
  function onAdd(engine: Engine): Void;
}

/**
 *
 */
function hasOnAdd(a: Any) {
  return !!a.onAdd;
}

interface CanAdd {
  function onAdd(engine: Engine): Void;
}

interface OnRemove {
  function onRemove(engine: Engine): Void;
}

/**
 *
 */
function hasOnRemove(a: Any) {
  return !!a.onRemove;
}

interface CanRemove {
  function onRemove(engine: Engine): Void;
}

interface SceneActivationContext<TData, TPreviousSceneData> {
  var data: Null<TData>;
  var previousScene: Scene;
  var previousSceneData: Null<TPreviousSceneData>;
  var nextScene: Scene;
  var engine: Engine;
}

interface CanActivate<TData> {
  /**
   * Overridable implementation
   */
  function onActivate(context: SceneActivationContext<TData>): Void;
}

interface CanDeactivate {
  /**
   * Overridable implementation
   */
  function onDeactivate(context: SceneActivationContext<Any>): Void;
}

interface CanUpdate {
  /**
   * Overridable implementation
   */
  function onPreUpdate(engine: Engine, elapsed: Int): Void;

  /**
   * Overridable implementation
   */
  function onPostUpdate(engine: Engine, elapsed: Int): Void;
}

interface OnPreDraw {
  /**
   * Overridable implementation
   */
  function onPreDraw(ctx: ExcaliburGraphicsContext, elapsed: Int): Void;
}

interface OnPostDraw {
  /**
   * Overridable implementation
   */
  function onPostDraw(ctx: ExcaliburGraphicsContext, elapsed: Int): Void;
}

/**
 *
 */
function hasPreDraw(a: Any) {
  return !!a.onPreDraw;
}

/**
 *
 */
function hasPostDraw(a: Any) {
  return !!a.onPostDraw;
}

interface CanBeKilled {
  /**
   * Overridable implementation
   */
  function onPreKill(_scene: Scene): Void;

  /**
   * Overridable implementation
   */
  function onPostKill(_scene: Scene): Void;
}
