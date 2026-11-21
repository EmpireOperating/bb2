#!/usr/bin/env python3
"""Independent whole-pixel/alpha/source-seal checks for bounded identity art."""
from pathlib import Path
import argparse,hashlib,json
import numpy as np
from PIL import Image,ImageDraw
ROOT = Path(__file__).resolve().parents[2]
ASSETS = Path(__file__).resolve().parent

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def verify(out):
    manifest = json.loads((out / "manifest.json").read_text())
    sealed = json.loads((ASSETS / "sources/protected-inputs.json").read_text())
    assert all(sha(ROOT/p)==h for p,h in sealed.items()), "Protected base/equipment byte drift"
    assert all(sha(ROOT/p)==h for p,h in manifest["inputs"].items()), "Retained source drift"
    assert all(sha(out/p)==h for p,h in manifest["outputs"].items()), "Output differs from recipe manifest"
    assert manifest["canvas"] == [1024,1536] and manifest["foot"] == [512,1490]
    mask = Image.new("L", (1024,1536)); ImageDraw.Draw(mask).polygon([tuple(p) for p in manifest["head_polygon"]],fill=255)
    outside = np.asarray(mask)==0
    fixed = ROOT / "sprite_study/assets/characters"
    originals = {s:np.asarray(Image.open(fixed/("foundation"+s+".png")).convert("RGBA")) for s in ["","_helmet"]}
    stats=[]
    for identity in ["copper","silver"]:
        for suffix in ["","_helmet"]:
            name = "foundation_"+identity+suffix+".png"
            im=Image.open(out/name)
            assert im.mode=="RGBA" and im.size==(1024,1536),name
            arr=np.asarray(im); original=originals[suffix]
            assert np.array_equal(arr[outside],original[outside]), "Changed protected non-head RGBA: "+name
            assert np.array_equal(arr[320:],original[320:]), "Changed body/hand/feet: "+name
            if suffix:
                assert np.all(arr[:,:,3]<=original[:,:,3]), "Identity protrudes beyond accepted helmet-context head: "+name
            changed=int(np.any(arr != original,axis=2).sum())
            assert changed > 1000, "Identity missing"
            assert not np.any((arr[:,:,0]>180)&(arr[:,:,2]>180)&(arr[:,:,1]<60)&(arr[:,:,3]>128)), "Opaque magenta background leak"
            stats.append({"file":name,"changed_head_pixels":changed,"outside_head_exact":True,"body_fists_feet_exact":True})
    return {"ok":True,"protected_files":len(sealed),"variants":stats,"outputs":manifest["outputs"],"scope":"offline decoded pixels only; native API geometry in Godot suite, GUI acceptance separate"}

if __name__=="__main__":
    ap=argparse.ArgumentParser(); ap.add_argument("--output",type=Path,default=ASSETS/"characters")
    print(json.dumps(verify(ap.parse_args().output.resolve()),indent=2))
