package game;

import core.BoundingGameObject;
import kha.Window;
import kha.Image;
import core.Sprite;

class Enemy extends Sprite {
    private var _velocity : Int;

    public function new(image : Image, x : Float, y : Float, vel : Int) {
        super(image, x, y);
        _velocity = vel;
        physics_on = true;
        addGroup("Enemies");
    }

    public override function update(delta:Float) {
        super.update(delta);
        move(delta);
        doDestroy();
    }

    private function move(delta:Float) {
        var y = getPosition().y;
        y += 1 * _velocity * delta;
        setY(y);
    }

    private function doDestroy() {
        if(getPosition().y > Window.get(0).height) {
            destroy();
        }
    }
}