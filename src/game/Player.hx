package game;

import core.gameobjects.Image;
import core.scene.Scene;
import kha.Assets;

class Player extends Image {
  public function new(_scene:Scene, _x:Float, _y:Float) {
    super(_scene, _x, _y, Assets.images.dude);
  }
}