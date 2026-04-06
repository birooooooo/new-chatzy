"""
Huggy Wuggy - Isolated Right-Hand Wave Animation
=================================================
How to use:
  1. Open Blender
  2. File > Open → open assets/models/huggy_wuggy.glb
     (or File > Import > glTF 2.0 if .glb isn't opening directly)
  3. Go to the "Scripting" tab at the top
  4. Click "New" to create a new script
  5. Paste this entire file into the editor
  6. Click "Run Script" (▶ button or Alt+P)
  7. When done, File > Export > glTF 2.0
       - Output file: assets/models/huggy_wuggy.glb  (overwrite)
       - Format: glTF Binary (.glb)
       - Include: ✅ Selected Objects, ✅ Animations
  8. Replace the file in your Flutter project and hot-restart
"""

import bpy

# ─── Config ───────────────────────────────────────────────────────────────────
SOURCE_ACTION   = 'A_Huggy_SelectScreenIntro_SK_Huggy'   # animation to copy from
NEW_ACTION_NAME = 'SK_Huggy|A_Huggy_Wave_SK_Huggy'       # new action name

# Right-arm/hand bone names — Huggy Wuggy rig typically uses these.
# If nothing moves after running, open the Armature's Pose Mode and
# note the exact bone names, then update this list.
RIGHT_ARM_BONES = {
    # Upper arm
    'RightArm', 'upperarm_r', 'UpperArm_R',
    'Upperarm.R', 'upper_arm.R', 'DEF-upper_arm.R',
    'SK_Huggy_RightArm',
    # Lower arm / forearm
    'RightForeArm', 'forearm_r', 'ForeArm_R',
    'Forearm.R', 'lower_arm.R', 'DEF-forearm.R',
    'SK_Huggy_RightForeArm',
    # Hand
    'RightHand', 'hand_r', 'Hand_R',
    'Hand.R', 'DEF-hand.R',
    'SK_Huggy_RightHand',
    # Fingers (optional — keep for more realistic wave)
    'RightHandIndex1', 'RightHandIndex2', 'RightHandIndex3',
    'RightHandMiddle1', 'RightHandMiddle2', 'RightHandMiddle3',
    'RightHandRing1',   'RightHandRing2',   'RightHandRing3',
    'RightHandPinky1',  'RightHandPinky2',  'RightHandPinky3',
    'RightHandThumb1',  'RightHandThumb2',  'RightHandThumb3',
    # Also keep shoulder so the raise looks natural
    'RightShoulder', 'shoulder_r', 'Shoulder_R', 'Shoulder.R',
    'SK_Huggy_RightShoulder',
}

# ─── Main script ──────────────────────────────────────────────────────────────

def run():
    # 1. Find the armature
    armature = None
    for obj in bpy.data.objects:
        if obj.type == 'ARMATURE':
            armature = obj
            print(f"Found armature: {obj.name}")
            break

    if armature is None:
        print("ERROR: No armature found. Make sure the GLB is imported.")
        return

    # 2. Find source action
    source = bpy.data.actions.get(SOURCE_ACTION)
    if source is None:
        print(f"ERROR: Action '{SOURCE_ACTION}' not found.")
        print("Available actions:")
        for a in bpy.data.actions:
            print(f"  - {a.name}")
        return

    # 3. Duplicate the action
    new_action = source.copy()
    new_action.name = NEW_ACTION_NAME
    print(f"Duplicated '{SOURCE_ACTION}' → '{NEW_ACTION_NAME}'")

    # 4. Remove fcurves for ALL bones EXCEPT right arm bones
    removed = []
    kept = []
    for fc in list(new_action.fcurves):
        # data_path looks like: pose.bones["BoneName"].location / rotation_quaternion / scale
        if 'pose.bones["' in fc.data_path:
            bone_name = fc.data_path.split('"')[1]
            if bone_name not in RIGHT_ARM_BONES:
                new_action.fcurves.remove(fc)
                if bone_name not in removed:
                    removed.append(bone_name)
            else:
                if bone_name not in kept:
                    kept.append(bone_name)

    print(f"\n✅ Kept animation for {len(kept)} bone(s):")
    for b in sorted(kept):
        print(f"   {b}")

    print(f"\n🗑  Cleared animation from {len(removed)} bone(s):")
    for b in sorted(removed):
        print(f"   {b}")

    if not kept:
        print("\n⚠️  WARNING: No right-arm bones were matched!")
        print("   Open Pose Mode on the armature and check actual bone names,")
        print("   then update RIGHT_ARM_BONES at the top of this script.")

    # 5. Assign the new action to the armature
    armature.animation_data_create()
    armature.animation_data.action = new_action
    print(f"\n✅ Assigned '{NEW_ACTION_NAME}' to '{armature.name}'")
    print("\nDone! Now export: File > Export > glTF 2.0 (.glb)")

run()
