package core.input;

import core.scene.Systems;
import core.scene.Scene;

/**
 * @classdesc
 * The Input Plugin belongs to a Scene and handles all input related events and operations for it.
 *
 * You can access it from within a Scene using `this.input`.
 *
 * It emits events directly. For example, you can do:
 *
 * ```javascript
 * this.input.on('pointerdown', callback, context);
 * ```
 *
 * To listen for a pointer down event anywhere on the game canvas.
 *
 * Game Objects can be enabled for input by calling their `setInteractive` method. After which they
 * will directly emit input events:
 *
 * ```haxe
 * var sprite = this.add.sprite(x, y, texture);
 * sprite.setInteractive();
 * sprite.on('pointerdown', callback, context);
 * ```
 *
 * There are lots of game configuration options available relating to input.
 * See the [Input Config object]{@linkcode Phaser.Types.Core.InputConfig} for more details, including how to deal with Phaser
 * listening for input events outside of the canvas, how to set a default number of pointers, input
 * capture settings and more.
 *
 * Please also see the Input examples and tutorials for further information.
 *
 * **Incorrect input coordinates with Angular**
 *
 * If you are using Phaser within Angular, and use nglf or the router, to make the component in which the Phaser game resides
 * change state (i.e. appear or disappear) then you'll need to notify the Scale Manager about this, as Angular will mess with
 * the DOM in a way in which Phaser can't detect directly. Call `this.scale.updateBounds()` as part of your game init in order
 * to refresh the canvas DOM bounds values, which Phaser uses for input point position calculations.
 */
class InputPlugin extends EventEmitter {
  // A reference to the Scene that this Input Plugin is responsible for.
  public var scene:Scene;

  // A reference to the Scene Systems class.
  public var systems:Systems;

  // A reference to the Game Input Manager.
  public var manager:InputManager;
}