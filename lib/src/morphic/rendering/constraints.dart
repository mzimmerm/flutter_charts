/// Defines how a container [layout] should expand the container in a direction.
///
/// Direction can be "width" or "height".
/// Generally,
///   - If direction style is [TryFill], the container should use all
///     available length in the direction (that is, [width] or [height].
///     This is intended to fill a predefined
///     available length, such as when showing X axis labels
///   - If direction style is [GrowDoNotFill], container should use as much space
///     as needed in the direction, but stop "well before" the available length.
///     The "well before" is not really defined here.
///     This is intended to for example layout Y axis in X direction,
///     where we want to put the data container to the right of the Y labels.
///   - If direction style is [Unused], the [layout] should fail on attempted
///     looking at such
///
class LayoutExpansion {
  final double width;
  final double height;

  LayoutExpansion({
    required double width,
    required double height,
    bool used = true,
  })  : this.width = width,
        this.height = height
  {
    if (used && this.width <= 0.0) {
      throw new StateError('Invalid width $width');
    }
    if (used && this.height <= 0.0) {
      throw new StateError('Invalid height $height');
    }
  }

  /// Named constructor for unused expansion
  LayoutExpansion.unused()
      : this(
    width: -1.0,
    height: -1.0,
    used: false,
  );

  LayoutExpansion cloneWith({
    double? width,
    double? height,
  }) {
    height ??= this.height;
    width ??= this.width;
    return new LayoutExpansion(
        width: width,
        height: height
    );
  }
}