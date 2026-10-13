from PIL import Image, ImageDraw
from pathlib import Path
root=Path(__file__).resolve().parent/'screenshots'
for clip in ['run','ability']:
    sheet=Image.new('RGB',(1024,7*284),'#d9e8d1')
    draw=ImageDraw.Draw(sheet)
    for row,name in enumerate(['rhino','owl','frog','otter','elephant','turtle','monkey']):
        draw.text((8,row*284+4),name+' / '+clip,fill='black')
        for phase in range(4):
            with Image.open(root/f'animal-{name}-{clip}-{phase}.png') as im:
                sheet.paste(im.convert('RGB'),(phase*256,row*284+24))
    sheet.save(root/f'animal-motion-{clip}.jpg',quality=92)
