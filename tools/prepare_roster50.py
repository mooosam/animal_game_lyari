"""Prepare the approved library in a background Blender scene. Source is read-only."""
import bpy, math, pathlib, json, sys, statistics, argparse
from mathutils import Vector
sys.path.insert(0,str(pathlib.Path(__file__).parent))
from roster50 import ROWS, PERIOD, clips_for
from coat_patterns import patterned_coat
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'game/assets/animals'; PREP=ROOT/'tools/prepared_roster50'
PREP.mkdir(exist_ok=True); OUT.mkdir(exist_ok=True)
parser=argparse.ArgumentParser(); parser.add_argument('--only',default='')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
selected=[r for r in ROWS if not args.only or r[0] in args.only.split(',')]

# Species-specific gait assignments. Shared mechanics are reused only where
# animals really share a locomotor pattern; cadence and body mechanics are
# tuned independently in SPECIES_MOTION below.
GAIT = {
    'rhino':'heavy_walk','owl':'flight','frog':'frog','otter':'otter',
    'elephant':'elephant','turtle':'tortoise','monkey':'knuckle','lion':'feline',
    'tiger':'feline','cheetah':'cheetah','snow_leopard':'feline','mountain_lion':'feline',
    'gray_wolf':'canine','red_fox':'fox','arctic_fox':'fox','brown_bear':'bear',
    'polar_bear':'bear','black_bear':'bear','panda':'bear','red_panda':'climber',
    'gorilla':'knuckle','orangutan':'climber','mandrill':'knuckle','sloth':'sloth',
    'koala':'climber','giraffe':'giraffe','zebra':'ungulate','hippo':'heavy_walk',
    'bison':'ungulate','camel':'pace','llama':'pace','goat':'ungulate','ibex':'ungulate',
    'bighorn_sheep':'ungulate','moose':'ungulate','deer':'ungulate','boar':'heavy_walk',
    'armadillo':'tortoise','anteater':'anteater','hedgehog':'tortoise','rabbit':'bound',
    'red_squirrel':'bound','raccoon':'climber','crocodile':'reptile','komodo_dragon':'reptile',
    'chameleon':'reptile','eagle':'flight','penguin':'penguin','harbour_seal':'seal','walrus':'walrus',
}
assert set(GAIT)=={r[0] for r in ROWS}, 'Every roster animal must have an explicit gait assignment'

SPECIES_MOTION = {
    # cadence, stride range, body bounce, spine/flex range
    'rhino':(0.82,0.78,0.035,0.08), 'owl':(1.00,1.00,0.05,0.15),
    'frog':(1.15,1.15,0.06,0.22), 'otter':(1.05,1.00,0.08,0.30),
    'elephant':(0.68,0.68,0.025,0.06), 'turtle':(0.60,0.75,0.025,0.05),
    'monkey':(1.00,1.00,0.055,0.18), 'lion':(1.00,1.00,0.09,0.18),
    'tiger':(1.04,1.05,0.10,0.20), 'cheetah':(1.45,1.25,0.06,0.50),
    'snow_leopard':(1.00,1.00,0.08,0.24), 'mountain_lion':(1.02,1.05,0.09,0.20),
    'gray_wolf':(1.00,1.00,0.06,0.18), 'red_fox':(1.15,1.15,0.12,0.20),
    'arctic_fox':(1.10,1.10,0.12,0.18), 'brown_bear':(0.80,0.82,0.035,0.10),
    'polar_bear':(0.80,0.82,0.035,0.10), 'black_bear':(0.82,0.85,0.04,0.11),
    'panda':(0.72,0.75,0.03,0.07), 'red_panda':(0.95,0.95,0.055,0.22),
    'gorilla':(0.85,0.88,0.04,0.11), 'orangutan':(0.82,0.82,0.035,0.18),
    'mandrill':(0.95,0.98,0.055,0.16), 'sloth':(0.48,0.55,0.018,0.12),
    'koala':(0.75,0.78,0.025,0.13), 'giraffe':(0.70,0.78,0.04,0.12),
    'zebra':(1.05,1.08,0.11,0.16), 'hippo':(0.58,0.72,0.025,0.07),
    'bison':(0.78,0.82,0.03,0.09), 'camel':(0.78,0.82,0.04,0.11),
    'llama':(0.90,0.92,0.075,0.16), 'goat':(1.00,1.02,0.10,0.18),
    'ibex':(1.02,1.05,0.10,0.18), 'bighorn_sheep':(0.94,0.98,0.095,0.15),
    'moose':(0.75,0.82,0.04,0.09), 'deer':(1.08,1.10,0.12,0.16),
    'boar':(0.86,0.90,0.035,0.09), 'armadillo':(0.68,0.82,0.025,0.07),
    'anteater':(0.72,0.78,0.03,0.12), 'hedgehog':(0.62,0.82,0.025,0.07),
    'rabbit':(1.12,1.18,0.12,0.15), 'red_squirrel':(1.20,1.20,0.14,0.26),
    'raccoon':(0.94,0.98,0.055,0.24), 'crocodile':(0.66,0.82,0.035,0.34),
    'komodo_dragon':(0.78,0.92,0.04,0.29), 'chameleon':(0.48,0.62,0.02,0.24),
    'eagle':(1.10,1.05,0.06,0.18), 'penguin':(0.80,0.82,0.04,0.08),
    'harbour_seal':(0.78,0.88,0.05,0.32), 'walrus':(0.66,0.78,0.025,0.24),
}
assert set(SPECIES_MOTION)=={r[0] for r in ROWS}, 'Every roster animal must have an individual motion profile'

