// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Geometry precomputation shader for blended liquid glass shapes
// This shader pre-computes the refraction displacement and encodes it into a texture
// Only needs to be re-run when shape geometry or layout changes

#version 460 core
precision mediump float;

#include <flutter/runtime_effect.glsl>
#include "shared.glsl"
#include "displacement_encoding.glsl"

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform vec4 uGlassColor;             // r, g, b, a
layout(location = 2) uniform vec4 uOpticalProps;           // refractiveIndex, chromaticAberration, thickness, blend
layout(location = 3) uniform vec4 uLightConfig;            // angle, intensity, ambient, saturation
layout(location = 4) uniform vec2 uLightDirection;         // pre-computed cos(angle), sin(angle)

// Extract individual values for backward compatibility
float uChromaticAberration = uOpticalProps.y;
float uLightIntensity = uLightConfig.y;
float uAmbientStrength = uLightConfig.z;
float uThickness = uOpticalProps.z;
float uRefractiveIndex = uOpticalProps.x;
float uSaturation = uLightConfig.w;

layout(location = 0) uniform sampler2D uGeometryTexture;
layout(location = 1) uniform sampler2D uBackgroundTexture;

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    
    #ifdef IMPELLER_TARGET_OPENGLES
        vec2 screenUV = vec2(fragCoord.x / uSize.x, 1.0 - (fragCoord.y / uSize.y));
    #else
        vec2 screenUV = vec2(fragCoord.x / uSize.x, fragCoord.y / uSize.y);
    #endif
    
    vec4 encodedData = texture(uGeometryTexture, screenUV);
    float foregroundAlpha = encodedData.a;
    
    if (foregroundAlpha < 0.01) {
        fragColor = vec4(0.0);
        return;
    }
    
    float maxDisplacement = uThickness * 10.0;
    vec2 displacement = decodeDisplacement(encodedData, maxDisplacement);
    float height = decodeHeight(encodedData, uThickness);
    
    float invRefractiveIndex = 1.0 / uRefractiveIndex;
    vec2 invUSize = 1.0 / uSize;
    
    // Simple displacement-based refraction calculation
    // Instead of full vector math, we use the precomputed displacement
    vec4 refractColor;
    if (uChromaticAberration < 0.001) {
        vec2 refractedUV = screenUV + displacement * invUSize;
        refractColor = texture(uBackgroundTexture, refractedUV);
    } else {
        float dispersionStrength = uChromaticAberration * 0.5;
        vec2 redOffset = displacement * (1.0 + dispersionStrength);
        vec2 blueOffset = displacement * (1.0 - dispersionStrength);
        
        vec2 redUV = screenUV + redOffset * invUSize;
        vec2 greenUV = screenUV + displacement * invUSize;
        vec2 blueUV = screenUV + blueOffset * invUSize;
        
        float red = texture(uBackgroundTexture, redUV).r;
        vec4 greenSample = texture(uBackgroundTexture, greenUV);
        float blue = texture(uBackgroundTexture, blueUV).b;
        refractColor = vec4(red, greenSample.g, blue, greenSample.a);
    }
    
    vec3 backgroundColor = refractColor.rgb;
    
    // Fast normal estimation from encoded height
    float dx = dFdx(height);
    float dy = dFdy(height);
    vec3 normal = normalize(vec3(dx, dy, 1.0));
    
    // Lighting with background color tinting
    vec3 lighting = calculateLighting(screenUV, normal, -1.0, uThickness, height, uLightDirection, uLightIntensity, uAmbientStrength, backgroundColor);
    
    vec4 finalColor = applyGlassColor(refractColor, uGlassColor);
    finalColor.rgb += lighting;
    finalColor.rgb = applySaturation(finalColor.rgb, uSaturation);
    
    fragColor = mix(vec4(0, 0, 0, 0), finalColor, foregroundAlpha);
}
