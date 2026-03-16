// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Final render shader using the precomputed geometry texture

#version 460 core
precision mediump float;

#include <flutter/runtime_effect.glsl>
#include "render.glsl"

void main() {
    // This shader's main is already in render.glsl in this integrated version
    // but the original package splits it. I'll consolidate for simplicity if possible
    // or keep the structure. Let's keep it clean.
}
