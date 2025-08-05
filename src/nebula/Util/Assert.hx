/**
 * Asserts will throw in `process.env.NODE_ENV === 'development'` builds if the expression evaluates false
 */
// function assert(message: String, expression: () => Bool) {
//   if (process.env.NODE_ENV === 'development') {
//     if (!expression()) {
//       throw new Error(message);
//     }
//   }
// }

class Assert {
  static public function assert(message: String, expression: () -> Bool) {
    
  }
}
