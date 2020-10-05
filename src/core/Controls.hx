package core;

class Controls {
    public var W : Bool;
    public var A : Bool;
    public var S : Bool;
    public var D : Bool;
    public var ENTER : Bool;
    public var ESCAPE : Bool;
    public var LEFT : Bool;
    public var RIGHT : Bool;
    public var DOWN : Bool;
    public var UP : Bool;
    public var SPACE : Bool;
    public var MOUSE_X : Int;
    public var MOUSE_Y : Int;
    public var MOUSE_LEFT : Bool;
    public var MOUSE_RIGHT : Bool;

    public function new() {
        W = false;
        A = false;
        S = false;
        D = false;
        ENTER = false;
        ESCAPE = false;
        LEFT = false;
        RIGHT = false;
        DOWN = false;
        UP = false;
        SPACE = false;
        MOUSE_X = 0;
        MOUSE_Y = 0;
        MOUSE_LEFT = false;
        MOUSE_RIGHT = false;
    }
}