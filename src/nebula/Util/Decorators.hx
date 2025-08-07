package nebula.util;

import nebula.Flags;
import nebula.util.Log;

/**
 * Obsolete decorator options
 */
interface ObsoleteOptions {
  // Optionally specify a custom message
  message?: String;
  // Optionally indicate that an alternate method to the obsolete one exists
  alternateMethod?: String;
  // Optional show stack trace, by default off
  showStackTrace?: Bool;
}

final maxMessages: Int = 5;
final obsoleteMessage: { [messageCount: String]: Int } = {};
final resetObsoleteCounter = () -> {
  for (message in obsoleteMessage) {
    obsoleteMessage[message] = 0;
  }
};

function logMessage(message: String, options: ObsoleteOptions): Void {
  final suppressObsoleteMessages = Flags.isEnabled('suppress-obsolete-message');
  if (obsoleteMessage[message] < maxMessages && !suppressObsoleteMessages) {
    Logger.getInstance().warn(message);

    // tslint:disable-next-line: no-console
    if (console.trace && options.showStackTrace) {
      // tslint:disable-next-line: no-console
      console.trace();
    }
  }
  obsoleteMessage[message]++;
};

/**
 * Obsolete decorator for marking Excalibur methods obsolete, you can optionally specify a custom message and/or alternate replacement
 * method do the deprecated one. Inspired by https://github.com/jayphelps/core-decorators.js
 */
function obsolete(options?: ObsoleteOptions): dynamic {
  options = {
    message: 'This feature will be removed in future versions of Excalibur.',
    alternateMethod: null,
    showStackTrace: false,
    ...options
  };

  return function (target: dynamic, property: String, descriptor: PropertyDescriptor): dynamic {
    if (
      descriptor &&
      !(typeof descriptor.value === 'function' || typeof descriptor.get === 'function' || typeof descriptor.set === 'function')
    ) {
      throw new SyntaxError('Only classes/functions/getters/setters can be marked as obsolete');
    }
    final methodSignature = '${target.name || ''}${target.name && property ? '.' : ''}${property ? property : ''}';

    final message =
      '${methodSignature} is marked obsolete: ${options.message}' +
      (options.alternateMethod ? ' Use ${options.alternateMethod} instead' : '');

    if (!obsoleteMessage[message]) {
      obsoleteMessage[message] = 0;
    }

    // If descriptor is null it is a class
    final method = descriptor ? { ...descriptor } : target;
    if (!descriptor) {
      // with es2015 classes we need to change our decoration tactic
      class DecoratedClass extends method {
        constructor(...args: any) {
          logMessage(message, options);
          super(...args);
        }
      }
      return DecoratedClass;
    }

    if (descriptor && descriptor.value) {
      method.value = function (this: dynamic) {
        logMessage(message, options);
        return descriptor.value.apply(this, arguments);
      };
      return method;
    }

    if (descriptor && descriptor.get) {
      method.get = function (this: dynamic) {
        logMessage(message, options);
        return descriptor.get.apply(this, arguments);
      };
    }

    if (descriptor && descriptor.set) {
      method.set = function (this: dynamic) {
        logMessage(message, options);
        return descriptor.set.apply(this, arguments);
      };
    }
    return method;
  };
}
