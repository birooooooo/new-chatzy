"""
Creates a new 'wave right hand only' animation in huggy_wuggy.glb
by copying SelectScreenIntro and stripping all bones except right arm.
Run with:  python create_wave_anim.py
"""
import copy, json
from pygltflib import GLTF2

GLB_PATH  = "assets/models/huggy_wuggy.glb"
NEW_NAME  = "SK_Huggy|A_Huggy_Wave_SK_Huggy"
SOURCE    = "SK_Huggy|A_Huggy_SelectScreenIntro_SK_Huggy"

# ── Right-arm bone names (from inspect output) ────────────────────────────────
RIGHT_BONES = {
    "rt_shoulder_JNT_033_53_58",
    "rt_arm_JNT1_034_54_59",
    "rt_arm_JNT2_035_55_60",
    "rt_arm_JNT3_036_56_61",
    "rt_arm_JNT4_037_57_62",
    "rt_arm_JNT5_038_58_63",
    "rt_arm_JNT6_039_59_64",
    "rt_arm_JNT7_040_60_65",
    "rt_arm_JNT8_041_61_66",
    "rt_arm_JNT9_042_62_67",
    "rt_arm_JNT10_043_63_68",
    "rt_arm_JNT11_044_64_69",
}

def run():
    print(f"Loading {GLB_PATH} ...")
    glb = GLTF2().load(GLB_PATH)

    # Build node index → name map
    node_name = {i: (n.name or "") for i, n in enumerate(glb.nodes)}

    # Find source animation
    src_anim = next((a for a in glb.animations if a.name == SOURCE), None)
    if src_anim is None:
        print(f"ERROR: '{SOURCE}' not found. Available animations:")
        for a in glb.animations:
            print(f"  {a.name}")
        return

    # Check it doesn't already exist
    if any(a.name == NEW_NAME for a in glb.animations):
        print(f"Animation '{NEW_NAME}' already exists — skipping.")
        return

    # Deep-copy the animation
    new_anim = copy.deepcopy(src_anim)
    new_anim.name = NEW_NAME

    # Keep only channels whose target node is a right-arm bone
    kept = []
    removed_bones = set()
    kept_bones = set()

    for ch in new_anim.channels:
        bone = node_name.get(ch.target.node, "")
        if bone in RIGHT_BONES:
            kept.append(ch)
            kept_bones.add(bone)
        else:
            removed_bones.add(bone)

    new_anim.channels = kept

    # Keep only the samplers referenced by surviving channels
    used_sampler_ids = {ch.sampler for ch in kept}
    # Remap sampler indices
    old_samplers = new_anim.samplers
    new_samplers = []
    remap = {}
    for old_idx in sorted(used_sampler_ids):
        remap[old_idx] = len(new_samplers)
        new_samplers.append(old_samplers[old_idx])
    new_anim.samplers = new_samplers
    for ch in new_anim.channels:
        ch.sampler = remap[ch.sampler]

    # Append to GLB
    glb.animations.append(new_anim)

    # Save
    print(f"Saving {GLB_PATH} ...")
    glb.save(GLB_PATH)

    print(f"\n✅ Done! Added animation '{NEW_NAME}'")
    print(f"   Kept {len(kept_bones)} right-arm bone channels:")
    for b in sorted(kept_bones):
        print(f"     {b}")
    print(f"   Stripped {len(removed_bones)} other bones")
    print("\nHot-restart your Flutter app to see the wave!")

run()
