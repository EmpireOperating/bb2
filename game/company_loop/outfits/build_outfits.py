#!/usr/bin/env python3
"""Offline deterministic extraction of genuine painted lower outfits.
Never imports a legacy builder or writes any immutable input. No network calls.
"""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[1]
SIZE=(1024,1536)
NAMES=('quilt','mail','brigandine')

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):
    im=Image.open(p)
    assert im.size==SIZE, (str(p),im.size)
    return im.convert('RGBA')

def key(p):
    rgb=np.array(Image.open(p).convert('RGB'),dtype=np.float32)
    r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    spill=np.maximum(np.minimum(r,b)-g,0)
    chroma=(b>r*.62)&(b>g*1.3)&(spill>35)
    alpha=np.ones(r.shape,dtype=np.float32)
    alpha[chroma]=1-spill[chroma]/np.maximum(255-g[chroma],1)
    alpha[(alpha<.10)|(chroma&(np.minimum(r,b)>180)&(g<80))]=0
    safe=np.maximum(alpha,1/255)
    for c in (0,2): rgb[:,:,c][chroma]=(rgb[:,:,c][chroma]-(1-alpha[chroma])*255)/safe[chroma]
    rgb[:,:,1][chroma]/=safe[chroma]
    a=np.dstack((np.clip(rgb,0,255),alpha*255)).round().astype(np.uint8)
    a[alpha==0]=0
    return Image.fromarray(a)

def hem(upper,recipe):
    a=np.array(upper)[:,:,3]
    y=np.arange(SIZE[1])[:,None]
    last=np.where((a>recipe['hem_alpha_threshold'])&(y>=recipe['lower_only_from_y']),y,0).max(axis=0)
    return np.maximum(last-recipe['hem_underlap_pixels'],recipe['lower_only_from_y'])

def translated_lower(source,top,spec,recipe):
    # Each lower leg is a whole integer-translated source island; no resize,
    # pixel filter, recoloring, invented texture or generated anatomy is used.
    split=recipe['leg_split_x']; im=Image.new('RGBA',SIZE)
    for part,box in [('left',(0,0,split,SIZE[1])),('right',(split,0,SIZE[0],SIZE[1]))]:
        dx,dy=spec[part]
        im.paste(source.crop(box),(box[0]+dx,dy))
    a=np.array(im); a[np.arange(SIZE[1])[:,None]<top[None,:]]=0
    return Image.fromarray(a)

