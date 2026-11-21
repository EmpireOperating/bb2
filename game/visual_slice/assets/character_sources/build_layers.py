#!/usr/bin/env python3
"""Reproduce transparent paint layers; never modifies generated masters."""
from pathlib import Path
import hashlib, json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "characters"
SIZE = (1024, 1536)
FOOT = (512, 1460)

def key(path):
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
    spill = np.maximum(np.minimum(rgb[:,:,0], rgb[:,:,2])-rgb[:,:,1], 0)
    alpha = 1-spill/255
    alpha[(spill >= 225) | ((rgb[:,:,0] > 210) & (rgb[:,:,2] > 210) & (rgb[:,:,1] < 70))] = 0
    safe = np.maximum(alpha, 1/255)
    rgb[:,:,0] = (rgb[:,:,0] - (1-alpha)*255)/safe
    rgb[:,:,2] = (rgb[:,:,2] - (1-alpha)*255)/safe
    rgb[:,:,1] /= safe
    rgba = np.dstack((np.clip(rgb,0,255),alpha*255)).round().astype(np.uint8)
    rgba[alpha == 0] = 0
    return Image.fromarray(rgba)

def save(name, im):
    assert im.size == SIZE and im.mode == "RGBA"
    im.save(OUT / (name+".png"))


def polygon(points, blur=0.6):
    m=Image.new("L",SIZE,0)
    ImageDraw.Draw(m).polygon(points,fill=255)
    return m.filter(ImageFilter.GaussianBlur(blur)) if blur else m

def masked(im,mask):
    out=im.copy()
    alpha=np.asarray(im.getchannel("A"),dtype=np.float32)*np.asarray(mask,dtype=np.float32)/255
    out.putalpha(Image.fromarray(alpha.round().astype(np.uint8)))
    return out

def fitted(im,source_anchor,target_anchor,scale,angle=0):
    # One rigid whole-object registration. No blade/guard/pommel rearrangement.
    import math
    c,s=math.cos(math.radians(angle)),math.sin(math.radians(angle))
    a,b,d,e=c/scale,s/scale,-s/scale,c/scale
    tx=source_anchor[0]-a*target_anchor[0]-b*target_anchor[1]
    ty=source_anchor[1]-d*target_anchor[0]-e*target_anchor[1]
    return im.transform(SIZE,Image.Transform.AFFINE,(a,b,tx,d,e,ty),resample=Image.Resampling.BICUBIC)

# Cuffs follow cloth, not regenerated skin. Hem follows coat, not legs.
BODY=[(398,222),(435,250),(470,279),(512,308),(537,321),(562,300),(580,261),
      (626,278),(850,300),(850,578),(758,579),(744,583),(710,597),(684,615),
      (675,632),(650,619),(646,661),(746,919),(729,939),(669,951),(610,959),
      (563,963),(541,954),(527,915),(516,956),(471,959),(408,950),(343,941),
      (275,929),(266,916),(337,651),(333,607),(306,608),(289,609),(274,605),
      (251,604),(225,608),(201,621),(181,623),(150,580),(150,300),(388,260)]
NASAL=[(397,20),(621,20),(621,143),(581,143),(583,192),(566,189),
       (558,145),(474,151),(456,160),(451,178),(458,197),(462,216),
       (442,223),(411,218),(404,211),(416,194),(419,168),(397,168)]
KETTLE=[(365,20),(665,20),(665,206),(585,210),(582,145),(557,140),
        (532,145),(491,153),(458,166),(443,180),(437,224),(365,232)]

