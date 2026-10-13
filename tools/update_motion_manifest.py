"""Keep Godot's phase clock matched to each generated species gait rate."""
import ast, json
from pathlib import Path
from roster50 import ROWS, PERIOD

ROOT=Path(__file__).resolve().parents[1]
PREPARER=Path(__file__).with_name('prepare_roster50.py')
tree=ast.parse(PREPARER.read_text(encoding='utf-8'))
profiles=None
for node in tree.body:
    if isinstance(node,ast.Assign) and any(isinstance(target,ast.Name) and target.id=='SPECIES_MOTION' for target in node.targets):
        profiles=ast.literal_eval(node.value)
        break
if profiles is None: raise RuntimeError('SPECIES_MOTION mapping missing')
assets=ROOT/'game'/'assets'/'animals'
entries=[]
for key,title,source,family,ability,size in ROWS:
    path=assets/f'{key}.json'
    item=json.loads(path.read_text(encoding='utf-8'))
    item['period']=PERIOD[family]/profiles[key][0]
    path.write_text(json.dumps(item,indent=2),encoding='utf-8')
    entries.append(item)
(assets/'roster.json').write_text(json.dumps(entries,indent=2),encoding='utf-8')
print(f'MOTION_MANIFEST_PASS animals={len(entries)} cadence_min={min(x[0] for x in profiles.values()):.2f} cadence_max={max(x[0] for x in profiles.values()):.2f}')