def smooth01(x):
    x=max(0.0,min(1.0,x)); return x*x*(3.0-2.0*x)

def footfall_phase(gait, fore, side):
    left=side==1
    if gait in ['bound','frog']:
        return 0.0 if fore else .48
    if gait in ['pace','camelid']:
        return 0.0 if left else .5
    if gait in ['cheetah','feline','fox']:
        # Rotary gallop / bounding: near-side contacts are slightly staggered,
        # followed by the opposite pair, with a clear suspension interval.
        return (0.0 if left else .10) if fore else (.36 if left else .27)
    if gait in ['trot','ungulate_trot']:
        return (0.0 if left else .5) if fore else (.5 if left else 0.0)
    if gait in ['knuckle','primate']:
        # RH, LF, LH, RF: diagonal-sequence walking used by nonhuman primates.
        if fore: return .25 if not left else .75
        return 0.0 if left else .5
    if gait in ['flight']:
        return 0.0 if fore else .5
    if gait in ['reptile']:
        # Sprawled lateral-sequence walking with counter-phase trunk bends.
        return (0.0 if left else .5) if not fore else (.24 if left else .74)
    # Lateral-sequence walk: hind foot, ipsilateral forefoot, then far side.
    return (0.0 if left else .5) if not fore else (.24 if left else .74)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'EverythingLibrary_Animals_002.blend'))
source_scene=bpy.context.scene
deps=bpy.context.evaluated_depsgraph_get()
sources={}
# Some library entries intentionally contain two display variants in one
# collection. BrownBear and BlackBear include a standing biped and a lower,
# long-backed quadruped; combining both produces the exact fused silhouette
# seen in the viewer. Keep the quadruped for locomotion exports.
QUADRUPED_VARIANTS={'brown_bear','black_bear'}
for row in selected:
    root=bpy.data.objects[row[2]]
    mesh_objects=[o for o in [root]+list(root.children_recursive) if o.type=='MESH']
    if row[0] in QUADRUPED_VARIANTS and len(mesh_objects)>1:
        def world_height(o):
            pts=[o.matrix_world @ v.co for v in o.data.vertices]
            return max(p.z for p in pts)-min(p.z for p in pts)
        mesh_objects=[min(mesh_objects,key=world_height)]
    sources[row[0]]=[(o.name,bpy.data.meshes.new_from_object(o.evaluated_get(deps),depsgraph=deps),o.matrix_world.copy()) for o in mesh_objects]

