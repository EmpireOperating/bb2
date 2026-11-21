#!/usr/bin/env python3
"""Local derivative, never new skeleton painting. Run from source; no source writes.
Requires existing Pillow only. Exact RGB-only warm skin qualification in bounded
face/neck/forearm polygons. Clothes, hair darks, alpha, canvas and toes unchanged.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import hashlib,json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
POLYGONS=[[(486,150),(555,104),(654,108),(681,205),(647,281),(579,323),(533,361),(475,316),(468,240)],[(213,437),(257,451),(307,495),(283,544),(256,500)],[(790,502),(842,509),(879,557),(861,625),(825,650),(822,591)]]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 rows=[]
 for name in ['foundation','foundation_helmet','foundation_copper','foundation_copper_helmet','foundation_silver','foundation_silver_helmet']:
  origin=ROOT/('sprite_study/assets/characters' if name in ['foundation','foundation_helmet'] else 'company_loop/assets/characters')/(name+'.png')
  image=Image.open(origin).convert('RGBA'); mask=Image.new('L',image.size);draw=ImageDraw.Draw(mask)
  for poly in POLYGONS:draw.polygon(poly,fill=255)
  data=bytearray(image.tobytes()); support=mask.tobytes();changed=0
  for i,m in enumerate(support):
   if not m:continue
   j=i*4;r,g,b,a=data[j:j+4]
   if not a or r-g<12 or r-b<20:continue
   gray=.299*r+.587*g+.114*b
   rgb=[round(.15*r+.85*gray*.91),round(.15*g+.85*gray*1.06),round(.15*b+.85*gray*1.02)]
   rgb=[min(255,max(0,v)) for v in rgb]
   if list(data[j:j+3]) != rgb:changed+=1
   data[j:j+3]=bytes(rgb)
  out=HERE/('burial_'+name+'.png');Image.frombytes('RGBA',image.size,bytes(data)).save(out)
  rows.append(dict(source=origin.relative_to(ROOT).as_posix(),source_sha256=sha(origin),output=out.name,output_sha256=sha(out),changed_rgb_pixels=changed,alpha_exact=True))
 manifest={'recipe':'foundation_skin_pallor_v1','recipe_sha256':sha(Path(__file__)),'rights':'Derivative of sealed in-project painted foundation; originals immutable. Locally processed; no service/provider spend. Not newly painted skull anatomy.','canvas':[1024,1536],'foot':[512,1490],'polygons':POLYGONS,'rows':rows}
 (HERE/'provenance.json').write_text(json.dumps(manifest,indent=2,sort_keys=True)+'\n')
 print(json.dumps(manifest))
if __name__=='__main__':main()
