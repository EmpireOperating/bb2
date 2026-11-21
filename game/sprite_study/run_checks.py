#!/usr/bin/env python3
"""Cold, isolated sprite-study verification including all preserved presentation gates."""
import argparse,json,os,pathlib,re,shutil,subprocess,tempfile
p=argparse.ArgumentParser()
p.add_argument('--output',type=pathlib.Path,required=True)
p.add_argument('--godot',default=os.environ.get('GODOT_BIN') or shutil.which('godot') or '/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64')
a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
source=pathlib.Path(__file__).resolve().parents[1]
private=pathlib.Path(tempfile.mkdtemp(prefix='equipment-study-check-',dir=os.environ.get('TMPDIR',str(pathlib.Path.home()/'.cache'))))
project=private/'project'
shutil.copytree(source,project,ignore=shutil.ignore_patterns('.git','.godot','__pycache__','evidence','.iron-user'))
state=private/'state';state.mkdir()
env=os.environ.copy();env.update({'HOME':str(state),'XDG_DATA_HOME':str(state/'data'),'XDG_CONFIG_HOME':str(state/'config'),'XDG_CACHE_HOME':str(state/'cache'),'DISPLAY':'','WAYLAND_DISPLAY':'','DBUS_SESSION_BUS_ADDRESS':''})
results=[]
def run(name,args,timeout=180):
    try:
        cp=subprocess.run(args,cwd=project,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout)
        log=cp.stdout;code=cp.returncode
    except subprocess.TimeoutExpired as exc:
        log=exc.stdout or b''
        if isinstance(log,bytes):log=log.decode(errors='replace')
        code=-1
    record={'name':name,'exit_code':code,'passed':code==0 and not re.search(r'(^|\n)(ERROR:|SCRIPT ERROR:|FAIL:)',log),'summaries':[x for x in log.splitlines() if re.search(r'checks|failures|Ran \d+ tests|^OK$|^FAILED',x)]}
    (a.output/(name+'.log')).write_text(log);results.append(record);print(json.dumps(record),flush=True)
    return record['passed']
if run('cold-import',[a.godot,'--headless','--single-threaded-scene','--path',str(project),'--import']):
    for folder,stems in [('prototype',['layout','controller','view','scenario','character','terrain']),('visual_slice',['loadout','view','character','terrain','integration']),('sprite_study',['character','inspection','integration','color'])]:
        for stem in stems:
            args=[a.godot,'--headless','--single-threaded-scene','--path',str(project),'--script',f'res://{folder}/tests/{stem}_test.gd']
            if folder=='sprite_study' and stem=='character':args+=['--','--real-assets']
            run(folder+'-'+stem,args)
    for name,path in [('native-lifecycle','prototype/tests/native_runner_test.py'),('source-art','sprite_study/tests/asset_test.py'),('entrypoint','sprite_study/tests/entrypoint_test.py')]:
        run(name,['python3',str(project/path)],120)
summary={'passed':all(x['passed'] for x in results),'private_project':str(project),'results':results}
(a.output/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
raise SystemExit(0 if summary['passed'] else 1)
