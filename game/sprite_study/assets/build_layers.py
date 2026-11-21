#!/usr/bin/env python3
"""Deterministic, offline, source-preserving braced-sprite asset compiler."""
from pathlib import Path
import hashlib, json, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
HERE = Path(__file__).resolve().parent
SOURCES = HERE / 'sources'
OUT = HERE / 'characters'
EVIDENCE = HERE / 'evidence'
SIZE = (1024,1536)
FOOT = (512,1490)

def key(path):
    rgb = np.asarray(Image.open(path).convert('RGB'),dtype=np.float32)
    r,g,b = rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    spill = np.maximum(np.minimum(r,b)-g,0)
    chroma = (b > r*.62) & (b > g*1.3) & (spill > 35)
    alpha = np.ones(r.shape,dtype=np.float32)
    alpha[chroma] = 1 - spill[chroma]/np.maximum(255-g[chroma],1)
    alpha[(alpha<.10) | (chroma & (np.minimum(r,b)>180) & (g<80))] = 0
    # Only chroma edges are unmatted; all interior accepted RGB is unchanged.
    safe = np.maximum(alpha,1/255)
    for c in (0,2): rgb[:,:,c][chroma] = (rgb[:,:,c][chroma]-(1-alpha[chroma])*255)/safe[chroma]
    rgb[:,:,1][chroma] /= safe[chroma]
    rgba = np.dstack((np.clip(rgb,0,255),alpha*255)).round().astype(np.uint8)
    rgba[alpha==0] = 0
    return Image.fromarray(rgba)

def polygon(points, size=SIZE, feather=.45):
    m=Image.new('L',size,0)
    ImageDraw.Draw(m).polygon([tuple(v) for v in points],fill=255)
    return m.filter(ImageFilter.GaussianBlur(feather)) if feather else m

