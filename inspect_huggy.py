from pygltflib import GLTF2

glb = GLTF2().load("assets/models/huggy_wuggy.glb")

print("=== ANIMATIONS ===")
for i, anim in enumerate(glb.animations):
    print(f"[{i}] {anim.name}")

print("\n=== ANIMATION CHANNELS (first animation) ===")
if glb.animations:
    anim = glb.animations[0]
    nodes_used = set()
    for ch in anim.channels:
        node_idx = ch.target.node
        if node_idx is not None:
            node = glb.nodes[node_idx]
            nodes_used.add(node.name)
    for n in sorted(nodes_used):
        print(f"  bone: {n}")
