"""Reject splash screens, menus, and Android dialogs during APK smoke tests."""
import sys
from PIL import Image
im=Image.open(sys.argv[1]).convert('RGB')
w,h=im.size
left,right=int(w*.25),int(w*.75)
if '--home' in sys.argv:
    # The PLAY button spans the center of this row. Android's launcher and
    # ANR dialogs can be large PNGs, so image size is not a readiness check.
    y=int(h*.636)
    green=sum(g>180 and g-r>35 and g-b>45 for r,g,b in
              (im.getpixel((x,y)) for x in range(left,right)))
    ready=green/(right-left)>.75
    print('ANDROID_HOME_FRAME_READY' if ready else 'ANDROID_HOME_FRAME_PENDING')
    sys.exit(0 if ready else 1)
bar=False
for y in range(int(h*.08),int(h*.14)):
    white=sum(min(im.getpixel((x,y)))>200 for x in range(left,right))
    if white/(right-left)>.8: bar=True; break
gray=total=0
for y in range(int(h*.82),int(h*.92),4):
    for x in range(int(w*.08),int(w*.92),4):
        rgb=im.getpixel((x,y)); total+=1
        gray+=max(rgb)-min(rgb)<30 and 95<sum(rgb)/3<235
ready=bar and gray/max(1,total)>.3
print('ANDROID_RACE_FRAME_READY' if ready else 'ANDROID_RACE_FRAME_PENDING')
sys.exit(0 if ready else 1)