def masked(image, mask):
    a=np.asarray(image).copy()
    a[:,:,3]=(a[:,:,3].astype(np.uint16)*np.asarray(mask).astype(np.uint16)//255).astype(np.uint8)
    a[a[:,:,3]==0]=0
    return Image.fromarray(a)

def fitted(image, spec):
    # Whole rigid item transform; never independently move blade, guard or pommel.
    source=Image.new('RGBA',image.size)
    box=tuple(spec['crop']); source.paste(image.crop(box),box[:2])
    angle=math.radians(spec['angle']); c,s=math.cos(angle),math.sin(angle)
    scale=spec['scale']; flip=-1 if spec.get('mirror') else 1
    a,b,d,e=flip*c/scale,flip*s/scale,-s/scale,c/scale
    sx,sy=spec['anchor']; tx,ty=spec['target']
    return source.transform(SIZE,Image.Transform.AFFINE,(a,b,sx-a*tx-b*ty,d,e,sy-d*tx-e*ty),resample=Image.Resampling.BICUBIC)

def compose(layers,names):
    im=layers[names[0]].copy()
    for name in names[1:]: im.alpha_composite(layers[name])
    return im

def make_evidence(layers):
    font=ImageFont.truetype('/usr/share/fonts/ttf-ia-writer/iAWriterQuattroS-Regular.ttf',18)
    small=ImageFont.truetype('/usr/share/fonts/ttf-ia-writer/iAWriterQuattroS-Regular.ttf',14)
    profiles=[('Ordinary clothes / no gear',['foundation']),
              ('Mail / nasal / sword / kite',['foundation_helmet','body_mail','head_nasal','weapon_sword','grip_sword','shield_kite']),
              ('Brigandine / kettle / axe / round',['foundation_helmet','body_brigandine','head_kettle','weapon_axe','grip_axe','shield_round']),
              ('Linen / bare head / sword',['foundation','body_quilt','weapon_sword','grip_sword']),
              ('Linen / bow carry (not aiming)',['foundation','body_quilt','weapon_bow','grip_bow']),
              ('Mail / nasal / spear carry',['foundation_helmet','body_mail','head_nasal','weapon_spear','grip_spear'])]
    sheet=Image.new('RGB',(1800,1100),(27,31,35)); draw=ImageDraw.Draw(sheet)
    draw.text((20,14),'OFFLINE ASSET COMPOSITES — source pixels, not engine / gameplay evidence',font=font,fill='white')
    draw.text((20,44),'Menu: 430px full canvas. Tactical: EXACT 90px and 120px full canvas, no enlargement. Foot anchor 512,1490.',font=small,fill=(203,211,220))
    backgrounds=[(205,207,199),(54,61,56)]
    for i,(label,names) in enumerate(profiles):
        im=compose(layers,names); im.save(EVIDENCE/('composite-'+str(i)+'.png'))
        x=i*300
        draw.text((x+7,80),label,font=small,fill=(236,225,199))
        for height,yy in [(430,114),(120,615),(90,825)]:
            thumb=im.resize((round(SIZE[0]*height/SIZE[1]),height),Image.Resampling.LANCZOS)
            for j,bg in enumerate(backgrounds if height!=430 else backgrounds[:1]):
                xpos=x+(7 if height==430 else 31+j*140)
                canvas=Image.new('RGBA',thumb.size,bg+(255,)); canvas.alpha_composite(thumb)
                sheet.paste(canvas.convert('RGB'),(xpos,yy))
            draw.text((x+7,yy+height+9),f'{height}px / '+('menu' if height==430 else 'actual tactical canvas'),font=small,fill=(216,222,224))
    sheet.save(EVIDENCE/'offline-readability-sheet.png')
    joins=Image.new('RGB',(1800,1060),(219,220,212)); d=ImageDraw.Draw(joins)
    for i,(label,names) in enumerate(profiles[:4]):
        x=i*450; im=compose(layers,names)
        d.text((x+8,8),label,font=small,fill=(24,26,30))
        for box,dest,size in [((390,0,810,350),(x+10,35),(420,350)),((70,410,330,665),(x+10,410),(364,357)),((600,460,920,670),(x+10,795),(420,255))]:
            cut=im.crop(box).resize(size,Image.Resampling.LANCZOS)
            back=Image.new('RGBA',size,(219,220,212,255)); back.alpha_composite(cut)
            joins.paste(back.convert('RGB'),dest)
    joins.save(EVIDENCE/'offline-joins.png')
    # Isolated slots make ownership and real transparency visibly inspectable.
    slots=[n for n in layers if not n.startswith('foundation') and not n.startswith('grip')]
    isolated=Image.new('RGB',(1800,800),(213,213,205)); d=ImageDraw.Draw(isolated)
    for i,name in enumerate(slots):
        x=(i%8)*225; y=(i//8)*400
        d.text((x+5,y+5),name,font=small,fill=(25,28,31))
        im=layers[name].resize((220,330),Image.Resampling.LANCZOS)
        back=Image.new('RGBA',im.size,(213,213,205,255)); back.alpha_composite(im)
        isolated.paste(back.convert('RGB'),(x,y+30))
    isolated.save(EVIDENCE/'isolated-layers.png')
    removal=Image.new('RGB',(1320,650),(214,218,213)); rd=ImageDraw.Draw(removal)
    current=[('Mail: helmet worn',['foundation_helmet','body_mail','head_nasal']),('Mail: helmet REMOVED',['foundation','body_mail']),('Brigandine: helmet worn',['foundation_helmet','body_brigandine','head_kettle']),('Brigandine: helmet REMOVED',['foundation','body_brigandine'])]
    for i,(label,names) in enumerate(current):
        im=compose(layers,names); x=i*330
        rd.text((x+5,10),label,font=small,fill=(20,25,29))
        cut=im.crop((390,0,810,360)).resize((320,274),Image.Resampling.LANCZOS)
        back=Image.new('RGBA',cut.size,(214,218,213,255)); back.alpha_composite(cut)
        removal.paste(back.convert('RGB'),(x+5,40))
        cut=im.crop((590,450,930,670)).resize((320,207),Image.Resampling.LANCZOS)
        back=Image.new('RGBA',cut.size,(214,218,213,255)); back.alpha_composite(cut)
        removal.paste(back.convert('RGB'),(x+5,335))
    rd.text((10,580),'CURRENT JOIN REVISION: original face / fists retained; no donor-wrist crescent. Removal restores accepted hair.',font=small,fill=(20,25,29))
    removal.save(EVIDENCE/'removal-and-joins-final.png')


def build():
    OUT.mkdir(parents=True,exist_ok=True); EVIDENCE.mkdir(parents=True,exist_ok=True)
    recipe=json.loads((HERE/'extraction-recipe.json').read_text())
    base=key(SOURCES/'base-master.png')
    layers={'foundation':base}
    crown=polygon(recipe['crown'],feather=0)
    keep=Image.fromarray(255-np.asarray(crown))
    layers['foundation_helmet']=masked(base,keep)
    # Source-paint cutouts, new-pose curves. No legacy extraction masks reused.
    hands=np.maximum(np.asarray(polygon(recipe['left_arm'],feather=0)),np.asarray(polygon(recipe['right_arm'],feather=0)))
    for name,file,outline in [('body_quilt','base-master.png','quilt_outer'),('body_mail','mail-master.png','body_outer'),('body_brigandine','brigandine-master.png','body_outer')]:
        source=key(SOURCES/file)
        mask=np.asarray(polygon(recipe[outline])).copy(); mask[hands>0]=0
        if name!='body_quilt':
            donor_arm=np.asarray(polygon(recipe['donor_right_arm'],feather=0))
            expanded_hands=np.asarray(Image.fromarray(hands).filter(ImageFilter.MaxFilter(11)))
            mask[(donor_arm>0) | (expanded_hands>0)]=0
        garment=masked(source,Image.fromarray(mask))
        if name=='body_quilt':
            a=np.asarray(garment).copy(); rgb=a[:,:,:3].astype(float)
            # New ordinary linen-family presentation from accepted base cloth folds.
            # Preserve the belt, which belongs to the base garment rather than armor.
            cloth=np.asarray(polygon([[200,200],[900,200],[920,540],[690,590],[420,585],[200,545]],feather=0))>0
            cloth |= np.asarray(polygon([[250,680],[383,639],[453,677],[503,687],[556,831],[592,816],[554,663],[688,649],[828,868],[510,915],[248,805]],feather=0))>0
            bright=np.clip(rgb*np.array([1.45,1.53,1.58])+np.array([22,25,24]),0,255)
            a[:,:,:3][cloth]=bright[cloth].round().astype(np.uint8)
            a[a[:,:,3]==0]=0; garment=Image.fromarray(a)
        layers[name]=garment
    layers['head_nasal']=masked(key(SOURCES/'mail-master.png'),polygon(recipe['nasal']))
    layers['head_kettle']=masked(key(SOURCES/'brigandine-master.png'),polygon(recipe['kettle']))
    atlas=key(SOURCES/'equipment-master.png')
    for name,spec in recipe['objects'].items(): layers[name]=fitted(atlas,spec)
    hand=np.asarray(polygon(recipe['grip'],feather=0))>0
    for family in ['sword','axe','spear','bow']:
        support=np.asarray(layers['weapon_'+family])[:,:,3]>0
        a=np.asarray(base).copy(); a[~(hand & support)]=0
        layers['grip_'+family]=Image.fromarray(a)
    for name,im in layers.items(): im.save(OUT/(name+'.png'))
    make_evidence(layers)
    manifest={k:recipe[k] for k in ['canvas','foot_anchor','pixel_size','layer_order','unsupported_families','diagnostics']}
    manifest['status']='exploratory offline art; no engine acceptance claimed'
    manifest['sources']={str(q.relative_to(HERE)):hashlib.sha256(q.read_bytes()).hexdigest() for q in sorted(SOURCES.iterdir()) if q.is_file() and q.name!='.gdignore'}
    manifest['recipe_sha256']=hashlib.sha256((HERE/'extraction-recipe.json').read_bytes()).hexdigest()
    manifest['builder_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    manifest['layers']={}
    for name,im in layers.items():
        a=np.asarray(im)[:,:,3]
        manifest['layers'][name]={'sha256':hashlib.sha256((OUT/(name+'.png')).read_bytes()).hexdigest(),'bbox':im.getbbox(),'visible_pixels':int(np.count_nonzero(a)),'opaque_pixels':int(np.count_nonzero(a>240)),'opaque_fraction_of_visible':float(np.count_nonzero(a>240)/max(np.count_nonzero(a),1))}
    proof_names=['composite-'+str(i)+'.png' for i in range(6)]+['offline-readability-sheet.png','offline-joins.png','isolated-layers.png','removal-and-joins-final.png']
    manifest['proofs']={name:hashlib.sha256((EVIDENCE/name).read_bytes()).hexdigest() for name in proof_names}
    manifest['supported_families']={'body':['quilt (linen-family visual)','mail','brigandine'],'head':['nasal','kettle'],'weapon':['sword','axe','spear','bow'],'shield':['kite','round']}
    (HERE/'asset-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('BRACED_SPRITE_ASSETS',len(layers),'PNG layers; exact base, source-bound cutouts, 90/120px evidence')

if __name__ == '__main__': build()
