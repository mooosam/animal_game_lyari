import pathlib,sys,subprocess
sys.path.insert(0,str(pathlib.Path(__file__).parent/'media_deps'))
import imageio_ffmpeg
from PIL import Image,ImageDraw
root=pathlib.Path(__file__).resolve().parents[1]
out=root/'tools/reference_frames'; out.mkdir(exist_ok=True)
ff=imageio_ffmpeg.get_ffmpeg_exe()
subprocess.run([ff,'-y','-i','C:/Users/Home/Downloads/dino_dash_game.mp4','-vf','fps=1/5,scale=300:-1',str(out/'frame-%03d.png')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
files=sorted(out.glob('frame-*.png'))
for chunk in range(0,len(files),8):
    sheet=Image.new('RGB',(1200,1380),'#172b30'); draw=ImageDraw.Draw(sheet)
    for j,path in enumerate(files[chunk:chunk+8]):
        im=Image.open(path); x=(j%4)*300; y=(j//4)*690
        sheet.paste(im,(x,y+20)); draw.text((x+10,y+3),f'{(chunk+j)*5:03d} seconds',fill='white')
    sheet.save(out/f'contact-{chunk//8}.jpg')
print('REFERENCE_FRAMES',len(files))