def masked_base(base,keep):
    b=np.array(base)
    b[:,:,3]=(b[:,:,3].astype(np.uint16)*keep.astype(np.uint16)//255).astype(np.uint8)
    return Image.fromarray(b)

def background(im,color):
    back=Image.new('RGBA',im.size,tuple(color)+(255,)); back.alpha_composite(im)
    return back.convert('RGB')

def evidence(base,uppers,lowers,outfits,keep,recipe,emit):
    light=(223,221,207); dark=(29,35,42)
    font=ImageFont.truetype(recipe['font'],18)
    small=ImageFont.truetype(recipe['font'],14)
    composites={n:Image.alpha_composite(masked_base(base,keep),outfits[n]) for n in NAMES}
    for n,im in composites.items(): emit('evidence/composite-'+n+'.png',im)
    # Exact 400px menu and exact 90/120px tactical canvas heights.
    sheet=Image.new('RGB',(1800,925),(43,47,52)); d=ImageDraw.Draw(sheet)
    d.text((15,10),'OFFLINE OUTFIT PROOF | 400px MENU / ACTUAL 120px + 90px | not engine evidence',font=font,fill='white')
    for i,n in enumerate(NAMES):
        x=i*600
        d.text((x+15,48),n+' | unchanged accepted upper + new painted lower',font=small,fill='white')
        for height,y in [(400,82),(120,550),(90,735)]:
            im=composites[n].resize((round(1024*height/1536),height),Image.Resampling.LANCZOS)
            for j,bg in enumerate([light,dark]):
                xx=x+20+j*290
                sheet.paste(background(im,bg),(xx,y))
                d.text((xx,y+height+8),str(height)+'px '+('light' if j==0 else 'dark'),font=small,fill='white')
    emit('evidence/readability-400-120-90.png',sheet)
    # Layout is <=1000px per axis so review does not implicitly halve samples.
    tactical=Image.new('RGB',(900,350),(43,47,52)); d=ImageDraw.Draw(tactical)
    d.text((10,8),'EXACT canvas heights: 120px top / 90px bottom. Offline, no upscale.',font=small,fill='white')
    menu=Image.new('RGB',(900,940),(43,47,52)); md=ImageDraw.Draw(menu)
    md.text((10,8),'EXACT 400px menu canvas | offline source composite, no engine claim',font=small,fill='white')
    for i,n in enumerate(NAMES):
        for j,bg in enumerate([light,dark]):
            x=(i*2+j)*150
            d.text((x+5,35),n+(' / light' if j==0 else ' / dark'),font=small,fill='white')
            for height,y in [(120,60),(90,230)]:
                thumb=composites[n].resize((round(1024*height/1536),height),Image.Resampling.LANCZOS)
                tactical.paste(background(thumb,bg),(x+30,y))
            xx=i*300; yy=40+j*450
            md.text((xx+8,yy),n+(' / light' if j==0 else ' / dark'),font=small,fill='white')
            menu.paste(background(composites[n].resize((267,400),Image.Resampling.LANCZOS),bg),(xx+15,yy+28))
    emit('evidence/actual-tactical-120-90.png',tactical)
    emit('evidence/actual-menu-400.png',menu)
    # Accepted reference / unmodified source master / delivered exact-upper composite.
    source_sheet=Image.new('RGB',(2460,505),light); d=ImageDraw.Draw(source_sheet)
    for i,n in enumerate(NAMES):
        for j,(label,im) in enumerate([('accepted reference',load(OUT/f'sources/reference-{n}.png')),('raw generated source',load(OUT/f'sources/{n}-master.png')),('delivered composite',composites[n])]):
            x=(i*3+j)*273
            d.text((x+5,12),n+' / '+label,font=small,fill=(20,22,26))
            d.text((x+5,34),'400px full canvas',font=small,fill=(20,22,26))
            sheet_im=im.resize((267,400),Image.Resampling.LANCZOS)
            source_sheet.paste(background(sheet_im,light),(x+3,65))
    emit('evidence/reference-source-delivery.png',source_sheet)
    isolated=Image.new('RGB',(1800,1010),light); d=ImageDraw.Draw(isolated)
    for i,n in enumerate(NAMES):
        x=i*600
        d.text((x+10,10),n+' : retained upper | new lower | full outfit',font=small,fill=(20,22,26))
        for j,im in enumerate([uppers[n],lowers[n],outfits[n]]):
            cut=im.resize((195,293),Image.Resampling.LANCZOS)
            for k,bg in enumerate([light,dark]): isolated.paste(background(cut,bg),(x+j*200,50+k*360))
        # The full mask visualized independently: white=keep; black=suppress.
    mask=Image.new('RGBA',SIZE,(255,255,255,255)); mask.putalpha(Image.fromarray(keep))
    isolated.paste(background(mask.resize((160,240),Image.Resampling.NEAREST),dark),(20,755))
    d.text((210,780),'Common ALPHA mask; source-bound per-column hem, no runtime cutoff.',font=small,fill=(20,22,26))
    d.text((210,810),'All original lower foundation paint is suppressed; original upper/identity remains.',font=small,fill=(20,22,26))
    emit('evidence/isolated-layers-and-mask.png',isolated)
    joins=Image.new('RGB',(2100,1040),light); d=ImageDraw.Draw(joins)
    for i,n in enumerate(NAMES):
        x=i*700; d.text((x+10,8),n+' | current waist / hem at native pixels',font=small,fill=(20,22,26))
        cut=composites[n].crop((150,685,850,965))
        joins.paste(background(cut,light),(x,40)); joins.paste(background(cut,dark),(x,350))
        d.text((x+10,650),'Boots / material / soles (scaled crop, not tactical)',font=small,fill=(20,22,26))
        cut=composites[n].crop((65,1030,985,1500)).resize((660,337),Image.Resampling.LANCZOS)
        joins.paste(background(cut,light),(x+20,680))
    emit('evidence/hem-and-boot-joins.png',joins)
    # Both armor removals and all three identity families, no fake gear changes.
    identity_paths=[ROOT/'sprite_study/assets/characters/foundation.png',ROOT/'company_loop/assets/characters/foundation_copper.png',ROOT/'company_loop/assets/characters/foundation_silver.png']
    removal=Image.new('RGB',(1440,1130),light); d=ImageDraw.Draw(removal)
    for row,p in enumerate(identity_paths):
        b=load(p)
        for col,n in enumerate(('brigandine','mail','quilt',None)):
            im=Image.alpha_composite(masked_base(b,keep),outfits[n]) if n else b.copy()
            x=col*360;y=row*375
            d.text((x+6,y+5),p.stem.replace('foundation','identity')+' / '+(n or 'NO GEAR: exact base'),font=small,fill=(20,22,26))
            removal.paste(background(im.resize((227,340),Image.Resampling.LANCZOS),light),(x+60,y+28))
    emit('evidence/identity-and-removal.png',removal)
    return composites

def build():
    assert OUT.name=='outfits' and OUT.parent.name=='company_loop', 'Output root escaped lane'
    recipe=json.loads((OUT/'recipe.json').read_text())
    for name,h in json.loads((OUT/'protected-inputs.json').read_text()).items():
        assert sha(ROOT/name)==h, 'Protected input changed: '+name
    for n,h in recipe['source_hashes'].items(): assert sha(OUT/f'sources/{n}-master.png')==h,n
    emitted=[]
    def emit(name,im):
        path=OUT/name; assert path.is_relative_to(OUT)
        path.parent.mkdir(parents=True,exist_ok=True); im.save(path); emitted.append(path)
    base=load(ROOT/'sprite_study/assets/characters/foundation.png')
    uppers={n:load(ROOT/f'sprite_study/assets/characters/body_{n}.png') for n in NAMES}
    tops={n:hem(uppers[n],recipe) for n in NAMES}
    top=np.minimum.reduce(list(tops.values()))
    keep=np.where(np.arange(SIZE[1])[:,None]<top[None,:],255,0).astype(np.uint8)
    mask=Image.new('RGBA',SIZE,(255,255,255,255));mask.putalpha(Image.fromarray(keep))
    emit('characters/foundation_keep_mask.png',mask)
    lowers={};outfits={}
    metrics={}
    for n in NAMES:
        lower=translated_lower(key(OUT/f'sources/{n}-master.png'),tops[n],recipe['leg_integer_translations'][n],recipe)
        lower_arr=np.array(lower)
        upper_arr=np.array(uppers[n])
        full=np.array(Image.alpha_composite(lower,uppers[n]))
        full[:recipe['lower_only_from_y']]=upper_arr[:recipe['lower_only_from_y']]
        lowers[n]=lower;outfits[n]=Image.fromarray(full)
        emit('evidence/lower-'+n+'.png',lower)
        emit('characters/outfit_'+n+'.png',outfits[n])
        opaque=upper_arr[:,:,3]==255
        assert np.array_equal(full[opaque],upper_arr[opaque])
        metrics[n]={'preserved_upper_opaque_pixels':int(opaque.sum()),'lower_visible_pixels':int((lower_arr[:,:,3]>0).sum()),'lower_opaque_pixels':int((lower_arr[:,:,3]==255).sum()),'sole_bbox_alpha_gt_200':[]}
        for box in [(0,1250,500,1536),(500,1350,1024,1536)]:
            x1,y1,x2,y2=box;yy,xx=np.nonzero(full[y1:y2,x1:x2,3]>200)
            metrics[n]['sole_bbox_alpha_gt_200'].append([int(xx.min()+x1),int(yy.min()+y1),int(xx.max()+x1+1),int(yy.max()+y1+1)])
    evidence(base,uppers,lowers,outfits,keep,recipe,emit)
    manifest={k:recipe[k] for k in ('canvas','foot_anchor','pixel_size')}
    manifest.update({'authority_priority':['body/outer','body/mail','body/base'],'mechanical_changes':[],
        'bindings':{'body_quilt':'outfit_quilt','body_mail':'outfit_mail','body_brigandine':'outfit_brigandine'},
        'mask':'foundation_keep_mask','mask_channel':'alpha','status':'offline painted-art candidate; native runtime acceptance owned separately',
        'generation_calls':3,'repair_calls':0,'recipe_sha256':sha(OUT/'recipe.json'),'builder_sha256':sha(Path(__file__)),
        'protected_inputs_sha256':sha(OUT/'protected-inputs.json'),'receipts_sha256':sha(OUT/'sources/generation-tool-receipts.json'),
        'metrics':metrics,'artifacts':{str(p.relative_to(OUT)):sha(p) for p in sorted(emitted)}})
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('OUTFIT_ART_BUILD',len(emitted),'real PNG artifacts; 3 painted sources; source seal intact')
    print(json.dumps(metrics,indent=2))

if __name__=='__main__': build()
