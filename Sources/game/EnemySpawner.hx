package game;

import kha.Window;
import kha.Assets;
import core.gameobjects.GameObject;

class EnemySpawner extends GameObject {
    private var _delay : Float;
    private var _time : Float = 0;

    public function new(delay : Float) {
        super()
        _delay = delay;
    }

    public override function update(delta:Float) {
        super.update(delta);
        spawning(delta);
    }

    private function spawning(delta : Float) {
        _time += delta;
        if(_time >= _delay) {
            _time = 0;
            spawnFighter();
        }
    }

    private function spawnFighter() {
        var fighter = new Enemy(Assets.images.enemy_fighter_red, Window.get(0).width / 2, 0, 100);
        this._parentScene.add(fighter);
    }
}