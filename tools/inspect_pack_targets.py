import bpy, pathlib, json
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'EverythingLibrary_Animals_002.blend'))
names=['Rhino','SnowyOwl','GreenFrog','Otter','Elephant','Tortoise','Chimpanzee']
report=[]
for name in names:
    root=bpy.data.objects[name]
    meshes=[o for o in [root]+list(root.children_recursive) if o.type=='MESH']
    points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    report.append({'name':name,'bounds':[[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)],'meshes':[{'name':o.name,'rotation':list(o.rotation_euler),'matrix': [list(row) for row in o.matrix_world],'attributes':[(a.name,a.data_type,a.domain) for a in o.data.attributes],'materials':[{'name':m.name,'nodes':[(n.name,n.type) for n in m.node_tree.nodes], 'links':[(l.from_node.name,l.from_socket.name,l.to_node.name,l.to_socket.name) for l in m.node_tree.links]} for m in o.data.materials if m and m.use_nodes]} for o in meshes]})
(ROOT/'tools/new_pack_targets.json').write_text(json.dumps(report,indent=2))
print('TARGET_INSPECTION_COMPLETE')
