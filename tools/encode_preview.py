import pathlib,sys,subprocess
sys.path.insert(0,str(pathlib.Path(__file__).parent/'media_deps'))
import imageio_ffmpeg
root=pathlib.Path(__file__).resolve().parents[1]
shots=root/'tools/screenshots'
ff=imageio_ffmpeg.get_ffmpeg_exe()
subprocess.run([ff,'-y','-i',str(shots/'animal-switch-preview.avi'),'-c:v','libx264','-preset','fast','-crf','22','-pix_fmt','yuv420p','-c:a','aac','-b:a','96k','-movflags','+faststart',str(shots/'animal-switch-preview.mp4')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
for time in [7,15,22]:
    subprocess.run([ff,'-y','-ss',str(time),'-i',str(shots/'animal-switch-preview.mp4'),'-frames:v','1',str(shots/f'preview-{time}.png')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
print('PREVIEW_ENCODED', (shots/'animal-switch-preview.mp4').stat().st_size)
