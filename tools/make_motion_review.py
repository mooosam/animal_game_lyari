"""Build compact visual contact sheets from the Godot roster animation captures."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json

ROOT=Path(__file__).resolve().parents[1]
CAPTURES=ROOT/'tools'/'screenshots'
animals=json.loads((ROOT/'game'/'assets'/'animals'/'roster.json').read_text())
font=ImageFont.load_default()
for clip in ['run','ability']:
    for batch in range(5):
        group=animals[batch*10:(batch+1)*10]
        sheet=Image.new('RGB',(820,10*142),'#e4eee4')
        draw=ImageDraw.Draw(sheet)
        for row,animal in enumerate(group):
            y=row*142
            draw.text((6,y+5),f"{animal['id']} / {clip}",fill='#172c22',font=font)
            for phase in range(4):
                source=CAPTURES/f"roster-{animal['id']}-{clip}-{phase}.png"
                with Image.open(source) as im:
                    # Keep the animal and its contact shadow while dropping
                    # the viewer controls and labels from the review image.
                    crop=im.crop((0,int(im.height*.42),im.width,int(im.height*.83)))
                    crop.thumbnail((196,120),Image.Resampling.LANCZOS)
                    x=8+phase*202+(196-crop.width)//2
                    sheet.paste(crop,(x,y+20+(120-crop.height)//2))
        out=CAPTURES/f'motion-review-{clip}-{batch+1:02d}.jpg'
        sheet.save(out,quality=91)
        print(out)
