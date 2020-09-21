package game;

import core.BoundingGameObject;
import kha.Assets;
import core.Sprite;

class Laser extends Sprite {
    private var _velocity : Int;

    public function new(x : Float, y : Float, velocity : Int) {
        super(Assets.images.laserRed01, x, y);
        _velocity = velocity;
        layer = 1;
        physics_on = true;
        addGroup("Lasers");
    }

    public override function update(delta:Float) {
        super.update(delta);
        move(delta);
        doDestroy();
    }

    private function move(delta : Float) {
        var y = getPosition().y;
        y += -1 * _velocity * delta;
        setY(y);
    }

    private function doDestroy() {
        if(getPosition().y < 0 + getHeight()) {
            destroy();
        }
    }

    public override function onOverlapping(other:BoundingGameObject) {
        super.onOverlapping(other);
        var groups = other.getGroups();
        for(g in groups) {
            if(g == "Enemies") {
                other.destroy();
                destroy();
                break;
            }
        }
    }
}