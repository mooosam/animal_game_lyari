import bpy, pathlib, json
from mathutils import Vector
root=pathlib.Path(__file__).resolve().parents[1]/'3d_model_assets/assets/models'
names=['rhinoceros','low-poly-owl_','low-poly-frog_','low-poly-otter_','african-elephant-character']
for name in names:
    p=next(p for p in root.rglob('*.blend') if name in p.name)
    bpy.ops.wm.open_mainfile(filepath=str(p))
    meshes=[o for o in bpy.data.objects if o.type=='MESH']
    points=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
    print('AUDIT',json.dumps({'name':name,'file':str(p),'bounds':[[min(v[i] for v in points),max(v[i] for v in points)] for i in range(3)],'meshes':[{'name':o.name,'vertices':len(o.data.vertices),'materials':[m.name for m in o.data.materials if m]} for o in meshes]}))
