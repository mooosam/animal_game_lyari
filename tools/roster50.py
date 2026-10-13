"""Approved roster. Asset family and ability are separate from species identity."""
ROWS = [
('rhino','Rhino','Rhino','heavy','smash',2.7),
('owl','Snowy Owl','SnowyOwl','bird','fly',2.5),
('frog','Green Frog','RedEyedTreeFrog','frog','jump',1.6),
('otter','Otter','Otter','otter','swim',2.3),
('elephant','Elephant','Elephant','elephant','smash',3.3),
('turtle','Tortoise','Tortoise','armor','shield',2.0),
('monkey','Chimpanzee','Chimpanzee','ape','climb',2.3),
('lion','Lion','Lion','feline','jump',2.8),
('tiger','Tiger','Tiger','feline','jump',2.8),
('cheetah','Cheetah','Cheetah','feline','jump',2.8),
('snow_leopard','Snow Leopard','SnowLeopard','feline','climb',2.6),
('mountain_lion','Mountain Lion','MountainLion','feline','jump',2.7),
('gray_wolf','Gray Wolf','GrayWolf','canine','jump',2.5),
('red_fox','Red Fox','RedFox','canine','jump',2.0),
('arctic_fox','Arctic Fox','ArcticFox','canine','jump',2.0),
('brown_bear','Brown Bear','BrownBear','bear','smash',3.0),
('polar_bear','Polar Bear','PolarBear','bear','swim',3.0),
('black_bear','Black Bear','BlackBear','bear','climb',2.8),
('panda','Giant Panda','Panda','bear','climb',2.5),
('red_panda','Red Panda','RedPanda','climber','climb',2.2),
('gorilla','Gorilla','Gorilla','ape','smash',2.8),
('orangutan','Orangutan','Orangutan','ape','climb',2.5),
('mandrill','Mandrill','Mandrill','primate','climb',2.2),
('sloth','Sloth','Sloth','sloth','climb',2.0),
('koala','Koala','KoalaBear','climber','climb',2.0),
('giraffe','Giraffe','Giraffe','giraffe','reach',3.8),
('zebra','Zebra','Zebra','hoof','jump',3.0),
('hippo','Hippopotamus','Hippo','heavy','swim',3.0),
('bison','Bison','Bison','hoof','smash',3.0),
('camel','Camel','Camel','camelid','jump',3.2),
('llama','Llama','Llama','camelid','jump',2.8),
('goat','Goat','Goat','hoof','climb',2.4),
('ibex','Ibex','Ibex','hoof','climb',2.5),
('bighorn_sheep','Bighorn Sheep','BighornSheep','hoof','smash',2.5),
('moose','Moose','Moose','hoof','jump',3.2),
('deer','Deer','Deer','hoof','jump',2.8),
('boar','Wild Boar','Boar','heavy','smash',2.4),
('armadillo','Armadillo','Armadillo','armor','shield',2.0),
('anteater','Anteater','Anteater','anteater','dig',2.6),
('hedgehog','Hedgehog','Hedgehog','armor','shield',1.8),
('rabbit','Rabbit','Rabbit','hopper','jump',1.8),
('red_squirrel','Red Squirrel','RedSquirrel','hopper','climb',2.0),
('raccoon','Raccoon','Raccoon','climber','climb',2.2),
('crocodile','Crocodile','Crocodile','reptile','swim',3.0),
('komodo_dragon','Komodo Dragon','KomodoDragon','reptile','swim',2.8),
('chameleon','Chameleon','Chameleon','reptile','climb',2.0),
('eagle','Eagle','Eagle','bird','fly',2.8),
('penguin','Penguin','Penguin','penguin','swim',2.0),
('harbour_seal','Harbour Seal','HarbourSeal','seal','swim',2.8),
('walrus','Walrus','Walrus','walrus','swim',3.0),
]
NO_JUMP={'elephant','hippo','rhino','turtle','giraffe','sloth','harbour_seal','walrus','armadillo','hedgehog'}
PERIOD={'feline':.70,'canine':.78,'bear':1.05,'climber':.95,'ape':.9,'primate':.78,'sloth':3.0,'heavy':1.10,'elephant':1.4,'armor':1.8,'hoof':.88,'camelid':1.1,'giraffe':1.3,'hopper':.68,'frog':.74,'otter':.70,'reptile':1.25,'bird':.85,'penguin':.9,'seal':1.15,'walrus':1.45,'anteater':1.25}

def clips_for(row):
    key,title,source,family,ability,size=row
    clips=['idle','walk','run','turn_left','turn_right','stop','interact','hit_reaction','ability','celebrate']
    if family not in ['bird','frog','penguin','seal','sloth','armor']: clips+=['trot']
    if key not in NO_JUMP and family not in ['bird','reptile']: clips+=['jump','land']
    extras={
      'feline':['sprint','stalk','leap','roar'], 'canine':['pounce','dig','sit'],
      'bear':['stand','sit','charge'], 'ape':['knuckle_walk','climb','reach','hang','sit','grab'],
      'primate':['climb','forage','sit'], 'climber':['climb','descend','balance','eat'],
      'sloth':['hang','climb','reach','branch_transfer','sleep'],
      'heavy':['charge','head_swing','eat'], 'elephant':['fast_walk','trunk_grab','push','drink','eat'],
      'armor':['slow_walk','retract','emerge','defend','eat'], 'hoof':['climb','graze','head_butt'],
      'camelid':['pace','kneel','stand_up','eat'], 'giraffe':['pace','eat_high','drink'],
      'hopper':['bound','sprint','climb','eat'], 'frog':['crouch','hop','long_jump','frog_kick','swim'],
      'otter':['bound','slide','swim','dive','surface','roll'],
      'reptile':['low_walk','high_walk','swim','dive','tail_whip'],
      'bird':['perch','takeoff','flap','glide','bank_left','bank_right','dive','land'],
      'penguin':['waddle','fast_waddle','belly_slide','swim','dive','flipper_shake'],
      'seal':['land_undulate','swim','fast_swim','dive','surface','roll'],
      'walrus':['haul_out','swim','dive','surface','flipper_slap'],
      'anteater':['dig','feed','rear']}
    clips+=extras[family]
    if ability=='swim': clips+=['swim','dive','surface']
    if key=='chameleon': clips+=['reach','tail_coil','tail_uncoil','tongue_strike']
    if key=='red_squirrel': clips+=['descend','tail_flick']
    if key=='tiger': clips+=['swim']
    if key=='arctic_fox': clips+=['snow_bound','curl_sleep']
    if key=='hedgehog': clips+=['curl','uncurl','sniff']
    import pathlib,re
    notes=pathlib.Path('C:/Users/Home/.codex/attachments/dc060ef9-4aa7-4200-a4c5-ded289eb91cd/Pasted text.txt')
    if notes.exists():
        for line in notes.read_text(encoding='utf-8-sig').splitlines():
            fields=line.split('\t')
            if len(fields)>=4 and fields[0]==title:
                for name in fields[1].split(','):
                    name=name.strip()
                    if name in ['Turn L/R','Bank L/R']:
                        clips += ['turn_left','turn_right'] if name.startswith('Turn') else ['bank_left','bank_right']
                    else: clips.append(re.sub(r'[^a-z0-9]+','_',name.lower()).strip('_'))
    return list(dict.fromkeys(clips))
