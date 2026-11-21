#!/usr/bin/env python3
"""Two complete rebuilds, cold-root reproduction, real corruption negatives."""
from pathlib import Path
import argparse,hashlib,json,os,shutil,subprocess,sys
import numpy as np
from PIL import Image
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(dest):
    dest=dest.resolve();dest.mkdir(parents=True,exist_ok=False)
    (dest/'.gdignore').write_text('')
    report={'complete':False,'evidence_kind':'offline source PNG / unittest only; native engine pending'}
    (dest/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
    def run(root,args,label,expected=0):
        p=subprocess.run([sys.executable]+args,cwd=root,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
        (dest/(label+'.log')).write_text(p.stdout)
        if expected==0:assert p.returncode==0,(label,p.returncode,p.stdout)
        else:assert p.returncode!=0 and 'FAILED' in p.stdout,(label,'corruption not rejected',p.stdout)
        return {'exit':p.returncode,'log':label+'.log','sha256':sha(dest/(label+'.log'))}
    def inventory(root):
        o=root/'company_loop/gloves'
        files=list((o/'characters').glob('*.png'))+[o/'manifest.json']+list((o/'evidence/review').glob('*.png'))+[o/'evidence/review/manifest.json']
        return {str(p.relative_to(o)):sha(p) for p in sorted(files)}
    builds=[]
    for i in (1,2):
        run(ROOT,['company_loop/gloves/build_gloves.py'],f'build-{i}')
        run(ROOT,['company_loop/gloves/render_review.py'],f'review-{i}')
        builds.append(inventory(ROOT))
        (dest/f'build-{i}-inventory.json').write_text(json.dumps(builds[-1],indent=2)+'\n')
    assert builds[0]==builds[1],'two final complete rebuilds differ'
    report['reproducible_files']=len(builds[0]);report['two_builds_exact']=True
    report['unittest']=run(ROOT,['company_loop/tests/glove_assets_test.py'],'glove-unittest')
    report['inherited_assets']=run(ROOT,['sprite_study/tests/asset_test.py'],'inherited-assets')
    # Independent writable evidence copy; no original source is ever mutated.
    cold=dest/'cold-project';cold.mkdir()
    seal=json.loads((OUT/'protected-inputs.json').read_text())
    for rel in seal:
        p=cold/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/rel,p)
    shutil.copytree(OUT,cold/'company_loop/gloves',ignore=shutil.ignore_patterns('__pycache__'))
    test=cold/'company_loop/tests/glove_assets_test.py';test.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/'company_loop/tests/glove_assets_test.py',test)
    run(cold,['company_loop/gloves/build_gloves.py'],'cold-build')
    run(cold,['company_loop/gloves/render_review.py'],'cold-review')
    assert inventory(cold)==builds[0],'independent cold root differs'
    report['cold_root_exact']=True
    probe_specs=[
      ('paint-rgb','company_loop/gloves/characters/glove_pair_quilt.png',(140,570,0),'GloveAssetsTest.test_source_rgb_is_genuine_and_clean'),
      ('finger-alpha','company_loop/gloves/characters/glove_pair_mail.png',(140,570,3),'GloveAssetsTest.test_alpha_coverage_and_source_bound_mask'),
      ('mask-face','company_loop/gloves/characters/hand_keep_mask.png',(580,180,3),'GloveAssetsTest.test_alpha_coverage_and_source_bound_mask'),
      ('protected-foundation','sprite_study/assets/characters/foundation.png',(140,570,0),'GloveAssetsTest.test_protected_source_validator'),
      ('oversize-cuff','company_loop/gloves/characters/glove_pair_brigandine.png',(500,800,3),'GloveAssetsTest.test_alpha_coverage_and_source_bound_mask')]
    report['corruption_probes']={}
    for label,rel,(x,y,c),case in probe_specs:
        p=cold/rel;original=p.read_bytes()
        try:
            with Image.open(p) as im:a=np.array(im.convert('RGBA'))
            a[y,x,c]=int(a[y,x,c])^255;Image.fromarray(a).save(p)
            report['corruption_probes'][label]=run(cold,['company_loop/tests/glove_assets_test.py',case],'red-'+label,expected=1)
        finally:p.write_bytes(original)
    # Missing and undecodable mandatory source cannot be accepted as stale art.
    p=cold/'company_loop/gloves/characters/glove_pair_quilt.png';original=p.read_bytes()
    try:
        p.unlink();report['corruption_probes']['missing']=run(cold,['company_loop/tests/glove_assets_test.py','GloveAssetsTest.test_required_paired_layers_and_mask'],'red-missing',expected=1)
        p.write_bytes(b'not a PNG');report['corruption_probes']['undecodable']=run(cold,['company_loop/tests/glove_assets_test.py','GloveAssetsTest.test_required_paired_layers_and_mask'],'red-undecodable',expected=1)
    finally:p.write_bytes(original)
    report['restored_cold_unittest']=run(cold,['company_loop/tests/glove_assets_test.py'],'green-cold-restored')
    assert inventory(cold)==builds[0],'negative probes not restored'
    for rel,digest in seal.items():assert sha(ROOT/rel)==digest,'original input changed: '+rel
    report['protected_files_unchanged']=len(seal);report['complete']=True
    report['source_bindings']={str(p.relative_to(OUT)):sha(p) for p in [OUT/'build_gloves.py',OUT/'render_review.py',OUT/'verify_gloves.py',OUT/'recipe.json',OUT/'manifest.json',OUT/'sources/generation-tool-receipts.json']}
    report['test_sha256']=sha(ROOT/'company_loop/tests/glove_assets_test.py')
    (dest/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--output',required=True,type=Path);verify(ap.parse_args().output)
