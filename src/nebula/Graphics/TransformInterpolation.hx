package nebula.graphics;

import nebula.math.Transform;

class TransformInterpolation {
  /**
   * Blend 2 transforms for interpolation, will interpolate from the context of newTx's parent if it exists
   */
  public static function blendTransform(oldTx: Transform, newTx: Transform, blend: Float, ?target: Transform): Transform {
    if (oldTx.parent != newTx.parent) {
      // Caller expects a local transform
      // Adjust old tx to be local to the new parent whatever that is
      final oldTxWithNewParent = oldTx.clone();
      final oldGlobalPos = oldTx.globalPos.clone();
      final oldGlobalScale = oldTx.globalScale.clone();
      final oldGlobalRotation = oldTx.globalRotation;
      oldTxWithNewParent.parent = newTx.parent;
      oldTxWithNewParent.globalPos = oldGlobalPos;
      oldTxWithNewParent.globalScale = oldGlobalScale;
      oldTxWithNewParent.globalRotation = oldGlobalRotation;
      oldTx = oldTxWithNewParent;
    }
    var interpolatedPos = newTx.pos;
    var interpolatedScale = newTx.scale;
    var interpolatedRotation = newTx.rotation;

    interpolatedPos = newTx.pos.scale(blend).add(oldTx.pos.scale(1.0 - blend));
    interpolatedScale = newTx.scale.scale(blend).add(oldTx.scale.scale(1.0 - blend));
    // Rotational lerp https://stackoverflow.com/a/30129248
    final cosine = (1.0 - blend) * Math.cos(oldTx.rotation) + blend * Math.cos(newTx.rotation);
    final sine = (1.0 - blend) * Math.sin(oldTx.rotation) + blend * Math.sin(newTx.rotation);
    interpolatedRotation = Math.atan2(sine, cosine);

    final tx = target ?? new Transform();
    tx.setTransform(interpolatedPos, interpolatedRotation, interpolatedScale);
    return tx;
  }

  /**
   *
   */
  public static function blendGlobalTransform(oldTx: Transform, newTx: Transform, blend: Float, ?target: Transform): Transform {
    var interpolatedPos = newTx.globalPos;
    var interpolatedScale = newTx.globalScale;
    var interpolatedRotation = newTx.globalRotation;

    interpolatedPos = newTx.globalPos.scale(blend).add(oldTx.globalPos.scale(1.0 - blend));
    interpolatedScale = newTx.globalScale.scale(blend).add(oldTx.globalScale.scale(1.0 - blend));
    // Rotational lerp https://stackoverflow.com/a/30129248
    final cosine = (1.0 - blend) * Math.cos(oldTx.globalRotation) + blend * Math.cos(newTx.globalRotation);
    final sine = (1.0 - blend) * Math.sin(oldTx.globalRotation) + blend * Math.sin(newTx.globalRotation);
    interpolatedRotation = Math.atan2(sine, cosine);

    final tx = target ?? new Transform();
    tx.setTransform(interpolatedPos, interpolatedRotation, interpolatedScale);
    return tx;
  }
}