#!/usr/bin/env python3
"""Offline real-asset contact sheets; explicitly NOT native screenshots."""
import json
from PIL import Image,ImageDraw,ImageFont
from build_gloves import OUT,ROOT,NAMES,compose,sha
LIGHT=(229,227,216);DARK=(29,35,43)
def matte(im,bg):
    out=Image.new('RGBA',im.size,bg+(255,));out.alpha_composite(im);return out.convert('RGB')
def render():
    dest=OUT/'evidence/review';dest.mkdir(parents=True,exist_ok=True)
    font=ImageFont.truetype(json.loads((OUT/'recipe.json').read_text())['font'],14)
    written={}
    def save(name,im):
        p=dest/name;im.save(p);written[name]=sha(p)
    for n in NAMES:
        cache={}
        for w in [None,'sword','axe','spear','bow']:
            for s in [None,'kite','round']:
                im=compose(n,w,s);cache[w,s]=im
                save(f'composite-{n}-{w or "none"}-{s or "none"}.png',im)
        # Same original weapons, original grip alpha, glove priority19/21, shield22.
        sheet=Image.new('RGB',(920,900),(66,69,72));d=ImageDraw.Draw(sheet)
        d.text((8,5),n+' | OFFLINE actual source stack 19 glove /20 weapon /21 original-alpha glove /22 shield',font=font,fill='white')
        for row,bg in enumerate([LIGHT,DARK]):
            for col,w in enumerate([None,'sword','axe','spear','bow']):
                x=col*184;y=35+row*210
                d.text((x+2,y),w or 'no held item',font=font,fill='white')
                sheet.paste(matte(cache[w,None].crop((75,465,255,650)),bg),(x+2,y+20))
            for col,s in enumerate([None,'kite','round']):
                x=col*305;y=460+row*212
                d.text((x+2,y),'shield hand / '+(s or 'none'),font=font,fill='white')
                sheet.paste(matte(cache[None,s].crop((595,480,895,665)),bg),(x+2,y+20))
        save(f'hand-contacts-{n}.png',sheet)
        # Exact sample heights on both contrasting backgrounds, seven relevant joins.
        states=[(None,None),('sword',None),('axe',None),('spear',None),('bow',None),('sword','kite'),('axe','round')]
        for k in range(0,len(states),3):
            subset=states[k:k+3]
            menu=Image.new('RGB',(900,950),(66,69,72));md=ImageDraw.Draw(menu)
            md.text((8,5),n+' | exact 400px canvas menu samples | OFFLINE',font=font,fill='white')
            for col,state in enumerate(subset):
                for row,bg in enumerate([LIGHT,DARK]):
                    x=col*300;y=30+row*455
                    md.text((x+3,y),str(state),font=font,fill='white')
                    im=cache[state].resize((267,400),Image.Resampling.LANCZOS)
                    menu.paste(matte(im,bg),(x+15,y+24))
            save(f'menu-400-{n}-{k//3}.png',menu)
        for s in [None,'kite','round']:
            small=Image.new('RGB',(900,560),(66,69,72));sd=ImageDraw.Draw(small)
            sd.text((7,4),n+' / shield '+str(s)+' / EXACT 120px and 90px canvas heights, OFFLINE',font=font,fill='white')
            for col,w in enumerate([None,'sword','axe','spear','bow']):
                x=col*180;sd.text((x+4,25),w or 'none',font=font,fill='white')
                for row,bg in enumerate([LIGHT,DARK]):
                    for height,yy in [(120,50),(90,185)]:
                        im=cache[w,s].resize((round(1024*height/1536),height),Image.Resampling.LANCZOS)
                        small.paste(matte(im,bg),(x+35,yy+row*270))
            save(f'tactical-120-90-{n}-{s or "none"}.png',small)
        # Isolated paint and source alongside true original contour.
        isol=Image.new('RGB',(900,500),LIGHT);idraw=ImageDraw.Draw(isol)
        for j,label in enumerate(['reference-'+n,n+'-master','glove_pair_'+n]):
            p=OUT/('characters' if j==2 else 'sources')/(label+'.png')
            with Image.open(p) as im:
                for h,box in enumerate([(75,445,295,650),(595,480,880,665)]):
                    cut=im.convert('RGBA').crop(box);isol.paste(matte(cut,LIGHT if h==0 else DARK),(j*300,25+h*235))
            idraw.text((j*300+3,5),label,font=font,fill='black')
        save(f'source-isolated-{n}.png',isol)
    # Exact original removal is also a saved artifact.
    save('removed-exact-foundation.png',compose())
    report={'kind':'offline PNG proof, not gameplay or native engine','files':written,'renderer_sha256':sha(OUT/'render_review.py'),'builder_sha256':sha(OUT/'build_gloves.py')}
    (dest/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
    print('review emitted',len(written),'PNGs')
if __name__=='__main__':render()
