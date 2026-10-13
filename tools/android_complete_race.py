"""Drive the visible Gentle-mode hints and verify an installed Android race."""
import argparse, json, subprocess, time
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser()
parser.add_argument('--level',type=int,choices=range(1,11),default=9)
level=parser.parse_args().level
ADB=ROOT/'tools/android/sdk/platform-tools/adb.exe'
OUT=ROOT/'tools/screenshots'
def adb(*args):
    return subprocess.run([str(ADB),'-s','emulator-5554',*map(str,args)],
                          check=True, capture_output=True, timeout=30).stdout
def frame():
    adb('shell','screencap','-p','/data/local/tmp/complete-race.png')
    adb('pull','/data/local/tmp/complete-race.png',OUT/'android-live-race.png')
    return Image.open(OUT/'android-live-race.png').convert('RGB')
def tap(x,y,w,h): adb('shell','input','tap',int(x*w),int(y*h))
progress=ROOT/'tools/android_complete_progress.json'
progress.write_text(json.dumps(dict(gentle=True,highest=level,music=True,sound=True,version=1)))
try:
    adb('shell','am','force-stop','com.animalswitch.game')
    adb('push',progress,'/data/local/tmp/complete-progress.json')
    adb('shell','run-as','com.animalswitch.game','cp','/data/local/tmp/complete-progress.json','files/progress.json')
    adb('shell','am','start','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-p','com.animalswitch.game')
    started=False
    switches=0
    for attempt in range(180):
        time.sleep(1)
        im=frame(); w,h=im.size
        green=sum(g>180 and g-r>35 and g-b>45 for r,g,b in
                  (im.getpixel((x,int(h*.636))) for x in range(int(w*.25),int(w*.75))))
        if green>w*.375:
            tap(.5,.636,w,h)
            continue
        bar=any(sum(min(im.getpixel((x,y)))>200 for x in range(int(w*.25),int(w*.75)))>w*.4
                for y in range(int(h*.08),int(h*.14),2))
        if bar:
            started=True
            for index,cx in enumerate((.2,.5,.8)):
                yellow=sum(r>220 and g>170 and b<160 and r>g
                           for y in range(int(h*.794),int(h*.82),2)
                           for x in range(int(w*(cx-.10)),int(w*(cx+.10)),2)
                           for r,g,b in [im.getpixel((x,y))])
                if yellow>25:
                    im.save(OUT/f'android-hint-{index}.png')
                    tap(cx,.885,w,h)
                    switches+=1
                    print(f'ANDROID_HINT_SWITCH button={index+1} count={switches}',flush=True)
                    time.sleep(1)
                    frame().save(OUT/f'android-traversal-{index}.png')
                    break
            if attempt%15==0: print(f'ANDROID_RACE_ACTIVE attempt={attempt}',flush=True)
        elif started:
            # Results are a cream panel with a green continuation button.
            cream=sum(r>210 and g>200 and b>150 and r>b+10
                      for y in range(int(h*.25),int(h*.75),8)
                      for x in range(int(w*.15),int(w*.85),8)
                      for r,g,b in [im.getpixel((x,y))])
            if cream>1500:
                im.save(OUT/'android-complete-results.png')
                saved=json.loads(adb('shell','run-as','com.animalswitch.game','cat','files/progress.json'))
                if saved['highest']!=min(level+1,10): raise RuntimeError(f'Unlock failed: {saved}')
                print(f'ANDROID_COMPLETE_RACE_PASS level={level} switches={switches} highest={saved["highest"]}',flush=True)
                break
    else: raise RuntimeError('Race completion timed out')
finally:
    adb('shell','am','force-stop','com.animalswitch.game')
    adb('push',ROOT/'tools/android_library_original_progress.json','/data/local/tmp/original-progress.json')
    adb('shell','run-as','com.animalswitch.game','cp','/data/local/tmp/original-progress.json','files/progress.json')
