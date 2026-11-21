#!/usr/bin/env python3
"""Rebuild bounded head edits only. Immutable accepted layers are read-only."""
from pathlib import Path
import argparse, hashlib, json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
ROOT = Path(__file__).resolve().parents[2]
ASSETS = Path(__file__).resolve().parent
FROZEN = ROOT / "sprite_study/assets/characters"
CANVAS = (1024, 1536)
HEAD = [(462,20),(720,20),(720,272),(680,297),(624,307),(582,292),(548,275),(529,250),(506,232),(484,223),(463,204)]

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def build(out):
    assert out != ROOT and not out.is_relative_to(ROOT / "sprite_study"), "Frozen inputs are not an output root"
    assert not out.is_relative_to(ASSETS / "sources"), "Raw sources are not an output root"
    expected = json.loads((ASSETS / "sources/protected-inputs.json").read_text())
    assert all(sha(ROOT / name) == digest for name, digest in expected.items()), "Protected input drift"
    out.mkdir(parents=True, exist_ok=True)
    base = Image.open(FROZEN / "foundation.png").convert("RGBA")
    helmet = Image.open(FROZEN / "foundation_helmet.png").convert("RGBA")
    region = Image.new("L", CANVAS)
    ImageDraw.Draw(region).polygon(HEAD, fill=255)
    # Feather only the internal head/neck join; outside this region stays byte-exact.
    soft = region.filter(ImageFilter.GaussianBlur(1.1))
    mask = np.asarray(soft).copy()
    mask[np.asarray(region) == 0] = 0
    region = Image.fromarray(mask)
    outputs = []
    variants = [base]
    helmet_variants = [helmet]
    for name in ["copper", "silver"]:
        source = Image.open(ASSETS / "sources" / (name + "-master.png")).convert("RGBA")
        rgb = np.asarray(source).copy()
        # Chroma-key only the generated magenta backdrop; source paint retained.
        backdrop = (rgb[:,:,0] > 150) & (rgb[:,:,2] > 150) & (rgb[:,:,1] < 100)
        rgb[backdrop] = 0
        cut = Image.fromarray(rgb).resize((280,320),Image.Resampling.LANCZOS)
        layer = Image.new("RGBA", CANVAS)
        layer.paste(cut,(440,20))
        result = Image.composite(layer,base,region)
        # Contextual crown suppression is exactly the accepted helmet foundation
        # alpha boundary, so neither new hair nor scalp can protrude beyond it.
        arr = np.asarray(result).copy()
        original_alpha = np.asarray(helmet)[:,:,3]
        arr[:,:,3] = np.minimum(arr[:,:,3],original_alpha)
        covered = Image.fromarray(arr)
        # Outside edited head preserve every original helmet foundation byte.
        covered = Image.composite(covered,helmet,Image.fromarray((mask>0).astype("uint8")*255))
        for suffix,img in [("",result),("_helmet",covered)]:
            p = out / ("foundation_"+name+suffix+".png")
            img.save(p)
            outputs.append(p)
        variants.append(result); helmet_variants.append(covered)
    sheet = Image.new("RGB", (1200,1260), "#ded9cb")
    draw = ImageDraw.Draw(sheet)
    for col,(name,bare,hatted) in enumerate(zip(["Brown / original", "Copper / moustache", "Silver / bald beard"],variants,helmet_variants)):
        x = col*400
        draw.text((x+15,12),name,fill="#302e29")
        sheet.paste(bare.crop((450,20,730,320)).resize((336,360)),(x+25,40),bare.crop((450,20,730,320)).resize((336,360)))
        for row,hat in enumerate(["head_nasal","head_kettle"]):
            composed = Image.alpha_composite(hatted,Image.open(FROZEN/(hat+".png")).convert("RGBA"))
            crop = composed.crop((380,0,810,330)).resize((387,297))
            sheet.paste(crop,(x+5,420+row*300),crop)
        dressed = bare.copy()
        for asset in ["body_mail","weapon_sword","grip_sword","shield_round"]:
            dressed = Image.alpha_composite(dressed,Image.open(FROZEN/(asset+".png")).convert("RGBA"))
        nominal = dressed.resize((128,192),Image.Resampling.LANCZOS)
        sheet.paste(nominal,(x+130,1050),nominal)
    sheet.save(out / "identity-sheet.png")
    outputs.append(out / "identity-sheet.png")
    manifest = {"canvas":list(CANVAS),"foot":[512,1490],"identities":["original","copper","silver"],"source_crop":[440,20,720,340],"source_reference_resize":[840,960],"generated_registration":{"resize":[280,320],"paste":[440,20],"resampling":"Pillow LANCZOS"},"head_polygon":HEAD,"join_feather_radius":1.1,"helmet_alpha":"min(identity alpha, accepted foundation_helmet alpha); exact accepted outside head mask","inputs":{str(p.relative_to(ROOT)):sha(p) for p in [*sorted(FROZEN.glob("*.png")),ROOT/"sprite_study/assets/sources/base-master.png",*sorted((ASSETS/"sources").glob("*.png"))]},"outputs":{p.name:sha(p) for p in outputs},"limits":"Head-only registered source edits; shared original body and original equipment. Offline sheet is not native renderer acceptance."}
    (out / "manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print(json.dumps({"output":str(out),"outputs":manifest["outputs"]},indent=2))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,default=ASSETS/"characters")
    build(parser.parse_args().output.resolve())