def equipment(atlas):
    sword=atlas.copy(); m=Image.new("L",atlas.size,0); ImageDraw.Draw(m).rectangle((0,0,340,1024),fill=255)
    sword.putalpha(Image.fromarray((np.asarray(sword.getchannel("A"),dtype=np.uint16)*np.asarray(m)//255).astype(np.uint8)))
    axe=atlas.copy(); m=Image.new("L",atlas.size,0)
    ImageDraw.Draw(m).polygon([(350,0),(638,0),(638,350),(491,350),(491,1024),(350,1024)],fill=255)
    axe.putalpha(Image.fromarray((np.asarray(axe.getchannel("A"),dtype=np.uint16)*np.asarray(m)//255).astype(np.uint8)))
    round_=atlas.copy(); m=Image.new("L",atlas.size,0)
    ImageDraw.Draw(m).polygon([(840,170),(1105,170),(1105,900),(575,900),(575,385),(630,310),(690,240)],fill=255)
    round_.putalpha(Image.fromarray((np.asarray(round_.getchannel("A"),dtype=np.uint16)*np.asarray(m)//255).astype(np.uint8)))
    kite=atlas.copy(); m=Image.new("L",atlas.size,0); ImageDraw.Draw(m).rectangle((1110,0,1536,1024),fill=255)
    kite.putalpha(Image.fromarray((np.asarray(kite.getchannel("A"),dtype=np.uint16)*np.asarray(m)//255).astype(np.uint8)))
    return {"weapon_sword":fitted(sword,(180,165),(267,786),0.68,14),
            "weapon_axe":fitted(axe,(430,530),(267,786),0.72,-18),
            "weapon_dagger":fitted(sword,(180,165),(267,786),0.40,14),
            "shield_round":fitted(round_,(900,520),(795,813),0.58),
            "shield_buckler":fitted(round_,(900,520),(779,802),0.35),
            "shield_kite":fitted(kite,(1320,430),(785,790),0.68)}

def offline_sheet(layers):
    profiles=[("Ordinary clothes - NO equipment",["foundation"]),
              ("Mail / nasal / sword / kite",["foundation_helmet","body_quilt","body_mail","head_nasal","weapon_sword","grip_sword","shield_kite"]),
              ("Brigandine / kettle / axe / round",["foundation_helmet","body_quilt","body_brigandine","head_kettle","weapon_axe","grip_axe","shield_round"]),
              ("Linen-family / bare head / sword",["foundation","body_quilt","weapon_sword","grip_sword"])]
    sheet=Image.new("RGB",(1440,720),(38,40,41)); draw=ImageDraw.Draw(sheet)
    draw.text((20,12),"OFFLINE PAINTED ASSET COMPOSITES - NOT A GAMEPLAY SCREENSHOT",fill="white")
    for i,(label,names) in enumerate(profiles):
        background=Image.new("RGBA",SIZE)
        d=ImageDraw.Draw(background)
        for y in range(0,SIZE[1],64):
            for x in range(0,SIZE[0],64): d.rectangle((x,y,x+63,y+63), fill=(168,166,159,255) if (x//64+y//64)%2 else (199,197,189,255))
        for name in names: background.alpha_composite(layers[name])
        sheet.paste(background.resize((350,525),Image.Resampling.LANCZOS).convert("RGB"),(i*360,66))
        draw.text((i*360+6,42),label,fill="white")
        tactical=Image.new("RGBA",SIZE,(67,71,64,255))
        for name in names: tactical.alpha_composite(layers[name])
        sheet.paste(tactical.resize((65,98),Image.Resampling.LANCZOS).convert("RGB"),(i*360+145,604))
    sheet.save(HERE/"offline-character-sheet.png")
    # Enlarged, opposing-light background helmet/cuff views are asset evidence only.
    details=Image.new("RGB",(1200,840),(220,217,204))
    for i,names in enumerate([profiles[1][1],profiles[2][1]]):
        composite=Image.new("RGBA",SIZE,(220,217,204,255))
        for name in names: composite.alpha_composite(layers[name])
        details.paste(composite.crop((360,20,660,320)).resize((600,600)),(i*600,0))
        details.paste(composite.crop((160,560,350,900)).resize((130,230)),(i*600,605))
        details.paste(composite.crop((640,560,830,900)).resize((130,230)),(i*600+150,605))
    details.save(HERE/"offline-joins.png")

def build():
    OUT.mkdir(parents=True,exist_ok=True)
    base=key(HERE.parent/"sources/base-mercenary.png")
    layers={"foundation":base}
    # Remove only original crown/hair while a physical helmet is equipped.
    # The original exposed face/ears/neck remain byte-identical.
    hair=polygon([(400,20),(625,20),(625,159),(583,159),(579,143),
                  (569,137),(558,134),(545,140),(533,128),(521,121),
                  (509,121),(498,116),(481,118),(469,132),(458,142),
                  (450,155),(442,174),(411,178),(400,150)],0.4)
    keep=Image.fromarray(255-np.asarray(hair))
    layers["foundation_helmet"]=masked(base,keep)
    mail=key(HERE.parent/"sources/mail-mercenary.png")
    brig=key(HERE/"brigandine-master.png")
    for name,im in [("body_quilt",base),("body_mail",mail),("body_brigandine",brig)]:
        layers[name]=masked(im,polygon(BODY))
    layers["head_nasal"]=masked(mail,polygon(NASAL))
    layers["head_kettle"]=masked(brig,polygon(KETTLE))
    layers["head_cap"]=layers["head_nasal"].copy()
    cap=np.asarray(layers["head_cap"]).copy(); cap[165:200,560:590,3]=0
    layers["head_cap"]=Image.fromarray(cap)
    layers["body_shoulders"]=masked(mail,polygon([(250,290),(385,260),(431,308),(412,364),(332,447),(233,432)]))
    layers["body_collar"]=masked(mail,polygon([(389,253),(440,261),(480,300),(536,323),(574,285),(618,286),(625,342),(576,372),(442,350),(387,310)]))
    layers.update(equipment(key(HERE/"equipment-master.png")))
    hand_mask=polygon([(195,717),(277,708),(317,748),(326,805),(309,858),(232,860),(200,814)],0.4)
    for family in ["sword","axe","dagger"]:
        support=np.asarray(layers["weapon_"+family].getchannel("A")) > 24
        grip=masked(base,hand_mask)
        alpha=np.asarray(grip.getchannel("A"))*support
        grip.putalpha(Image.fromarray(alpha.astype(np.uint8)))
        layers["grip_"+family]=grip
    for name,im in layers.items(): save(name,im)
    offline_sheet(layers)
    manifest={"canvas":SIZE,"foot_anchor":FOOT,"pixel_size":0.00129,"layers":{}}
    for name,im in layers.items():
        a=np.asarray(im)[:,:,3]
        assert not np.any(a[0]) and not np.any(a[-1]) and not np.any(a[:,0]) and not np.any(a[:,-1]),name
        assert np.any(a>240),name
        manifest["layers"][name]={"sha256":hashlib.sha256((OUT/(name+".png")).read_bytes()).hexdigest(),"bbox":im.getbbox(),"opaque_pixels":int(np.count_nonzero(a>240))}
    for family in ["mail","brigandine"]:
        a=np.asarray(layers["body_"+family])[:,:,3]
        assert a[206,532] == a[791,253] == a[777,757] == a[1425,310] == 0
    manifest["sources"]={str(p.relative_to(HERE.parent)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [HERE.parent/"sources/base-mercenary.png",HERE.parent/"sources/mail-mercenary.png",HERE/"brigandine-master.png",HERE/"equipment-master.png"]}
    (HERE/"layer-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print("PAINTED_LAYERS:",len(layers),"transparent PNGs; source, bounds and anatomy witnesses verified")

if __name__ == "__main__": build()
