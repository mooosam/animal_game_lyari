"""Non-destructive, repeatable model preparation in a background Blender scene."""
import bpy, math, pathlib, json
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'game/assets/animals'; OUT.mkdir(parents=True,exist_ok=True)
SOURCES=ROOT/'3d_model_assets/assets/models'
ROSTER={'rhino':('rhinoceros',2.7),'owl':('low-poly-owl_',1.45),'frog':('low-poly-frog_',1.3),'otter':('low-poly-otter_',2.1),'elephant':('african-elephant-character',2.9),'turtle':('low-poly-sea-turtle_',2.0),'monkey':('original_monkey',2.0)}
PALETTE={'rhino':(.38,.27,.70,1),'owl':(.95,.48,.10,1),'frog':(.20,.72,.07,1),'otter':(.65,.24,.07,1),'elephant':(.12,.56,.75,1),'turtle':(.14,.48,.12,1),'monkey':(.58,.21,.07,1)}
def original_monkey():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    def ball(name, at, scale, color):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=at)
        obj=bpy.context.object; obj.name=name; obj.scale=scale
        mat=bpy.data.materials.new(name); mat.diffuse_color=color; mat.use_nodes=True
        mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=color
        obj.data.materials.append(mat)
    fur=PALETTE['monkey']; cream=(1,.70,.36,1); black=(.018,.012,.008,1)
    ball('body',(0,0,1.0),(.40,.28,.55),fur)
    ball('head',(0,-.08,1.72),(.42,.34,.39),fur)
    ball('face',(0,-.36,1.70),(.32,.08,.27),cream)
    ball('muzzle',(0,-.43,1.56),(.21,.1,.11),cream)
    for side in [-1,1]:
        ball('ear',(side*.46,-.03,1.73),(.17,.12,.20),cream)
        ball('eye',(side*.13,-.445,1.78),(.057,.025,.075),black)
        ball('eye shine',(side*.14,-.467,1.80),(.015,.012,.023),(1,1,1,1))
        ball('arm',(side*.45,-.01,1.02),(.14,.16,.52),fur)
        ball('hand',(side*.46,-.11,.54),(.17,.17,.13),cream)
        ball('leg',(side*.23,.02,.38),(.17,.18,.39),fur)
        ball('foot',(side*.23,-.14,.1),(.18,.30,.1),cream)
    for i in range(9):
        t=i/8; ball('tail',(0,.22+t*.75,.80+t*t*.75),(.085,.10,.12),fur)