def rig_and_animate(scene,meshes,row,height,width,front,rear,body_z):
    key,title,source,family,ability,size=row
    data=bpy.data.armatures.new(key+'_skeleton'); arm=bpy.data.objects.new(key+'_rig',data)
    scene.collection.objects.link(arm)
    bpy.ops.object.select_all(action='DESELECT'); arm.select_set(True); bpy.context.view_layer.objects.active=arm
    bpy.ops.object.mode_set(mode='EDIT')
    def bone(name,head,tail,parent='body'):
        b=data.edit_bones.new(name); b.head=head; b.tail=tail
        direction=b.tail-b.head
        if direction.length<.01:
            # Extend a short bone along its existing anatomical direction;
            # adding world-up here used to reverse tiny reptile/shallow-body
            # lower legs and made their front elbows hinge the wrong way.
            if direction.length>1e-6: direction.normalize()
            else: direction=Vector((0,0,1))
            b.tail=b.head+direction*.01
        if parent: b.parent=data.edit_bones[parent]
    bone('body',(0,0,body_z),(0,0,body_z+.22),None)
    bone('spine_mid',(0,0,body_z),(0,-front*.08,body_z+.10),'body')
    bone('hips',(0,rear*.12,body_z),(0,rear*.30,body_z),'body')
    bone('chest',(0,-front*.12,body_z),(0,-front*.32,body_z),'spine_mid')
    neck_top=height*.85 if family=='giraffe' else min(height*.83,body_z+height*.14)
    bone('neck',(0,-front*.30,body_z),(0,-front*.45,(neck_top+body_z)/2),'chest')
    bone('neck_tip',(0,-front*.45,(neck_top+body_z)/2),(0,-front*.60,neck_top),'neck')
    bone('head',(0,-front*.60,neck_top),(0,-front*.83,neck_top+.07),'neck_tip')
    limb_points={}
    for side in [-1,1]:
        for label in ['fore','hind']:
            pts=[v.co for o in meshes for v in o.data.vertices if (v.co.x*side>width*.12 and v.co.z<body_z*.62 and ((v.co.y<0)==(label=='fore')))]
            x=statistics.median([p.x for p in pts]) if pts else side*width*.55
            y=statistics.median([p.y for p in pts]) if pts else (-front*.35 if label=='fore' else rear*.30)
            if family in ['bird','penguin'] and label=='fore': continue
            hip=max(body_z*(1.1 if family=='ape' and label=='fore' else .94),.10)
            knee=max(hip*.48,.065)
            limb_points[(label,side)]=(x,y)
            parent='chest' if label=='fore' else 'hips'
            bone(f'{label}_{side}',(x,y,hip),(x,y,knee),parent)
            bone(f'{label}_lower_{side}',(x,y,knee),(x,y,.04),f'{label}_{side}')
            bone(f'{label}_foot_{side}',(x,y,.04),(x,y-.13,.02),f'{label}_lower_{side}')
    if family in ['bird','penguin']:
        for side in [-1,1]:
            bone(f'wing_{side}',(side*width*.18,0,height*.60),(side*width*.57,0,height*.58),'chest')
            bone(f'wingtip_{side}',(side*width*.57,0,height*.58),(side*width,0,height*.52),f'wing_{side}')
    # Multi-segment tails support waves, balance and delayed secondary motion.
    if family not in ['ape','primate','sloth','elephant','penguin']:
        for i in range(4):
            bone(f'tail_{i}',(0,rear*(.30+i*.16),body_z*(.72-i*.12)),(0,rear*(.46+i*.16),body_z*(.60-i*.12)),'hips' if i==0 else f'tail_{i-1}')
    if key=='elephant':
        for i in range(3):
            bone(f'trunk_{i}',(0,-front*(.65+i*.1),height*(.65-i*.18)),(0,-front*(.75+i*.1),height*(.47-i*.18)),'head' if i==0 else f'trunk_{i-1}')
    bpy.ops.object.mode_set(mode='OBJECT')
    for obj in meshes:
        groups={b.name:obj.vertex_groups.new(name=b.name) for b in data.bones}
        for v in obj.data.vertices:
            p=v.co; side=1 if p.x>=0 else -1; w={'body':1.0}
            if family in ['bird','penguin'] and abs(p.x)>width*.26 and p.z>height*.30:
                t=min(1,max(0,(abs(p.x)/width-.26)/.25)); tip=min(1,max(0,(abs(p.x)/width-.57)/.25))
                w={'chest':1-t,f'wing_{side}':t*(1-tip),f'wingtip_{side}':t*tip}
            elif key=='elephant' and p.y<-front*.68 and abs(p.x)<width*.24 and p.z<height*.65:
                i=min(2,max(0,int((.65-p.z/height)/.18))); w={f'trunk_{i}':1.0}
            elif 'tail_0' in groups and p.y>rear*.32 and abs(p.x)<width*.40 and p.z<body_z*.95:
                t=min(3,max(0,(p.y/rear-.30)/.16)); i=min(2,int(t)); frac=t-i
                w={f'tail_{i}':1-frac,f'tail_{i+1}':frac}
            # Only vertices close to a limb root receive limb weights. The old
            # broad side test pulled chunks of the torso onto the leg bones,
            # making the upper body look wooden and the legs look melted.
            elif p.z<body_z*.58 and abs(p.x)>width*.30:
                label='fore' if p.y<0 else 'hind'
                if (label,side) not in limb_points: label='hind'
                t=min(1,max(0,(.94-p.z/body_z)/.35)); lower=min(1,max(0,(.53-p.z/body_z)/.25)); foot=min(1,max(0,(.12-p.z/body_z)/.08))
                w={'body':1-t,f'{label}_{side}':t*(1-lower),f'{label}_lower_{side}':t*lower*(1-foot),f'{label}_foot_{side}':t*lower*foot}
            elif family=='giraffe' and p.z>body_z*1.1:
                t=min(1,(p.z-body_z)/(height-body_z)); w={'neck':max(0,1-t*2),'neck_tip':max(0,1-abs(t-.5)*2),'head':max(0,t*2-1)}
            elif p.y<-front*.48 and p.z>body_z*.65:
                t=min(1,max(0,(-p.y/front-.48)/.25)); w={'neck_tip':1-t,'head':t}
            else:
                t=min(.75,abs(p.y)/(front if p.y<0 else rear)); w={'body':.30,'spine_mid':.35,'chest' if p.y<0 else 'hips':.35*t}
            total=sum(w.values())
            for name,weight in w.items():
                if weight>0: groups[name].add([v.index],weight/total,'REPLACE')
        mod=obj.modifiers.new('Species articulation','ARMATURE'); mod.object=arm; obj.parent=arm
    arm.animation_data_create()
    clips=clips_for(row)
    gait=GAIT[key]
    cadence,stride_scale,bounce_scale,spine_scale=SPECIES_MOTION[key]
    for clip in clips:
        duration=PERIOD[family]
        duration/=cadence
        if gait in ['sloth','tortoise','heavy_walk','elephant','walrus']: duration*=1.12
        if clip in ['idle','interact','eat','sleep','perch']: duration*=2
        if clip in ['walk','slow_walk','stalk','climb','pace','knuckle_walk','land_undulate']: duration*=1.5
        if clip in ['sprint','fast_walk','fast_waddle','fast_swim','charge']: duration*=.75
        if clip in ['stop','land','hit_reaction','retract','emerge','takeoff']: duration=.65
        if clip=='ability': duration=.90
        if key=='frog' and clip in ['ability','hop','long_jump','jump']: duration=1.0
        frames=max(18,round(duration*30)); action=bpy.data.actions.new(clip); arm.animation_data.action=action
        for f in range(frames+1):
            cycle=f/frames; phase=cycle*math.tau; wave=math.sin(phase)
            mode=ability if clip=='ability' else clip
            swimming=mode in ['swim','fast_swim','dive','surface','frog_kick']
            climbing=mode in ['climb','descend','reach','branch_transfer','hang','grab']
            idle=mode in ['idle','perch','sleep']; turn=mode in ['turn_left','turn_right','bank_left','bank_right']
            heavy=gait in ['heavy_walk','elephant','tortoise','walrus']
            pace=gait in ['pace','camelid'] or mode=='pace'
            walking=mode in ['walk','slow_walk','knuckle_walk','graze','stalk','high_walk','low_walk','land_undulate','waddle','trot','pace']
            running=mode in ['run','sprint','charge','bound','gallop','fast_walk','fast_waddle']
            jumping=mode in ['jump','leap','hop','long_jump','bound']
            smashing=mode in ['smash','head_butt','charge']
            shielding=mode in ['shield','defend','curl','retract']
            digging=mode in ['dig','forage','feed']
            locomoting=(walking or running or climbing or swimming or mode in ['hop','long_jump','jump','leap','bound','fly','glide']) and not idle
            if mode in ['walk','slow_walk','knuckle_walk','stalk','waddle']:
                active_gait='knuckle' if gait=='knuckle' else 'tortoise' if gait=='tortoise' else 'reptile' if gait=='reptile' else 'pace' if gait in ['pace','camelid'] else 'walk'
            elif running:
                active_gait='bound' if gait=='bound' else 'feline' if gait in ['feline','cheetah','fox'] else 'walk' if gait=='elephant' else 'trot' if gait=='ungulate' else gait
            else:
                active_gait=gait
            duty=.55 if running else .67
            amplitude=(.008 if idle else .20 if walking else .35)*stride_scale
            for pb in arm.pose.bones:
                pb.rotation_mode='XYZ'; pb.rotation_euler=(0,0,0); pb.location=(0,0,0)
                name=pb.name
                if name=='body':
                    # Weight follows stance: quadrupeds compress on landing,
                    # propel from the hindquarters and release into brief air.
                    impact=max(0.0, math.sin(phase*2.0 + math.pi*.18))
                    bob=height*(bounce_scale*(.5+.5*math.sin(phase*2.0-math.pi*.5)) if locomoting else .006*wave)
                    pitch=wave*(.025 if heavy else .045)*stride_scale
                    if running and active_gait in ['feline','fox','bound']:
                        flight=smooth01((cycle-.48)/.12)*(1.0-smooth01((cycle-.78)/.14))
                        bob+=height*bounce_scale*.45*flight
                        pitch+=math.sin(phase)*spine_scale*.16
                    pb.location.z=bob-height*impact*(.012 if heavy else .018)*stride_scale
                    pb.rotation_euler.x=pitch
                    pb.rotation_euler.z=math.sin(phase+.4)*(.018 if heavy else .035)*stride_scale
                    if gait=='frog' and locomoting and not swimming:
                        crouch=1.0-smooth01(cycle/.19)
                        launch=smooth01((cycle-.14)/.18)
                        airborne=math.sin(math.pi*max(0.0,min(1.0,(cycle-.25)/.49)))
                        land=smooth01((cycle-.70)/.13)
                        pb.location.z=height*(-.085*crouch+.34*airborne-.055*land)
                        pb.rotation_euler.x=.22*crouch-.24*launch+.05*airborne+.30*land
                        pb.rotation_euler.z=wave*.045
                    elif jumping:
                        crouch=1.0-smooth01(cycle/.18)
                        launch=smooth01((cycle-.14)/.18)
                        airborne=math.sin(math.pi*max(0.0,min(1.0,(cycle-.30)/.50)))
                        land=smooth01((cycle-.71)/.15)
                        pb.rotation_euler.x=.16*crouch-.18*launch+.08*airborne+.24*land
                        pb.rotation_euler.z=wave*.05
                    if smashing:
                        windup=1.0-smooth01(cycle/.24)
                        strike=smooth01((cycle-.28)/.10)*(1.0-smooth01((cycle-.44)/.22))
                        settle=smooth01((cycle-.56)/.25)
                        pb.rotation_euler.x+=-.12*windup+.42*strike+.08*settle
                        pb.location.z-=height*.045*strike
                    if shielding:
                        tuck=math.sin(math.pi*cycle)
                        pb.location.z-=height*.055*tuck
                        pb.rotation_euler.x+=.18*tuck
                    if digging:
                        press=max(0.0,math.sin(phase*2.0))
                        pb.rotation_euler.x+=.10*press
                        pb.location.z-=height*.025*press
                    if gait=='seal' and not swimming and not idle:
                        pb.location.z=height*.045*(1-math.cos(phase)); pb.rotation_euler.x=wave*.10
                    if gait=='penguin' and not swimming: pb.rotation_euler.z=wave*.10
                    if swimming:
                        pb.rotation_euler.x=wave*(.07 if gait in ['seal','walrus','otter','reptile'] else .035)
                        pb.location.z=height*.025*(1-math.cos(phase*2))
                    if mode=='belly_slide': pb.rotation_euler.x=.9
                    if family=='sloth' and mode in ['hang','climb','reach','branch_transfer','idle']: pb.rotation_euler.x=math.pi*.80
                    if mode in ['stand','rear','stand_up']: pb.rotation_euler.x=-math.sin(cycle*math.pi)*.65
                    if mode in ['sit','kneel']: pb.location.z=-height*.12*(1-math.cos(phase))*.5
                    if mode=='hit_reaction': pb.rotation_euler.x=math.sin(cycle*math.pi)*.10
                    if mode=='celebrate': pb.rotation_euler.y=wave*.06
                elif name in ['hips','spine_mid','chest']:
                    sign=1 if name=='chest' else -1 if name=='hips' else .35
                    activity=.18 if running else .11 if walking else .035 if swimming else .018
                    if idle: activity=.008
                    if gait=='cheetah': activity=.62 if running else .16
                    elif gait in ['feline','fox']: activity=.28 if running else .10
                    elif gait in ['reptile','otter','seal','walrus']: activity=.12 if swimming else .07
                    elif gait in ['heavy_walk','elephant','tortoise','bear']: activity=.025 if running else .018
                    flex=wave*activity*spine_scale
                    if name=='spine_mid':
                        pb.rotation_euler.x=flex*sign
                        pb.rotation_euler.z=math.sin(phase-.35)*(.14 if gait=='reptile' else .025 if gait in ['bear','knuckle','climber'] else .012)*stride_scale
                    else:
                        pb.rotation_euler.x=flex*sign
                    if gait=='reptile': pb.rotation_euler.z+=sign*wave*.10*stride_scale
                    if gait=='giraffe' and name=='chest': pb.rotation_euler.x*=.55
                    if family=='armor' and not shielding: pb.rotation_euler=(0,0,0)
                elif name.startswith(('fore_','hind_')):
                    fore=name.startswith('fore_'); side=1 if name.endswith('_1') else -1
                    offset=footfall_phase(active_gait,fore,side)
                    p=(cycle+offset)%1.0
                    if p<duty:
                        progress=p/duty; swing=.48-0.96*progress; knee=0.0; lift=0.0; planted=True
                    else:
                        progress=(p-duty)/(1-duty); swing=-.48+0.96*smooth01(progress); knee=math.sin(math.pi*progress); lift=math.sin(math.pi*progress); planted=False
                    root_value=amplitude*swing
                    # In this top-to-bottom rig, positive local X flexes the
                    # front elbow back toward the animal's tail. The previous
                    # negative sign made every foreleg fold forward at the
                    # knee, against the direction of travel.
                    lower_value=knee*(.48 if running else .32)*stride_scale
                    foot_value=-root_value*.45-lower_value*.35
                    if '_lower_' in name: value=lower_value
                    elif '_foot_' in name:
                        value=foot_value
                        pb.location.z=0.0 if planted else height*.025*lift
                    else: value=root_value
                    if gait=='giraffe' and fore and '_lower_' in name: value*=.65
                    if gait in ['heavy_walk','elephant','tortoise','walrus']:
                        value*=.70
                    if gait=='knuckle' and fore:
                        value*=1.15
                    if gait=='flight' and not fore:
                        value*=.35
                    if gait=='seal' and not swimming:
                        value=wave*.08 if fore and '_lower_' not in name else 0.0
                    if swimming:
                        value=math.sin(phase+(0 if side==1 else math.pi))*(.46 if fore else .34)
                        if gait in ['seal','walrus']: value=wave*.32 if not fore else math.sin(phase+.4)*.16
                        if gait=='reptile': value=.22 if fore else -.22
                    if climbing and fore: value=math.sin(phase+(0 if side==1 else math.pi))*.50-.55
                    if gait=='frog' and locomoting and not swimming:
                        crouch=1.0-smooth01(cycle/.19); launch=smooth01((cycle-.14)/.18)
                        airborne=math.sin(math.pi*max(0.0,min(1.0,(cycle-.25)/.49))); land=smooth01((cycle-.70)/.13)
                        if fore:
                            value=(.18*crouch+.45*airborne+.62*land) if '_lower_' in name else (-.20*crouch+.24*airborne-.32*land)
                        elif '_lower_' in name:
                            value=-.68*crouch+.22*launch+.72*airborne+.55*land
                        elif '_foot_' in name:
                            value=-.24*crouch+.12*airborne-.30*land
                        else:
                            value=-.55*crouch+.82*launch-.18*airborne+.42*land
                        if '_foot_' in name: pb.location.z=height*(.015 if cycle<.18 or cycle>.88 else .045*airborne)
                    elif jumping:
                        crouch=1.0-smooth01(cycle/.18)
                        launch=smooth01((cycle-.14)/.18)
                        airborne=math.sin(math.pi*max(0.0,min(1.0,(cycle-.30)/.50)))
                        land=smooth01((cycle-.71)/.15)
                        if fore:
                            value=(.16*crouch+.52*airborne+.62*land) if '_lower_' in name else (-.18*crouch+.26*airborne-.30*land)
                        elif '_lower_' in name:
                            value=-.42*crouch+.48*launch+.50*airborne+.66*land
                        elif '_foot_' in name:
                            value=-.18*crouch+.10*airborne-.26*land
                        else:
                            value=-.48*crouch+.82*launch-.22*airborne+.38*land
                    if shielding: value=(-.45 if fore else .45)*math.sin(math.pi*cycle)
                    if digging and fore: value=math.sin(phase*2+(0 if side==1 else math.pi))*.58
                    if smashing: value*=.35
                    # Source packs do not share one consistent armature roll.
                    # Convert the desired caudal flex into each bone's local
                    # handedness so GLTF keeps the elbow bending toward the
                    # tail on every species (notably flipped reptile rigs).
                    local_x=pb.bone.matrix_local.to_3x3().col[0]
                    bend_sign=1.0 if local_x.dot(Vector((1,0,0)))>=0 else -1.0
                    pb.rotation_euler.x=value*bend_sign
                    if gait=='reptile': pb.rotation_euler.z=(.10 if fore else -.10)*side*(.25 if idle else 1)
                elif name.startswith('wing'):
                    side=1 if name.endswith('_1') else -1; tip=name.startswith('wingtip')
                    flap=math.sin(phase+(.4 if tip else 0))+.14*math.sin(phase*2)
                    if gait=='penguin': pb.rotation_euler.y=side*(flap*.40 if swimming else .12*wave)
                    else:
                        glide=mode in ['glide','bank_left','bank_right']
                        if mode=='fly': flap=math.sin(phase*1.25+(.3 if tip else 0))+.18*math.sin(phase*2.5)
                        pb.rotation_euler.y=side*flap*(.055 if glide or idle else .60 if not tip else .38)
                        if mode in ['walk','perch']: pb.rotation_euler.y=side*.65
                elif name.startswith('tail_'):
                    i=int(name[-1]); delay=i*.42
                    tail_amp=(.40 if swimming else .20 if locomoting else .055)*spine_scale
                    if gait in ['reptile','otter','seal','walrus']: tail_amp*=1.7
                    pb.rotation_euler.z=math.sin(phase-delay)*tail_amp
                    pb.rotation_euler.x=math.sin(phase-delay-.25)*tail_amp*.25
                    if mode in ['tail_coil','climb'] and key=='chameleon': pb.rotation_euler.x=.35
                    if mode=='tail_whip': pb.rotation_euler.z=math.sin(phase-i*.4)*.35
                elif name.startswith('trunk_'):
                    i=int(name[-1]); pb.rotation_euler.x=math.sin(phase-i*.46)*(.42 if mode in ['trunk_grab','drink','interact','smash'] else .14 if locomoting else .045)
                    pb.rotation_euler.z=math.sin(phase-i*.5)*.08
                elif name.startswith('neck'):
                    neck_motion=.035 if gait in ['giraffe','pace'] else .06 if locomoting else .025
                    pb.rotation_euler.x=math.sin(phase+.2)*neck_motion
                    if gait=='giraffe': pb.rotation_euler.x=-math.sin(phase)*.035
                elif name=='head':
                    pb.rotation_euler.x=wave*(.018 if idle else .035)
                    if gait in ['giraffe','camelid']: pb.rotation_euler.x=-math.sin(phase)*.045
                    if gait in ['bear','heavy_walk','elephant']: pb.rotation_euler.x=-math.sin(phase+.35)*.055
                    if mode in ['smash','charge','head_butt','graze','eat','drink','feed']: pb.rotation_euler.x=.18+wave*.035
                    if mode in ['retract','shield','defend','curl']: pb.location.y=-front*.13*math.sin(math.pi*cycle)
                    if smashing: pb.rotation_euler.x=.10+.58*math.sin(math.pi*min(1.0,max(0.0,(cycle-.24)/.38)))
                    if mode in ['roar','interact','sniff']: pb.rotation_euler.x=math.sin(cycle*math.pi)*.12
                if turn: pb.rotation_euler.z+=math.sin(cycle*math.pi)*(.07 if name=='body' else .035)*(1 if mode.endswith('left') else -1)
                pb.keyframe_insert('rotation_euler',frame=f+1); pb.keyframe_insert('location',frame=f+1)
        # Blender 5.2 stores curves in layered channel bags; newly inserted
        # keys already use the scene's default Bezier interpolation. Keep the
        # export compatible with both Blender 4.x and 5.x here.
        track=arm.animation_data.nla_tracks.new(); track.name=clip; track.strips.new(clip,1,action); arm.animation_data.action=None; track.mute=True
    for t in arm.animation_data.nla_tracks: t.mute=False
    scene.render.fps=30; scene.frame_set(1)
    return arm,clips

