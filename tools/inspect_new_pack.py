import bpy, json, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'EverythingLibrary_Animals_002.blend'))
report = {'collections': [{'name': c.name, 'objects': [o.name for o in c.all_objects]} for c in bpy.data.collections], 'objects': []}
for o in bpy.data.objects:
    report['objects'].append({'name': o.name, 'type': o.type, 'parent': o.parent.name if o.parent else None, 'collections': [c.name for c in o.users_collection], 'dimensions': list(o.dimensions), 'vertices': len(o.data.vertices) if o.type == 'MESH' else 0, 'materials': [m.name for m in o.data.materials if m] if o.type == 'MESH' else [], 'modifiers': [{'type': m.type, 'name': m.name} for m in o.modifiers]})
report['actions'] = [a.name for a in bpy.data.actions]
report['images'] = [{'name': i.name, 'path': i.filepath, 'packed': bool(i.packed_file)} for i in bpy.data.images]
(ROOT / 'tools/new_pack_inventory.json').write_text(json.dumps(report, indent=2))
print('PACK_INVENTORY_COMPLETE', len(report['objects']), len(report['collections']))
