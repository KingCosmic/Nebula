package game;

import core.GameObject;
import kha.Window;
import kha.graphics2.Graphics;
import kha.Image;
import core.TileSprite;

class BackgroundScroller extends GameObject {
    private var _image : Image;
    private var _velocity : Int = 40;
    private var _bg1 : TileSprite;
    private var _bg2 : TileSprite;
    private var _repeatX : Int;
    private var _repeatY : Int;

    public function new(image : Image, repeatX : Int, repeatY : Int) {
        super();
        _image = image;
        _repeatX = repeatX;
        _repeatY = repeatY;
        _bg1 = new TileSprite(_image, 0, 0, _repeatX, _repeatY);
        _bg2 = new TileSprite(_image, 0, _image.height * _repeatY, _repeatX, _repeatX);
        layer = 0;
    }

    public override function draw(graphics : Graphics) {
        _bg1.draw(graphics);
        _bg2.draw(graphics);
    }

    public override function update(delta : Float) {
        scroll(delta);
    }

    private function scroll(delta : Float) {
        //Scroll backgrounds
        var bg1_position = _bg1.getPosition();
        var bg2_position = _bg2.getPosition();

        bg1_position.y += _velocity * delta;
        bg2_position.y += _velocity * delta;

        //if bg1 goes offsreen, stick it back ontop of bg2
        if(bg1_position.y > Window.get(0).height) {
            bg1_position.y = bg2_position.y - _image.height * _repeatY;
        }

        //if bg2 goes offscreen, stick it back ontop of bg1
        if(bg2_position.y > Window.get(0).height) {
            bg2_position.y = bg1_position.y - _image.height * _repeatY;
        }

        _bg1.setPosition(bg1_position.x, bg1_position.y);
        _bg2.setPosition(bg2_position.x, bg2_position.y);
    }
}