manifest=[]
for row in selected:
    key,title,source,family,ability,size=row
    print('PREPARING',key,flush=True)
    scene=bpy.data.scenes.new('AnimalSwitch_'+key); bpy.context.window.scene=scene
    meshes=[]
    for name,data,matrix in sources[key]:
        obj=bpy.data.objects.new(key+'_'+name,data.copy()); scene.collection.objects.link(obj)
        for v in obj.data.vertices: v.co=matrix@v.co
        meshes.append(obj)
    pts=[v.co for o in meshes for v in o.data.vertices]
    lo=Vector(tuple(min(p[i] for p in pts) for i in range(3))); hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    center=Vector(((hi.x+lo.x)/2,(hi.y+lo.y)/2,lo.z)); factor=size/max(hi-lo)
    for o in meshes:
        for v in o.data.vertices: v.co=(v.co-center)*factor
    pts=[v.co for o in meshes for v in o.data.vertices]
    height=max(p.z for p in pts); width=max(abs(p.x) for p in pts)
    torso=[p for p in pts if abs(p.x)>width*.18 and height*.12<p.z<height*.68]
    offset=statistics.median([p.y for p in torso]) if torso else 0
    for o in meshes:
        for v in o.data.vertices: v.co.y-=offset
    pts=[v.co for o in meshes for v in o.data.vertices]; front=-min(p.y for p in pts); rear=max(p.y for p in pts)
    body_pts=[p.z for p in pts if abs(p.x)<width*.45 and -front*.3<p.y<rear*.3]
    body_z=max(height*.26,min(height*.70,statistics.median(body_pts) if body_pts else height*.5))
    if family in ['bird','penguin']: body_z=height*.53
    textures=[]
    for n,obj in enumerate(meshes):
        bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.uv.smart_project(island_margin=.03); bpy.ops.object.mode_set(mode='OBJECT')
        mat=bpy.data.materials.new(key+f'_skin_{n}'); mat.use_nodes=True; nodes=mat.node_tree.nodes; links=mat.node_tree.links
        bsdf=nodes.get('Principled BSDF'); output=nodes.get('Material Output')
        paint=nodes.new('ShaderNodeVertexColor'); paint.layer_name='colorSet1'
        patterned_coat(nodes,links,paint,bsdf,key,width,front,rear,height)
        obj.data.materials.clear(); obj.data.materials.append(mat)
        for p in obj.data.polygons: p.material_index=0
        scene.render.engine='CYCLES'; scene.cycles.samples=4; scene.render.bake.margin=6
        scene.render.bake.use_pass_direct=False; scene.render.bake.use_pass_indirect=False; scene.render.bake.use_pass_color=True
        def tex(label,res=256,noncolor=True):
            im=bpy.data.images.new(key+f'_{n}_{label}',width=res,height=res,alpha=False)
            if noncolor: im.colorspace_settings.name='Non-Color'
            node=nodes.new('ShaderNodeTexImage'); node.image=im; nodes.active=node
            return node,im
        def save(im,label):
            path=OUT/f'{key}_{n}_{label}.png'; im.filepath_raw=str(path); im.file_format='PNG'; im.save(); im.pack(); textures.append(path.name)
        base,im=tex('albedo',512,False); bpy.ops.object.bake(type='DIFFUSE'); save(im,'albedo')
        links.new(base.outputs['Color'],bsdf.inputs['Base Color'])
        noise=nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value=90 if family not in ['reptile','armor','heavy','elephant'] else 35; noise.inputs['Detail'].default_value=3
        bump=nodes.new('ShaderNodeBump'); bump.inputs['Strength'].default_value=.22; bump.inputs['Distance'].default_value=.018 if family not in ['frog','bird','penguin'] else .005
        links.new(noise.outputs['Fac'],bump.inputs['Height']); links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])
        normal,im=tex('normal'); bpy.ops.object.bake(type='NORMAL'); save(im,'normal')
        normal_map=nodes.new('ShaderNodeNormalMap'); links.new(normal.outputs['Color'],normal_map.inputs['Color']); links.new(normal_map.outputs['Normal'],bsdf.inputs['Normal'])
        ao,im=tex('ao'); bpy.ops.object.bake(type='AO'); save(im,'ao')
        group=bpy.data.node_groups.new('glTF Material Output','ShaderNodeTree'); group.interface.new_socket(name='Occlusion',in_out='INPUT',socket_type='NodeSocketFloat')
        gn=nodes.new('ShaderNodeGroup'); gn.node_tree=group; links.new(ao.outputs['Color'],gn.inputs['Occlusion'])
        rough,im=tex('roughness'); ramp=nodes.new('ShaderNodeValToRGB')
        wet=family in ['frog','reptile','seal','walrus','otter']
        ramp.color_ramp.elements[0].color=((.36 if wet else .70),)*3+(1,); ramp.color_ramp.elements[1].color=((.58 if wet else .90),)*3+(1,)
        links.new(noise.outputs['Fac'],ramp.inputs[0]); emission=nodes.new('ShaderNodeEmission'); links.new(ramp.outputs[0],emission.inputs[0]); links.new(emission.outputs[0],output.inputs['Surface'])
        bpy.ops.object.bake(type='EMIT'); save(im,'roughness'); links.new(bsdf.outputs[0],output.inputs['Surface']); links.new(rough.outputs['Color'],bsdf.inputs['Roughness'])
        for node in [noise,bump,ramp,emission]: nodes.remove(node)
    arm,clips=rig_and_animate(scene,meshes,row,height,width,front,rear,body_z)
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes+[arm]: o.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'{key}.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_materials='EXPORT',export_vertex_color='NONE')
    for track in arm.animation_data.nla_tracks: track.mute=True
    for p in arm.pose.bones: p.rotation_euler=(0,0,0); p.location=(0,0,0)
    scene.view_settings.view_transform='Standard'; scene.view_settings.look='None'; scene.view_settings.exposure=-.4
    world=bpy.data.worlds.new(key+'_world'); world.use_nodes=True; world.node_tree.nodes['Background'].inputs[1].default_value=.7; scene.world=world
    target=Vector((0,(rear-front)/2,height*.46))
    cd=bpy.data.cameras.new('Portrait'); camera=bpy.data.objects.new('Portrait',cd); scene.collection.objects.link(camera); camera.location=target+Vector((size*.9,-size*1.4,size*.65)); camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler(); cd.type='ORTHO'; cd.ortho_scale=size*1.16; scene.camera=camera
    for at,energy in [((3,-4,6),600),((-3,-1,4),300)]:
        ld=bpy.data.lights.new('Softbox','AREA'); light=bpy.data.objects.new('Softbox',ld); scene.collection.objects.link(light); light.location=at; ld.energy=energy; ld.size=5; light.rotation_euler=(target-light.location).to_track_quat('-Z','Y').to_euler()
    scene.cycles.samples=12; scene.render.resolution_x=256; scene.render.resolution_y=256; scene.render.resolution_percentage=100; scene.render.film_transparent=True; scene.render.image_settings.file_format='PNG'; scene.render.filepath=str(OUT/f'{key}.png'); bpy.ops.render.render(write_still=True)
    for track in arm.animation_data.nla_tracks: track.mute=False
    bpy.data.libraries.write(str(PREP/f'{key}.blend'),{scene},fake_user=True)
    entry=dict(id=key,title=title,source=source,family=family,ability=ability,period=PERIOD[family]/SPECIES_MOTION[key][0],height=height,size=size,model_scale={'rhino':1.4,'owl':1.5,'frog':1.25,'otter':1.25,'elephant':1.05,'turtle':1.25,'monkey':1.1}.get(key,1.15),clips=clips,textures=textures,bones=len(arm.data.bones),vertices=sum(len(o.data.vertices) for o in meshes),forward='-Y Blender / -Z Godot after model rotation PI')
    (OUT/f'{key}.json').write_text(json.dumps(entry,indent=2)); manifest.append(entry)
    print('ROSTER_ASSET_READY',key,len(clips),flush=True)
    bpy.context.window.scene=source_scene
    # Free only newly created scene objects; never touch the source library.
    for obj in list(scene.objects): bpy.data.objects.remove(obj,do_unlink=True)
    bpy.data.scenes.remove(scene)
if args.only:
    manifest=[json.loads((OUT/f'{r[0]}.json').read_text()) for r in ROWS if (OUT/f'{r[0]}.json').exists()]
(OUT/'roster.json').write_text(json.dumps(manifest,indent=2))
print('ROSTER_PREPARATION_COMPLETE',len(manifest),flush=True)
