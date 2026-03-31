import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:meta/meta.dart' show visibleForTesting;

@visibleForTesting
bool isLocalTest = false;

final String _shadersRoot = ''; // Shaders are in the same project, assets-relative path will work

abstract class ShaderKeys {
  const ShaderKeys._();

  static const blendedGeometry =
      'lib/widgets/liquid_glass/src/assets/shaders/liquid_glass_geometry_blended.frag';
  static const liquidGlassRender =
      'lib/widgets/liquid_glass/src/assets/shaders/liquid_glass_final_render.frag';
  static const liquidGlassFilterShader =
      'lib/widgets/liquid_glass/src/assets/shaders/liquid_glass_filter.frag';
  static const fakeGlassColor =
      'lib/widgets/liquid_glass/src/assets/shaders/fake_glass_color.frag';
}
