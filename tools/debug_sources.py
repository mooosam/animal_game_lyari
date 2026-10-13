import bpy,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
for key in ['rhino','otter','monkey']:
 bpy.ops.wm.open_mainfile(filepath=str(root/'tools/prepared_animals'/f'{key}.blend'))
 for o in bpy.context.scene.objects:
  if o.type=='MESH':
   print('DEBUG',key,o.name,'bounds',o.dimensions[:],'mods',[(m.name,m.type,getattr(m,'mirror_object',None),getattr(m,'use_clip',None)) for m in o.modifiers])
   for m in o.data.materials:
    print('MATERIAL',m.name,m.diffuse_color[:],[(n.type,tuple(n.inputs['Color'].default_value) if 'Color' in n.inputs else '') for n in m.node_tree.nodes] if m.use_nodes else 'no nodes')
