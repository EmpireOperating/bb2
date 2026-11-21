#!/usr/bin/env python3
"""Real two-run/cold-root/negative/native-Image verification; no GUI or git writes."""
from pathlib import Path
from typing import Any
import argparse,hashlib,json,os,shutil,subprocess,sys
import numpy as np
from PIL import Image
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
ENGINE=Path('/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64')

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);args=p.parse_args()
    evidence=args.output.resolve()
    assert evidence!=ROOT and not evidence.is_relative_to(ROOT/'sprite_study'), 'Unsafe evidence path'
    evidence.mkdir(parents=True,exist_ok=False)
    (evidence/'.gdignore').write_text('')
    report: dict[str,Any]={'verifier_sha256':digest(Path(__file__)), 'native_check_sha256':digest(HERE/'native_image_check.gd'), 'status':'incomplete','builder_sha256':digest(HERE/'build_outfits.py'),'recipe_sha256':digest(HERE/'recipe.json'),'tests_sha256':digest(ROOT/'company_loop/tests/outfit_assets_test.py'),'claims':'Offline extraction and native Godot Image math only; not gameplay, GUI, GPU, resolver or gloves.'}
    def save_report(): (evidence/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
    save_report()
    def run(name,command,root=ROOT,env=None,expected=0,marker=None):
        result=subprocess.run(command,cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
        (evidence/(name+'.log')).write_text(result.stdout)
        assert result.returncode==expected,(name,result.returncode,result.stdout)
        if marker: assert marker in result.stdout,(name,'missing marker')
        return result.stdout
    inventories=[]
    for i in (1,2):
        run('rebuild-'+str(i),[sys.executable,str(HERE/'build_outfits.py')])
        manifest=json.loads((HERE/'manifest.json').read_text())
        actual={name:digest(HERE/name) for name in manifest['artifacts']}
        actual['manifest.json']=digest(HERE/'manifest.json')
        inventories.append(actual)
        (evidence/f'rebuild-{i}-hashes.json').write_text(json.dumps(actual,indent=2)+'\n')
    assert inventories[0]==inventories[1],'Two actual rebuilds differed'
    report['two_rebuilds']={'identical':True,'files':len(inventories[0]),'pngs':len(inventories[0])-1}
    run('outfit-tests',[sys.executable,str(ROOT/'company_loop/tests/outfit_assets_test.py')],marker='OK')
    run('inherited-asset-tests',[sys.executable,str(ROOT/'sprite_study/tests/asset_test.py')],marker='OK')
    # A truly different root. Only sealed inputs, retained sources and lane code.
    cold=evidence/'cold-root'; cold.mkdir()
    seal=json.loads((HERE/'protected-inputs.json').read_text())
    for name in seal:
        q=cold/name;q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/name,q)
    co=cold/'company_loop/outfits';co.mkdir(parents=True,exist_ok=True)
    for name in ['build_outfits.py','recipe.json','protected-inputs.json']:
        shutil.copy2(HERE/name,co/name)
    shutil.copytree(HERE/'sources',co/'sources')
    ct=cold/'company_loop/tests/outfit_assets_test.py';ct.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/'company_loop/tests/outfit_assets_test.py',ct)
    run('cold-root-build',[sys.executable,str(co/'build_outfits.py')],root=cold)
    cold_hashes={name:digest(co/name) for name in inventories[1]}
    assert cold_hashes==inventories[1],'Cold-root output differs'
    run('cold-root-tests',[sys.executable,str(ct)],root=cold,marker='OK')
    report['cold_root']={'identical':True,'files':len(cold_hashes),'copied_protected_inputs':len(seal)}
    negatives=[]
    def negative(name,path,xy,test):
        saved=path.read_bytes()
        try:
            im=Image.open(path).convert('RGBA');pixel=im.getpixel(xy)
            assert isinstance(pixel,tuple)
            v=list(pixel);v[3 if name=='obsolete-boot-mask' else 0]=(255 if name=='obsolete-boot-mask' else (v[0]+1)%256)
            im.putpixel(xy,tuple(v));im.save(path)
            run('negative-'+name,[sys.executable,str(ct),'OutfitAssetsTest.'+test],root=cold,expected=1,marker='FAILED')
            negatives.append(name)
        finally: path.write_bytes(saved)
    negative('obsolete-boot-mask',co/'characters/foundation_keep_mask.png',(100,1200),'test_complete_registered_outfits')
    negative('repainted-upper',co/'characters/outfit_mail.png',(520,420),'test_upper_anatomy_restoration_and_mask')
    negative('changed-protected-source',cold/'sprite_study/assets/characters/body_mail.png',(520,420),'test_protected_inputs')
    run('cold-root-restored-tests',[sys.executable,str(ct)],root=cold,marker='OK')
    report['deliberate_negatives_rejected']=negatives
    # Native Image math in an isolated empty project and state home.
    native=evidence/'native-image-project';native.mkdir()
    (native/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Private Outfit Image QA"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    shutil.copy2(HERE/'native_image_check.gd',native/'native_image_check.gd')
    home=evidence/'private-home';home.mkdir()
    env=os.environ.copy();env.update({'HOME':str(home),'XDG_CONFIG_HOME':str(home/'config'),'XDG_DATA_HOME':str(home/'data'),'XDG_CACHE_HOME':str(home/'cache'),'OUTFIT_QA_ROOT':str(cold),'OUTFIT_QA_OUTPUT':str(native)})
    log=run('native-image',[str(ENGINE),'--headless','--single-threaded-scene','--path',str(native),'--script','res://native_image_check.gd'],root=native,env=env,marker='OUTFIT_NATIVE_IMAGE_PASS')
    assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log,log
    comparisons={}
    for name in ('quilt','mail','brigandine'):
        a=np.array(Image.open(native/f'native-{name}.png').convert('RGBA')).astype(float)
        b=np.array(Image.open(HERE/f'evidence/composite-{name}.png').convert('RGBA')).astype(float)
        alpha=float(np.abs(a[:,:,3]-b[:,:,3]).max()); mattes=[]
        for bg in (0,255):
            aa=a[:,:,:3]*a[:,:,3:]/255+bg*(1-a[:,:,3:]/255)
            bb=b[:,:,:3]*b[:,:,3:]/255+bg*(1-b[:,:,3:]/255)
            mattes.append(float(np.abs(aa-bb).max()))
        comparisons[name]={'alpha_max_channel_delta':alpha,'black_white_matte_max_deltas':mattes}
        assert alpha<=1 and max(mattes)<=2,(name,comparisons[name])
    report['native_image']={'engine':str(ENGINE),'engine_sha256':digest(ENGINE),'comparisons':comparisons,'scope':'native Image PNG load, mask and blend only; not production resolver/GPU/GUI'}
    report['protected_inputs']={'count':len(seal),'unchanged':all(digest(ROOT/name)==h for name,h in seal.items())}
    assert report['protected_inputs']['unchanged']
    # Publish convenient exact final previews; no re-encoding.
    for name in ('actual-menu-400.png','actual-tactical-120-90.png','hem-and-boot-joins.png','isolated-layers-and-mask.png','reference-source-delivery.png','identity-and-removal.png'):
        shutil.copy2(HERE/'evidence'/name,evidence/name)
    report['status']='PASS';save_report()
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
