import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart' show protected;
import 'package:flutter_shaders/flutter_shaders.dart';
import '../../liquid_glass_renderer.dart';
import 'snap_rect_to_pixels.dart';
import '../liquid_glass.dart';
import '../liquid_glass_blend_group.dart';
import '../logging.dart';
import '../rendering/liquid_glass_render_object.dart';

enum LiquidGlassGeometryState {
  updated,
  mightNeedUpdate,
  needsUpdate,
}

abstract class RenderLiquidGlassGeometry extends RenderProxyBox {
  RenderLiquidGlassGeometry({
    required GeometryRenderLink renderLink,
    required this.geometryShader,
    required LiquidGlassSettings settings,
    required double devicePixelRatio,
  })  : _renderLink = renderLink,
        _settings = settings,
        _devicePixelRatio = devicePixelRatio {
    updateShaderWithSettings(settings, devicePixelRatio);
  }

  final Logger logger = Logger(LgrLogNames.geometry);
  final FragmentShader geometryShader;
  LiquidGlassSettings? _settings;
  LiquidGlassSettings get settings => _settings!;
  set settings(LiquidGlassSettings value) {
    if (_settings == value) return;
    if (value.requiresGeometryRebuild(_settings)) {
      markGeometryNeedsUpdate(force: true);
    }
    _settings = value;
    updateShaderWithSettings(value, _devicePixelRatio);
    markNeedsPaint();
  }

  double _devicePixelRatio;
  double get devicePixelRatio => _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (_devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markGeometryNeedsUpdate(force: true);
    updateShaderWithSettings(settings, value);
    markNeedsPaint();
  }

  GeometryRenderLink? _renderLink;
  GeometryRenderLink? get renderLink => _renderLink;
  set renderLink(GeometryRenderLink? value) {
    if (_renderLink == value) return;
    _renderLink?.unregisterGeometry(this);
    _renderLink = value;
    _renderLink?.registerGeometry(this);
  }

  @protected
  LiquidGlassGeometryState geometryState = LiquidGlassGeometryState.needsUpdate;
  @protected
  GeometryCache? geometry;

  @protected
  void markGeometryNeedsUpdate({bool force = false}) {
    final newState = force
        ? LiquidGlassGeometryState.needsUpdate
        : LiquidGlassGeometryState.mightNeedUpdate;
    geometryState = switch ((geometryState, newState)) {
      (LiquidGlassGeometryState.needsUpdate, _) => LiquidGlassGeometryState.needsUpdate,
      (_, LiquidGlassGeometryState.needsUpdate) => LiquidGlassGeometryState.needsUpdate,
      _ => LiquidGlassGeometryState.mightNeedUpdate,
    };
  }

  @override
  void attach(PipelineOwner owner) {
    _renderLink?.registerGeometry(this);
    super.attach(owner);
  }

  @override
  void detach() {
    _renderLink?.unregisterGeometry(this);
    super.detach();
  }

  @override
  void dispose() {
    _renderLink?.unregisterGeometry(this);
    geometry?.dispose();
    geometry = null;
    super.dispose();
  }

  void updateShaderWithSettings(LiquidGlassSettings settings, double devicePixelRatio);
  void updateGeometryShaderShapes(List<ShapeGeometry> shapes);
  void paintShapeContents(RenderObject from, PaintingContext context, Offset offset, {required bool insideGlass});
  (Rect bounds, List<ShapeGeometry> geometries, bool needsUpdate) gatherShapeData();

  Path getPath(List<ShapeGeometry> geometries) {
    final path = Path();
    for (final shape in geometries) {
      path.addPath(shape.renderObject.getPath(), Offset.zero, matrix4: shape.shapeToGeometry?.storage);
    }
    return path;
  }

  GeometryCache? maybeRebuildGeometry() {
    if (geometryState == LiquidGlassGeometryState.updated && geometry != null) {
      return geometry;
    }
    final (layerBounds, shapes, anyShapeChangedInLayer) = gatherShapeData();
    if (geometryState == LiquidGlassGeometryState.mightNeedUpdate && !anyShapeChangedInLayer && geometry != null) {
      renderLink?.markRebuilt(this);
      geometry = geometry!.render();
      geometryState = LiquidGlassGeometryState.updated;
      return geometry;
    }
    geometry?.dispose();
    geometry = null;
    geometryState = LiquidGlassGeometryState.updated;
    if (shapes.isEmpty) return null;
    final snappedBounds = layerBounds.snapToPixels(devicePixelRatio);
    final matteBounds = Rect.fromLTWH(snappedBounds.left * devicePixelRatio, snappedBounds.top * devicePixelRatio, snappedBounds.width * devicePixelRatio, snappedBounds.height * devicePixelRatio).snapToPixels(1);
    final newGeo = geometry = UnrenderedGeometryCache(
      matte: _buildGeometryPicture(snappedBounds, shapes),
      bounds: snappedBounds,
      matteBounds: matteBounds,
      shapes: shapes,
      path: getPath(shapes),
    );
    _renderLink?.markRebuilt(this);
    return newGeo;
  }