report=[]
for animal,(pattern,size) in ROSTER.items():
    if animal=='monkey':
        original_monkey(); source=ROOT/'tools/original_monkey.blend'
    else:
        source=next(p for p in SOURCES.rglob('*.blend') if pattern in p.name)
        bpy.ops.wm.open_mainfile(filepath=str(source))
    # Evaluate source modifiers in the source scene before switching view layers.
    depsgraph=bpy.context.evaluated_depsgraph_get()
    baked=[(o,bpy.data.meshes.new_from_object(o.evaluated_get(depsgraph),depsgraph=depsgraph),o.matrix_world.copy()) for o in bpy.context.scene.objects if o.type=='MESH']
    scene=bpy.data.scenes.new('AnimalSwitch_'+animal); bpy.context.window.scene=scene
    meshes=[]
    for original,data,source_matrix in baked:
        # Bake source mirror/subdivision modifiers before recentering. Recentring a
        # half mesh before its Mirror modifier would collapse the animal's width.
        obj=bpy.data.objects.new(original.name+'_game',data); scene.collection.objects.link(obj)
        obj.matrix_world=source_matrix; meshes.append(obj)
    pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    scale=size/max(hi.x-lo.x,hi.y-lo.y,hi.z-lo.z)
    for obj in meshes:
        matrix=obj.matrix_world.copy(); obj.parent=None; obj.matrix_world.identity()
        for v in obj.data.vertices: v.co=(matrix@v.co-center)*scale
        for slot in obj.material_slots:
            if slot.material:
                slot.material=slot.material.copy()
                if slot.material.use_nodes:
                    for node in slot.material.node_tree.nodes:
                        if node.type=='BSDF_PRINCIPLED':
                            node.inputs['Roughness'].default_value=.78
                            base=node.inputs['Base Color']
                            # Preserve dark eyes and the original monkey's face colors.
                            name=slot.material.name.lower()
                            if animal!='monkey' and not any(word in name for word in ['black','white','eye','mouth','whisk','tooth','tusk']):
                                for link in list(base.links): slot.material.node_tree.links.remove(link)
                                tint=PALETTE[animal]
                                if any(word in name for word in ['under','belly']): tint=(.95,.66,.32,1)
                                base.default_value=tint
                                slot.material.diffuse_color=tint
    pts=[v.co for o in meshes for v in o.data.vertices]
    width=max(p.x for p in pts); depth=max(abs(p.y) for p in pts); height=max(p.z for p in pts)
    armdata=bpy.data.armatures.new(animal+'_skeleton'); arm=bpy.data.objects.new(animal+'_rig',armdata)
    scene.collection.objects.link(arm); bpy.context.view_layer.objects.active=arm; arm.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    root=armdata.edit_bones.new('body'); root.head=(0,0,height*.42); root.tail=(0,0,height*.7)
    head=armdata.edit_bones.new('head'); head.head=(0,-depth*.45,height*.6); head.tail=(0,-depth*.7,height*.8); head.parent=root
    limb_names=[]
    if animal=='owl':
        for side in [-1,1]:
            b=armdata.edit_bones.new('wing_'+str(side)); b.head=(side*width*.35,0,height*.65); b.tail=(side*width,.01,height*.55); b.parent=root; limb_names.append(b.name)
    else:
        for side in [-1,1]:
            for end in [-1,1]:
                b=armdata.edit_bones.new('leg_%s_%s'%(side,end)); b.head=(side*width*.65,end*depth*.4,height*.42); b.tail=(side*width*.65,end*depth*.4,.03); b.parent=root; limb_names.append(b.name)
        if animal=='monkey':
            for side in [-1,1]:
                b=armdata.edit_bones.new('arm_'+str(side)); b.head=(side*width*.6,0,height*.66); b.tail=(side*width*.8,0,height*.32); b.parent=root
    bpy.ops.object.mode_set(mode='OBJECT')
    for obj in meshes:
        groups={b.name:obj.vertex_groups.new(name=b.name) for b in armdata.bones}
        for v in obj.data.vertices:
            p=v.co; bone='body'; weight=1
            if animal=='monkey' and abs(p.x)>width*.52 and height*.20<p.z<height*.72:
                bone='arm_'+str(1 if p.x>0 else -1)
            elif animal=='owl' and abs(p.x)>width*.38 and p.z>height*.28:
                bone='wing_'+str(1 if p.x>0 else -1)
            elif animal!='owl' and p.z<height*.46 and abs(p.x)>width*.18:
                bone='leg_%s_%s'%(1 if p.x>0 else -1,1 if p.y>0 else -1)
                weight=min(1,max(.05,(height*.48-p.z)/(height*.25)))
            elif p.y<-depth*.4 and p.z>height*.45: bone='head'
            groups[bone].add([v.index],weight,'REPLACE')
            if weight<1: groups['body'].add([v.index],1-weight,'REPLACE')
        mod=obj.modifiers.new('Animal deformation','ARMATURE'); mod.object=arm; obj.parent=arm
    arm.animation_data_create()
    for clip in ['idle','run','ability','celebrate']:
        action=bpy.data.actions.new(clip); arm.animation_data.action=action
        for frame in range(1,26):
            phase=2*math.pi*(frame-1)/24
            for pb in arm.pose.bones:
                pb.rotation_mode='XYZ'; pb.rotation_euler=(0,0,0); pb.location=(0,0,0)
                if pb.name.startswith('leg_'):
                    s=1 if pb.name in ['leg_-1_-1','leg_1_1'] else -1
                    pb.rotation_euler.x=math.sin(phase)*s*(.48 if clip in ['run','ability'] else .06)
                elif pb.name.startswith('wing_'):
                    pb.rotation_euler.y=math.sin(phase)*(1 if pb.name.endswith('1') and not pb.name.endswith('-1') else -1)*(.85 if clip in ['run','ability'] else .12)
                elif pb.name.startswith('arm_'):
                    side=-1 if pb.name.endswith('-1') else 1
                    pb.rotation_euler.x=(1.1+math.sin(phase)*side*.45) if clip=='ability' else math.sin(phase)*side*.25
                elif pb.name=='head': pb.rotation_euler.x=math.sin(phase)*(.35 if clip=='ability' else .08)
                elif pb.name=='body':
                    pb.location.z=abs(math.sin(phase))*(.1 if clip=='run' else .2 if clip=='celebrate' else .025)
                    if clip=='celebrate': pb.rotation_euler.z=math.sin(phase)*.12
                pb.keyframe_insert('rotation_euler',frame=frame); pb.keyframe_insert('location',frame=frame)
        track=arm.animation_data.nla_tracks.new(); track.name=clip; track.strips.new(clip,1,action)
        arm.animation_data.action=None; track.mute=True
    for track in arm.animation_data.nla_tracks: track.mute=False
    scene.frame_start=1; scene.frame_end=25; scene.render.fps=24; scene.frame_set(1)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes+[arm]: obj.select_set(True)
    bpy.context.view_layer.objects.active=arm
    blend_out=ROOT/'tools/prepared_animals'; blend_out.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_out/(animal+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(animal+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_materials='EXPORT')
    # Transparent, three-quarter portraits rendered from the actual game assets.
    camera_data=bpy.data.cameras.new('Portrait'); camera=bpy.data.objects.new('Portrait',camera_data); scene.collection.objects.link(camera)
    camera.location=(size*1.3,-size*1.5,size*.95); target=Vector((0,0,height*.48))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler(); camera_data.type='ORTHO'; camera_data.ortho_scale=size*1.05; scene.camera=camera
    world=bpy.data.worlds.new('Portrait world'); world.use_nodes=True; world.node_tree.nodes['Background'].inputs[0].default_value=(.7,.85,1,1); world.node_tree.nodes['Background'].inputs[1].default_value=.8; scene.world=world
    for location,energy in [((3,-4,6),650),((-3,-1,3),350)]:
        ld=bpy.data.lights.new('Softbox','AREA'); light=bpy.data.objects.new('Softbox',ld); scene.collection.objects.link(light); light.location=location; ld.energy=energy; ld.size=5; light.rotation_euler=(target-light.location).to_track_quat('-Z','Y').to_euler()
    scene.render.engine='CYCLES'; scene.cycles.samples=24; scene.render.resolution_x=256; scene.render.resolution_y=256; scene.render.resolution_percentage=100; scene.render.film_transparent=True
    scene.view_settings.view_transform='Standard'; scene.view_settings.look='None'; scene.view_settings.exposure=-0.7
    scene.render.image_settings.file_format='PNG'; scene.render.filepath=str(OUT/(animal+'.png')); bpy.ops.render.render(write_still=True)
    report.append({'animal':animal,'source':str(source.relative_to(ROOT)),'bones':len(armdata.bones),'clips':['idle','run','ability','celebrate'],'vertices':sum(len(o.data.vertices) for o in meshes)})
(OUT/'audit.json').write_text(json.dumps(report,indent=2))
