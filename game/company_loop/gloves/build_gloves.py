#!/usr/bin/env python3
"""Offline genuine-paint extraction. No calls to renderer or immutable builders."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image,ImageDraw
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[1]
SIZE=(1024,1536)
NAMES=('quilt','mail','brigandine')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def image(p):
    im=Image.open(p);assert im.size==SIZE,(str(p),im.size)
    return im.convert('RGBA')
def ownership(recipe):
    scale=recipe['polygon_supersample'];mask=Image.new('L',(SIZE[0]*scale,SIZE[1]*scale));d=ImageDraw.Draw(mask)
    for poly in recipe['ownership_polygons']:d.polygon([(x*scale,y*scale) for x,y in poly],fill=255)
    return np.where(np.array(mask.resize(SIZE,Image.Resampling.LANCZOS))>=128,255,0).astype(np.uint8)
def extract(source,base,owner):
    # Retain original silhouette alpha. No resize, affine warp, recolor or paint.
    rgb=np.array(source.convert('RGB'))
    b=np.array(base); alpha=(b[:,:,3].astype(np.uint16)*owner.astype(np.uint16)//255).astype(np.uint8)
    f=rgb.astype(np.float32);r,g,bl=f[:,:,0],f[:,:,1],f[:,:,2]
    chroma=(bl>r*.62)&(bl>g*1.3)&(np.minimum(r,bl)-g>35)
    # Own-paint nearest-source transport is limited and recorded, never skin.
    bad=chroma&(alpha>0)
    if np.any(bad):
        yy,xx=np.nonzero(bad); pending=np.ones(len(xx),dtype=bool); maximum=0.0
        for dy,dx in sorted(((dy,dx) for dy in range(-12,13) for dx in range(-12,13) if 0<dx*dx+dy*dy<=144),key=lambda v:(v[0]*v[0]+v[1]*v[1],v)):
            sy=np.clip(yy+dy,0,SIZE[1]-1);sx=np.clip(xx+dx,0,SIZE[0]-1)
            use=pending&~chroma[sy,sx]
            if dx*dx+dy*dy>64:use &= (xx>740)&(yy>630)
            rgb[yy[use],xx[use]]=rgb[sy[use],sx[use]]
            if np.any(use):maximum=max(maximum,float((dx*dx+dy*dy)**.5))
            pending[use]=False
            if not np.any(pending):break
        assert not np.any(pending),('source drift exceeds bounded edge repair',int(pending.sum()))
    else:maximum=0.0
    a=np.dstack((rgb,alpha));a[alpha==0]=0
    return Image.fromarray(a),{'nearest_own_paint_pixels':int(bad.sum()),'maximum_distance_px':maximum,'opaque_rgb_source_exact':int(np.sum((alpha==255)&~bad))}
def validate_protected():
    seal=json.loads((OUT/'protected-inputs.json').read_text())
    for rel,expected in seal.items():
        p=ROOT/rel
        assert p.is_file() and sha(p)==expected, 'protected input changed: '+rel
    return len(seal)
def compose(design=None,weapon=None,shield=None,foundation=None):
    old=ROOT/'sprite_study/assets/characters'
    base=image(foundation or old/'foundation.png')
    glove=None
    if design is not None:
        assert design in NAMES
        a=np.array(base)
        for maskpath in (ROOT/'company_loop/outfits/characters/foundation_keep_mask.png',OUT/'characters/hand_keep_mask.png'):
            k=np.array(image(maskpath))[:,:,3]
            a[:,:,3]=(a[:,:,3].astype(np.uint16)*k.astype(np.uint16)//255).astype(np.uint8)
        base=Image.fromarray(a)
        base.alpha_composite(image(ROOT/f'company_loop/outfits/characters/outfit_{design}.png'))
        glove=image(OUT/f'characters/glove_pair_{design}.png')
        base.alpha_composite(glove) # priority 19
    if weapon is not None:
        assert weapon in ('sword','axe','spear','bow')
        base.alpha_composite(image(old/f'weapon_{weapon}.png')) # priority 20
        grip=image(old/f'grip_{weapon}.png')
        if design is not None:
            assert glove is not None
            foreground=np.array(glove);clip=np.array(grip)[:,:,3]
            foreground[:,:,3]=(foreground[:,:,3].astype(np.uint16)*clip.astype(np.uint16)//255).astype(np.uint8)
            grip=Image.fromarray(foreground)
        base.alpha_composite(grip) # priority 21, ORIGINAL grip alpha only
    if shield is not None:
        assert shield in ('kite','round')
        base.alpha_composite(image(old/f'shield_{shield}.png')) # priority 22
    return base
def build():
    assert OUT.name=='gloves' and OUT.parent.name=='company_loop', 'unsafe output root'
    validate_protected()
    recipe=json.loads((OUT/'recipe.json').read_text());base=image(ROOT/'sprite_study/assets/characters/foundation.png')
    owner=ownership(recipe);a=np.array(base)[:,:,3]
    # Suppress only foundation paint in the new glove footprint. Full suppression
    # at the silhouette avoids stacked edge alpha / resurrected original skin.
    keep=np.where((owner>0)&(a>0),0,255).astype(np.uint8)
    mask=np.full((SIZE[1],SIZE[0],4),255,dtype=np.uint8);mask[:,:,3]=keep
    (OUT/'characters').mkdir(exist_ok=True)
    Image.fromarray(mask).save(OUT/'characters/hand_keep_mask.png')
    stats={}
    for n in NAMES:
        glove,stats[n]=extract(image(OUT/f'sources/{n}-master.png'),base,owner)
        glove.save(OUT/f'characters/glove_pair_{n}.png')
    manifest={'canvas':list(SIZE),'foot_anchor':[512,1490],'builder_sha256':sha(OUT/'build_gloves.py'),'protected_seal_sha256':sha(OUT/'protected-inputs.json'),'recipe_sha256':sha(OUT/'recipe.json'),'source_sha256':{n:sha(OUT/f'sources/{n}-master.png') for n in NAMES},'outputs':{p.name:sha(p) for p in sorted((OUT/'characters').glob('*.png'))},'extraction':stats,'evidence_kind':'offline PNG source extraction; not native gameplay'}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(stats,indent=2))
if __name__=='__main__':build()
