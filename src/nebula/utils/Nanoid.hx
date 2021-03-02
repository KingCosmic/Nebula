package nebula.utils;

import haxe.Timer;
import haxe.Int64;

class Nanoid {
	public inline static var NANO_ID_ALPHABET = "_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

	static var rndSeed:Int = Std.int(Timer.stamp() * 1000);
	static var state0 = splitmix64_seed(rndSeed);
	static var state1 = splitmix64_seed(rndSeed + 1);

	private static function splitmix64_seed(index:Int):Int64 {
		var result:Int64 = (index + Int64.make(0x9E3779B9, 0x7F4A7C15));
		result = (result ^ (result >> 30)) * Int64.make(0xBF58476D, 0x1CE4E5B9);
		result = (result ^ (result >> 27)) * Int64.make(0x94D049BB, 0x133111EB);
		return result ^ (result >> 31);
	}

	private static function randomFromRange(min:Int, max:Int):Int {
		var s1:Int64 = state0;
		var s0:Int64 = state1;

		state0 = s0;
		s1 ^= s1 << 23;
		state1 = s1 ^ s0 ^ (s1 >>> 18) ^ (s0 >>> 5);

		var result:Int = ((state1 + s0) % (max - min + 1)).low;

		result = (result < 0) ? -result : result;
		return result + min;
	}

	private static function randomByte():Int {
		return randomFromRange(0, 255);
	}

	public static inline function generate(len:Int = 21, alphabet:String = NANO_ID_ALPHABET, ?randomFunc:Void->Int):String {
		if (randomFunc == null)
			randomFunc = randomByte;

		if (alphabet == null)
			throw "Alphabet cannot be null";

		if (alphabet.length == 0 || alphabet.length >= 256)
			throw "Alphabet must contain between 1 and 255 symbols";

		if (len <= 0)
			throw "Length must be greater than zero";

		var mask:Int = (2 << Math.floor(Math.log(alphabet.length - 1) / Math.log(2))) - 1;
		var step:Int = Math.ceil(1.6 * mask * len / alphabet.length);
		var sb = new StringBuf();
		while (sb.length != len) {
			for (i in 0...step) {
				var rnd = randomFunc();
				var aIndex:Int = rnd & mask;
				if (aIndex < alphabet.length) {
					sb.add(alphabet.charAt(aIndex));
					if (sb.length == len)
						break;
				}
			}
		}
		return sb.toString();
	}
}