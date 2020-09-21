package core;

import kha.graphics2.Graphics;
import core.gameobjects.Image;

class TileSprite extends Image {
  private var _repeatX:Int;
  private var _repeatY:Int;

  public function new(image:kha.Image, x:Float, y:Float, repeatX:Int, repeatY:Int) {    
    super(image, x, y);
    _repeatX = repeatX;
    _repeatY = repeatY;
  }

  public override function draw(graphics:Graphics) {
    super.draw(graphics);
    for(i in 0..._repeatX) {
      for(j in 0..._repeatY) {
        graphics.drawImage(_image, getPosition().x + i * _image.width, getPosition().y + j * _image.height);
      }
    }
  }
}