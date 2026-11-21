#!/usr/bin/env python3
"""Bounded headless acceptance; error text is failure even if Godot exits zero."""
import argparse,datetime,json,os,pathlib,re,shutil,subprocess,tempfile
p=argparse.ArgumentParser()
p.add_argument('--godot',default=os.environ.get('GODOT_BIN') or shutil.which('godot') or '/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64')
p.add_argument('--output',type=pathlib.Path,required=True)
p.add_argument('--legacy',action='store_true')
a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]
a.output.mkdir(parents=True,exist_ok=True)
scripts=['prototype/tests/layout_test.gd','prototype/tests/controller_test.gd','prototype/tests/view_test.gd','prototype/tests/scenario_test.gd','prototype/tests/character_test.gd','prototype/tests/terrain_test.gd']
if a.legacy:
    scripts += [f'tests/{s}.gd' for s in ['run','combat_baseline','armor','weapons','tactical_ai','turns','integrated_compat','unified_campaign']]
results=[]
for script in scripts:
    name=script.replace('/','-').removesuffix('.gd')
    state=a.output/(name+'-state')
    state.mkdir(exist_ok=True)
    env=os.environ.copy()
    env.update({'HOME':str(state),'XDG_DATA_HOME':str(state/'data'),'XDG_CONFIG_HOME':str(state/'config'),'XDG_CACHE_HOME':str(state/'cache'),'DISPLAY':'','WAYLAND_DISPLAY':'','DBUS_SESSION_BUS_ADDRESS':''})
    args=[a.godot,'--headless','--single-threaded-scene','--path',str(root),'--script','res://'+script]
    if script == 'tests/run.gd': args += ['--','--battles=20']
    try:
        cp=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,env=env,timeout=180)
        log=cp.stdout
        status=cp.returncode==0 and not re.search(r'(^|\n)(SCRIPT ERROR:|ERROR:|FAIL:)',log)
        record={'script':script,'exit_code':cp.returncode,'passed':status,'summaries':[line for line in log.splitlines() if re.search('checks|failures|PASS|FAIL',line)],'command':args}
    except subprocess.TimeoutExpired as exc:
        log=exc.stdout or b''
        if isinstance(log,bytes):log=log.decode(errors='replace')
        record={'script':script,'passed':False,'timeout':180,'command':args}
    (a.output/(name+'.log')).write_text(log)
    results.append(record)
    print(json.dumps(record),flush=True)
summary={'passed':all(r['passed'] for r in results),'suites':len(results),'results':results}
(a.output/'summary.json').write_text(json.dumps(summary,indent=2))
raise SystemExit(0 if summary['passed'] else 1)