  Picture _buildGeometryPicture(Rect geometryBounds, List<ShapeGeometry> shapes) {
    final bounds = geometryBounds.snapToPixels(devicePixelRatio);
    final width = (bounds.width * devicePixelRatio).ceil();
    final height = (bounds.height * devicePixelRatio).ceil();
    geometryShader.setFloatUniforms((value) {
      value..setFloat(width.toDouble())..setFloat(height.toDouble());
    });
    updateGeometryShaderShapes(shapes);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..shader = geometryShader;
    final leftPixel = (geometryBounds.left * devicePixelRatio).roundToDouble();
    final topPixel = (geometryBounds.top * devicePixelRatio).roundToDouble();
    canvas..translate(-leftPixel, -topPixel)..drawRect(Rect.fromLTWH(leftPixel, topPixel, width.toDouble(), height.toDouble()), paint);
    return recorder.endRecording();
  }
}

sealed class GeometryCache {
  const GeometryCache({required this.matteBounds, required this.bounds, required this.shapes, required this.path});
  final Rect bounds;
  final Rect matteBounds;
  final List<ShapeGeometry> shapes;
  final Path path;
  RenderedGeometryCache render();
  Future<RenderedGeometryCache> renderAsync();
  void dispose();
}

class UnrenderedGeometryCache extends GeometryCache {
  const UnrenderedGeometryCache({required this.matte, required super.matteBounds, required super.bounds, required super.shapes, required super.path});
  final Picture matte;
  @override
  Future<RenderedGeometryCache> renderAsync() async {
    final image = await matte.toImage(matteBounds.width.ceil(), matteBounds.height.ceil());
    return RenderedGeometryCache(matte: image, matteBounds: matteBounds, bounds: bounds, shapes: shapes, path: path);
  }
  @override
  RenderedGeometryCache render() {
    final image = matte.toImageSync(matteBounds.width.ceil(), matteBounds.height.ceil());
    dispose();
    return RenderedGeometryCache(matte: image, matteBounds: matteBounds, bounds: bounds, shapes: shapes, path: path);
  }
  @override
  void dispose() => matte.dispose();
}

class RenderedGeometryCache extends GeometryCache {
  const RenderedGeometryCache({required this.matte, required super.matteBounds, required super.bounds, required super.shapes, required super.path});
  final Image matte;
  @override
  RenderedGeometryCache render() => this;
  @override
  Future<RenderedGeometryCache> renderAsync() => Future.value(this);
  @override
  void dispose() => matte.dispose();
}

extension on LiquidGlassSettings {
  bool requiresGeometryRebuild(LiquidGlassSettings? other) {
    if (other == null) return false;
    return effectiveThickness != other.effectiveThickness || refractiveIndex != other.refractiveIndex;
  }
}

enum RawShapeType {
  squircle(1), ellipse(2), roundedRectangle(3);
  const RawShapeType(this.shaderIndex);
  final double shaderIndex;
  static RawShapeType fromLiquidGlassShape(LiquidShape shape) {
    switch (shape) {
      case LiquidRoundedSuperellipse(): return RawShapeType.squircle;
      case LiquidOval(): return RawShapeType.ellipse;
      case LiquidRoundedRectangle(): return RawShapeType.roundedRectangle;
    }
  }
}

class ShapeGeometry extends Equatable {
  ShapeGeometry({required this.renderObject, required this.shape, required this.glassContainsChild, required this.shapeBounds, this.shapeToGeometry}) : rawCornerRadius = _getRadiusFromGlassShape(shape), rawShapeType = RawShapeType.fromLiquidGlassShape(shape);
  static double _getRadiusFromGlassShape(LiquidShape shape) {
    switch (shape) {
      case LiquidRoundedSuperellipse(:final borderRadius): return borderRadius;
      case LiquidRoundedRectangle(:final borderRadius): return borderRadius;
      case LiquidOval(): return 0;
    }
  }
  final RenderLiquidGlass renderObject;
  final LiquidShape shape;
  final RawShapeType rawShapeType;
  final double rawCornerRadius;
  final bool glassContainsChild;
  final Rect shapeBounds;
  final Matrix4? shapeToGeometry;
  @override
  List<Object?> get props => [renderObject, shape, glassContainsChild, shapeBounds];
}
