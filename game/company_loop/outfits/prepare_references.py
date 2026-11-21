#!/usr/bin/env python3
"""One-time source seal/reference construction; refuses replacing existing seal."""
from pathlib import Path
import hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
seal=OUT/'protected-inputs.json'
assert not seal.exists(), 'Never regenerate the baseline seal'
protected=[]
for tree in ['sprite_study/assets','company_loop/assets','src']:
    protected.extend(p for p in (ROOT/tree).rglob('*') if p.is_file() and p.suffix not in ['.import','.pyc'] and '__pycache__' not in p.parts)
protected.extend([ROOT/'sprite_study/ART.md',ROOT/'sprite_study/tests/asset_test.py'])
seal.write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(protected)},indent=2)+'\n')
(OUT/'sources').mkdir(parents=True,exist_ok=True)
(OUT/'evidence').mkdir(parents=True,exist_ok=True)
(OUT/'sources/.gdignore').write_text('')
(OUT/'evidence/.gdignore').write_text('')
base=Image.open(ROOT/'sprite_study/assets/characters/foundation.png').convert('RGBA')
for name in ['quilt','mail','brigandine']:
    im=base.copy(); im.alpha_composite(Image.open(ROOT/f'sprite_study/assets/characters/body_{name}.png').convert('RGBA'))
    im.save(OUT/f'sources/reference-{name}.png')
print('SOURCE_SEAL',len(protected),'protected files; exact accepted full-canvas references created')
