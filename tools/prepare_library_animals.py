"""Extract selected animals without changing the supplied library or desktop scene."""
import bpy, math, pathlib, json
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1]
SOURCE=ROOT/'EverythingLibrary_Animals_002.blend'
OUT=ROOT/'game/assets/animals'
PREPARED=ROOT/'tools/prepared_library_animals'
PREPARED.mkdir(exist_ok=True)
ROSTER={'rhino':('Rhino',2.7),'owl':('SnowyOwl',2.5),'frog':('GreenFrog',1.6),'otter':('Otter',2.3),'elephant':('Elephant',3.3),'turtle':('Tortoise',2.0),'monkey':('Chimpanzee',2.3)}
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
deps=bpy.context.evaluated_depsgraph_get()
sources={}
for key,(name,size) in ROSTER.items():
    root=bpy.data.objects[name]
    sources[key]=[(o.name,bpy.data.meshes.new_from_object(o.evaluated_get(deps),depsgraph=deps),o.matrix_world.copy()) for o in [root]+list(root.children_recursive) if o.type=='MESH']
report=[]
for animal,(name,size) in ROSTER.items():
    scene=bpy.data.scenes.new('AnimalSwitchLibrary_'+animal)
    bpy.context.window.scene=scene
    meshes=[]
    for object_name,data,matrix in sources[animal]:
        obj=bpy.data.objects.new(animal+'_'+object_name,data.copy()); scene.collection.objects.link(obj)
        for v in obj.data.vertices: v.co=matrix@v.co
        meshes.append(obj)
    points=[v.co for o in meshes for v in o.data.vertices]
    lo=Vector(tuple(min(v[i] for v in points) for i in range(3)))
    hi=Vector(tuple(max(v[i] for v in points) for i in range(3)))
    center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    factor=size/max(hi-lo)
    for o in meshes:
        for v in o.data.vertices: v.co=(v.co-center)*factor
        # The pack is painted with corner vertex colors. Keep that artwork intact.
        if 'colorSet1' in o.data.color_attributes:
            o.data.color_attributes.active_color=o.data.color_attributes['colorSet1']
            o.data.color_attributes.render_color_index=list(o.data.color_attributes).index(o.data.color_attributes['colorSet1'])
        mat=bpy.data.materials.new(animal+'_library_colors'); mat.use_nodes=True
        bsdf=mat.node_tree.nodes.get('Principled BSDF'); bsdf.inputs['Roughness'].default_value=.8
        color=mat.node_tree.nodes.new('ShaderNodeVertexColor'); color.layer_name='colorSet1'
        mat.node_tree.links.new(color.outputs['Color'],bsdf.inputs['Base Color'])
        o.data.materials.clear(); o.data.materials.append(mat)
        for polygon in o.data.polygons: polygon.material_index=0
        # Bake vertex paint to an sRGB albedo map: Godot Compatibility otherwise
        # interprets glTF linear vertex colors as sRGB and makes the coats too dark.
        bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active=o
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(island_margin=.025); bpy.ops.object.mode_set(mode='OBJECT')
        image=bpy.data.images.new(animal+'_albedo',width=256,height=256,alpha=False)
        texture=mat.node_tree.nodes.new('ShaderNodeTexImage'); texture.image=image; mat.node_tree.nodes.active=texture
        scene.render.engine='CYCLES'; scene.cycles.samples=1
        scene.render.bake.use_pass_direct=False; scene.render.bake.use_pass_indirect=False; scene.render.bake.use_pass_color=True
        scene.render.bake.margin=4
        bpy.ops.object.bake(type='DIFFUSE')
        image.filepath_raw=str(PREPARED/(animal+'_albedo.png')); image.file_format='PNG'; image.save()
        mat.node_tree.links.new(texture.outputs['Color'],bsdf.inputs['Base Color'])
        mat.node_tree.nodes.remove(color)
    points=[v.co for o in meshes for v in o.data.vertices]
    width=max(abs(v.x) for v in points); depth=max(abs(v.y) for v in points); height=max(v.z for v in points)
    armdata=bpy.data.armatures.new(animal+'_skeleton'); arm=bpy.data.objects.new(animal+'_rig',armdata)
    scene.collection.objects.link(arm); bpy.context.view_layer.objects.active=arm; arm.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    def bone(name,head,tail,parent='body'):
        b=armdata.edit_bones.new(name); b.head=head; b.tail=tail
        if parent: b.parent=armdata.edit_bones[parent]
        return b
    bone('body',(0,0,height*.45),(0,0,height*.72),None)
    bone('neck',(0,-depth*.26,height*.60),(0,-depth*.46,height*.70))
    bone('head',(0,-depth*.46,height*.70),(0,-depth*.70,height*.78),'neck')
    if animal=='owl':
        for side in [-1,1]:
            bone('wing_'+str(side),(side*width*.18,0,height*.55),(side*width*.58,0,height*.55))
            bone('wingtip_'+str(side),(side*width*.58,0,height*.55),(side*width,.02,height*.50),'wing_'+str(side))
    else:
        for side in [-1,1]:
            for end in [-1,1]:
                label='fore' if end==-1 else 'hind'
                x=side*width*(.65 if animal not in ['turtle','frog'] else .78)
                y=end*depth*(.34 if end==-1 else .46)
                hip=height*(.68 if animal=='monkey' and end==-1 else .42)
                bone(label+'_'+str(side),(x,y,hip),(x,y,height*.21))
                bone(label+'_lower_'+str(side),(x,y,height*.21),(x,y,.055),label+'_'+str(side))
                bone(label+'_foot_'+str(side),(x,y,.055),(x,y-depth*.12,.055),label+'_lower_'+str(side))
        if animal in ['rhino','otter','elephant']:
            bone('tail',(0,depth*.50,height*.40),(0,depth*.90,height*.25))
        if animal=='elephant':
            bone('trunk',(0,-depth*.62,height*.59),(0,-depth*.85,height*.30),'head')
            bone('trunk_tip',(0,-depth*.85,height*.30),(0,-depth*.99,height*.12),'trunk')
    bpy.ops.object.mode_set(mode='OBJECT')
    for obj in meshes:
        groups={b.name:obj.vertex_groups.new(name=b.name) for b in armdata.bones}
        for v in obj.data.vertices:
            p=v.co; weights={'body':1.0}
            side=1 if p.x>0 else -1
            if animal=='otter' and p.y>depth*.40 and abs(p.x)<width*.65:
                blend=min(1,max(0,(p.y/depth-.40)/.18))
                weights={'body':1-blend,'tail':blend}
            elif animal=='owl' and abs(p.x)>width*.18:
                blend=min(1,max(0,(abs(p.x)/width-.18)/.20))
                tip=min(1,max(0,(abs(p.x)/width-.50)/.24))
                weights={'body':1-blend,'wing_'+str(side):blend*(1-tip),'wingtip_'+str(side):blend*tip}
            elif animal!='owl' and p.z<height*(.64 if animal=='monkey' else .46) and abs(p.x)>width*.18:
                limb='fore' if p.y<0 else 'hind'
                mix=min(1,max(0,(.48-p.z/height)/.20))
                if animal=='monkey' and p.y<0: mix=min(1,max(0,(.73-p.z/height)/.22))
                lower=min(1,max(0,(.28-p.z/height)/.14))
                foot=min(1,max(0,(.09-p.z/height)/.05))
                weights={'body':1-mix,limb+'_'+str(side):mix*(1-lower),limb+'_lower_'+str(side):mix*lower*(1-foot),limb+'_foot_'+str(side):mix*lower*foot}
            elif animal=='elephant' and p.y<-depth*.65 and abs(p.x)<width*.25:
                tip=min(1,max(0,(.32-p.z/height)/.20))
                weights={'trunk':1-tip,'trunk_tip':tip}
            elif 'tail' in groups and p.y>depth*.66 and abs(p.x)<width*.32:
                weights={'tail':1.0}
            elif p.y<-depth*.35 and p.z>height*.40:
                blend=min(1,max(0,(-p.y/depth-.35)/.24))
                weights={'body':1-blend,'head':blend}
            for key,weight in weights.items():
                if weight>0: groups[key].add([v.index],weight,'REPLACE')
        mod=obj.modifiers.new('Articulated animal','ARMATURE'); mod.object=arm; obj.parent=arm
    arm.animation_data_create()
    periods={'rhino':.82,'owl':.72,'frog':.72,'otter':.68,'elephant':1.20,'turtle':1.45,'monkey':.78}
    frames=max(18,round(periods[animal]*30))
    for clip in ['idle','run','ability','celebrate']:
        action=bpy.data.actions.new(clip); arm.animation_data.action=action
        for frame in range(1,frames+2):
            phase=2*math.pi*(frame-1)/frames
            active=clip in ['run','ability']; ability=clip=='ability'
            for pb in arm.pose.bones:
                pb.rotation_mode='XYZ'; pb.rotation_euler=(0,0,0); pb.location=(0,0,0)
                if pb.name=='body':
                    if animal=='frog' and active:
                        # Hind legs propel a short hop, followed by a crouched landing.
                        # Root flight is handled by the game. Local bone Y is up.
                        cycle=(frame-1)/frames
                        crouch=max(0,1-abs(cycle-.10)/.10)+max(0,1-abs(cycle-.90)/.10)
                        pb.location.y=-crouch*height*.10
                        pb.rotation_euler.x=math.sin(phase)*.06
                    elif animal=='otter' and ability:
                        pb.rotation_euler.y=math.sin(phase)*.045
                    elif animal!='owl':
                        pb.location.y=(1-math.cos(phase*2))*height*(.005 if active else .002)
                        pb.rotation_euler.y=math.sin(phase)*(.012 if animal in ['elephant','turtle'] else .025)
                    if animal=='monkey' and ability: pb.rotation_euler.x=-.15
                    if clip=='celebrate': pb.rotation_euler.z=math.sin(phase)*.045
                elif pb.name.startswith('wing'):
                    sign=1 if pb.name.endswith('_1') else -1
                    tip=pb.name.startswith('wingtip')
                    amplitude=(.10 if tip else .14) if ability else (.25 if tip else .45)
                    pb.rotation_euler.y=sign*(math.sin(phase+(.35 if tip else 0))*amplitude if active else .02*math.sin(phase))
                elif pb.name.startswith(('fore_','hind_')):
                    fore=pb.name.startswith('fore_'); sign=1 if pb.name.endswith('_1') else -1
                    # A diagonal trot for quadrupeds; a slower staggered walk for elephant/tortoise.
                    gait_phase=phase+(0 if (fore and sign==1) or (not fore and sign==-1) else math.pi)
                    if animal in ['elephant','turtle']: gait_phase=phase+(0 if fore else math.pi/2)+(0 if sign==1 else math.pi)
                    if animal=='frog': gait_phase=phase+(0 if not fore else .50)
                    stride=math.sin(gait_phase)
                    amplitude={'rhino':.24,'frog':.22,'otter':.23,'elephant':.20,'turtle':.16,'monkey':.34}[animal] if active else .008
                    if animal=='frog' and fore: amplitude*=.38
                    if animal=='turtle' and ability: amplitude=.10
                    if animal=='monkey' and ability and fore: amplitude=.52
                    if animal=='otter' and ability: amplitude=.27
                    if '_lower_' in pb.name:
                        pb.rotation_euler.x=max(0,stride)*amplitude*.65
                    elif '_foot_' in pb.name:
                        pb.rotation_euler.x=-stride*amplitude*.18
                    else:
                        pb.rotation_euler.x=stride*amplitude
                        if animal=='monkey' and ability and fore: pb.rotation_euler.x-=.8
                    if animal=='frog' and active:
                        # Synchronous extension followed by recovery, not a walking cycle.
                        cycle=(frame-1)/frames
                        extension=math.sin(math.pi*min(1,max(0,(cycle-.14)/.50)))
                        fold=max(0,1-abs(cycle-.89)/.16)
                        if '_lower_' in pb.name:
                            pb.rotation_euler.x=(-.42*extension+.24*fold) if not fore else .12*fold
                        elif '_foot_' in pb.name:
                            pb.rotation_euler.x=.22*extension if not fore else -.08*fold
                        else:
                            pb.rotation_euler.x=(.40*extension-.18*fold) if not fore else -.12*extension+.12*fold
                elif pb.name=='head':
                    pb.rotation_euler.x=math.sin(phase)*(.025 if active else .012)
                    if animal=='rhino' and ability: pb.rotation_euler.x=.18+math.sin(phase)*.025
                    if animal=='turtle' and ability: pb.location.y=-depth*.06
                elif pb.name=='tail': pb.rotation_euler.z=math.sin(phase)*.08
                elif pb.name.startswith('trunk'): pb.rotation_euler.x=math.sin(phase)*(.08 if ability else .045)
                pb.keyframe_insert('rotation_euler',frame=frame); pb.keyframe_insert('location',frame=frame)
        track=arm.animation_data.nla_tracks.new(); track.name=clip; track.strips.new(clip,1,action); arm.animation_data.action=None; track.mute=True
    for track in arm.animation_data.nla_tracks: track.mute=False
    scene.render.fps=30; scene.frame_start=1; scene.frame_end=frames+1; scene.frame_set(1)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes+[arm]: obj.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.wm.save_as_mainfile(filepath=str(PREPARED/(animal+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(animal+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_materials='EXPORT',export_vertex_color='NONE')
    # Portrait uses a neutral rest pose; NLA clips must not all blend together.
    for track in arm.animation_data.nla_tracks: track.mute=True
    for pb in arm.pose.bones: pb.rotation_euler=(0,0,0); pb.location=(0,0,0)
    camera_data=bpy.data.cameras.new('Portrait'); camera=bpy.data.objects.new('Portrait',camera_data); scene.collection.objects.link(camera)
    target=Vector((0,0,height*.48)); camera.location=(size*.95,-size*1.5,size*.9)
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler(); camera_data.type='ORTHO'; camera_data.ortho_scale=size*1.15; scene.camera=camera
    world=bpy.data.worlds.new('Portrait world'); world.use_nodes=True; world.node_tree.nodes['Background'].inputs[0].default_value=(.7,.85,1,1); world.node_tree.nodes['Background'].inputs[1].default_value=.8; scene.world=world
    for location,energy in [((3,-4,6),650),((-3,-1,3),350)]:
        ld=bpy.data.lights.new('Softbox','AREA'); light=bpy.data.objects.new('Softbox',ld); scene.collection.objects.link(light); light.location=location; ld.energy=energy; ld.size=5; light.rotation_euler=(target-light.location).to_track_quat('-Z','Y').to_euler()
    scene.render.engine='CYCLES'; scene.cycles.samples=12; scene.render.resolution_x=256; scene.render.resolution_y=256; scene.render.resolution_percentage=100; scene.render.film_transparent=True
    scene.view_settings.view_transform='Standard'; scene.view_settings.look='None'; scene.view_settings.exposure=-.45
    scene.render.image_settings.file_format='PNG'; scene.render.filepath=str(OUT/(animal+'.png')); bpy.ops.render.render(write_still=True)
    report.append({'animal':animal,'library_animal':name,'source':SOURCE.name,'bones':len(armdata.bones),'clips':['idle','run','ability','celebrate'],'cycle_seconds':frames/30,'vertices':sum(len(o.data.vertices) for o in meshes),'colors':'original colorSet1 baked to sRGB albedo'})
    print('LIBRARY_ANIMAL_READY',animal,flush=True)
(OUT/'audit.json').write_text(json.dumps(report,indent=2))
print('LIBRARY_PREPARATION_COMPLETE',flush=True)
