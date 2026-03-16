import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'liquid_glass_render_scope.dart';

class LiquidGlassSettings with EquatableMixin {
  const LiquidGlassSettings({
    this.visibility = 1.0,
    this.glassColor = const Color.fromARGB(0, 255, 255, 255),
    this.thickness = 20,
    this.blur = 5,
    this.chromaticAberration = .01,
    this.lightAngle = 0.5 * pi,
    this.lightIntensity = .5,
    this.ambientStrength = 0,
    this.refractiveIndex = 1.2,
    this.saturation = 1.5,
  });

  LiquidGlassSettings.figma({
    required double refraction,
    required double depth,
    required double dispersion,
    required double frost,
    double visibility = 1.0,
    double lightIntensity = 50,
    double lightAngle = 0.5 * pi,
    Color glassColor = const Color.fromARGB(0, 255, 255, 255),
  }) : this(
          visibility: visibility,
          refractiveIndex: 1 + (refraction / 100) * 0.2,
          thickness: depth,
          chromaticAberration: 4 * (dispersion / 100),
          lightIntensity: lightIntensity / 100,
          blur: frost,
          lightAngle: lightAngle,
          ambientStrength: 0.1,
          saturation: 1.5,
          glassColor: glassColor,
        );

  static LiquidGlassSettings of(BuildContext context) {
    return LiquidGlassRenderScope.of(context).settings;
  }

  final double visibility;
  final Color glassColor;
  Color get effectiveGlassColor =>
      glassColor.withValues(alpha: glassColor.a * visibility);
  final double thickness;
  double get effectiveThickness => thickness * visibility;
  final double blur;
  double get effectiveBlur => blur * visibility;
  final double chromaticAberration;
  double get effectiveChromaticAberration => chromaticAberration * visibility;
  final double lightAngle;
  final double lightIntensity;
  double get effectiveLightIntensity => lightIntensity * visibility;
  final double ambientStrength;
  double get effectiveAmbientStrength => ambientStrength * visibility;
  final double refractiveIndex;
  final double saturation;
  double get effectiveSaturation => 1 + (saturation - 1) * visibility;

  LiquidGlassSettings copyWith({
    double? visibility,
    Color? glassColor,
    double? thickness,
    double? blur,
    double? chromaticAberration,
    double? lightAngle,
    double? lightIntensity,
    double? ambientStrength,
    double? refractiveIndex,
    double? saturation,
  }) =>
      LiquidGlassSettings(
        visibility: visibility ?? this.visibility,
        glassColor: glassColor ?? this.glassColor,
        thickness: thickness ?? this.thickness,
        blur: blur ?? this.blur,
        chromaticAberration: chromaticAberration ?? this.chromaticAberration,
        lightAngle: lightAngle ?? this.lightAngle,
        lightIntensity: lightIntensity ?? this.lightIntensity,
        ambientStrength: ambientStrength ?? this.ambientStrength,
        refractiveIndex: refractiveIndex ?? this.refractiveIndex,
        saturation: saturation ?? this.saturation,
      );

  @override
  List<Object?> get props => [
        visibility,
        glassColor,
        thickness,
        blur,
        chromaticAberration,
        lightAngle,
        lightIntensity,
        ambientStrength,
        refractiveIndex,
        saturation,
      ];
}
