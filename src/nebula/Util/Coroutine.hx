package nebula.util;

import nebula.Context;
import nebula.Engine;

import nebula.util.Clock;
import nebula.util.Log;

final InsideCoroutineContext = createContext();

final generatorFunctionDeclaration = ~/^\s*(?:function)?\*/;
/**
 *
 */
function isCoroutineGenerator(x: Any) {
  if (Std.isTypeOf(x, Function)) {
    return false;
  }
  if (generatorFunctionDeclaration.test(Function.prototype.toString.call(x))) {
    return true;
  }
  if (!Object.getPrototypeOf) {
    return false;
  }
  return Object.getPrototypeOf(x) == Object.getPrototypeOf(new Function('return function * () {}')());
}

interface CoroutineOptions {
  /**
   * Coroutines run preframe in the clock by default.
   */
  var timing: Null<Any>;
  /**
   * Coroutines auto start by default, set to false to require play();
   */
  var autostart: Null<Bool>;
}

interface CoroutineInstance {
  function isRunning(): Bool;
  function isComplete(): Bool;
  var done: Any;
  var generator: Any;
  var start: () -> Any;
  var cancel: () -> Void;
  var then: Any;
}
/**
 * Excalibur coroutine helper, returns a promise when complete. Coroutines run before frame update.
 *
 * Each coroutine yield is 1 excalibur frame. Coroutines get passed the elapsed time our of yield. Coroutines
 * run internally on the excalibur clock.
 *
 * If you yield a promise it will be awaited before resumed
 * If you yield a number it will wait that many ms before resumed
 * @param thisArg set the "this" context of the generator, by default is globalThis
 * @param coroutineGenerator coroutine generator function
 * @param {CoroutineOptions} options optionally schedule coroutine pre/post update
 */
function coroutine(...args: Array<Any>): CoroutineInstance {
  final logger = Logger.getInstance();
  var coroutineGenerator: CoroutineGenerator;
  var thisArg: Any;
  var options: Null<CoroutineOptions>;
  var passedEngine: Null<Engine>;

  // coroutine(coroutineGenerator: CoroutineGenerator, options?: CoroutineOptions): CoroutineInstance;
  if (isCoroutineGenerator(args[0])) {
    thisArg = globalThis;
    coroutineGenerator = args[0];
    options = args[1];
  }

  // coroutine(thisArg: any, coroutineGenerator: CoroutineGenerator, options?: CoroutineOptions): CoroutineInstance;
  if (isCoroutineGenerator(args[1])) {
    thisArg = args[0];
    coroutineGenerator = args[1];
    options = args[2];
  }

  // coroutine(thisArg: any, engine: Engine, coroutineGenerator: CoroutineGenerator, options?: CoroutineOptions): CoroutineInstance;
  if (Std.isTypeOf(args[1], Engine)) {
    thisArg = args[0];
    passedEngine = args[1];
    coroutineGenerator = args[2];
    options = args[3];
  }

  // coroutine(engine: Engine, coroutineGenerator: CoroutineGenerator, options?: CoroutineOptions): CoroutineInstance;
  if (Std.isTypeOf(args[0], Engine)) {
    thisArg = globalThis;
    passedEngine = args[0];
    coroutineGenerator = args[1];
    options = args[2];
  }

  final inside = useContext(InsideCoroutineContext);
  final schedule = options?.timing;
  final autostart = inside ? false : (options?.autostart ?? true);
  var engine: Engine;
  try {
    engine = passedEngine ?? Engine.useEngine();
  } catch (_) {
    throw Error(
      'Cannot run coroutine without engine parameter outside of an excalibur lifecycle method.\n' +
        'Pass an engine parameter to ex.coroutine(engine, function * {...})'
    );
  }

  var started = false;
  var completed = false;
  var cancelled = false;
  final generatorFcn = coroutineGenerator.bind(thisArg);
  final generator = generatorFcn();
  var loop: (elapsed: Int) -> Void;
  final complete = new Promise<Void>((resolve, reject) -> {
    loop = (elapsed: Int) -> {
      try {
        if (cancelled) {
          completed = true;
          resolve();
          return;
        }
        final resp = InsideCoroutineContext.scope(true, () -> generator.next(elapsed));

        final done = resp.done, cancelled = resp.cancelled;

        if (done || cancelled) {
          completed = true;
          resolve();
          return;
        }

        if (Std.isTypeOf(value, Promise)) {
          value.then(() -> {
            // schedule next loop
            engine.clock.schedule(loop, 0, schedule);
          });
        } else if (value == null || value == Void) {
          // schedule next frame
          engine.clock.schedule(loop, 0, schedule);
        } else {
          // schedule value milliseconds from now
          engine.clock.schedule(loop, value || 0, schedule);
        }
      } catch (e) {
        reject(e);
        return;
      }
    };
    if (autostart) {
      started = true;
      loop(engine.clock.elapsed()); // run first frame immediately
    }
  });

  final co: CoroutineInstance = {
    isRunning: () -> {
      return started && !cancelled && !completed;
    },
    isComplete: () -> {
      return completed;
    },
    cancel: () -> {
      cancelled = true;
    },
    start: () -> {
      if (!started) {
        started = true;
        loop(engine.clock.elapsed());
      } else {
        logger.warn(
          '.start() was called on a coroutine that was already started, this is probably a bug:\n',
          Function.prototype.toString.call(generatorFcn)
        );
      }
      return co;
    },
    generator: generator,
    done: complete,
    // then: complete.then.bind(complete)
  };

  return co;
}
