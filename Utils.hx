package core;

class Utils {
    public static function getRandomInt(min: Int, max: Int) : Int {
        return Math.floor(Math.random() * (1 + max - min)) + min;
    }

    public static function getRandomFloat(min: Float, max: Float) : Float {
        return Math.floor(Math.random() * (1 + max - min)) + min; 
    }
}