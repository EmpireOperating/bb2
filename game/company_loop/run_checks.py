#!/usr/bin/env python3
"""Cold isolated company loop checks; require actual suite completion, not only exit 0."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ERRORS = re.compile(r'(^|\n)(ERROR:|SCRIPT ERROR:|FAIL:)', re.M)
# Reproduced unchanged on bdac701 after cold import; test-only filesystem image read.
BASELINE_WARNING = "WARNING: Loaded resource as image file, this will not work on export: 'res://sprite_study/assets/characters/foundation.png'. Instead, import the image file as an Image resource and load it normally as a resource."
SUITES = [
 ('prototype','layout','LAYOUT'),('prototype','controller','CONTROLLER'),
 ('prototype','view','VIEW'),('prototype','scenario','SCENARIO'),
 ('prototype','character','CHARACTER_TEST'),('prototype','terrain','TERRAIN'),
 ('visual_slice','loadout','SLICE_LOADOUT'),('visual_slice','view','SLICE_VIEW'),
 ('visual_slice','character','PAINTED_CHARACTER_TEST'),('visual_slice','terrain','PAINTED_TERRAIN'),
 ('visual_slice','integration','SLICE_INTEGRATION'),
 ('sprite_study','character','SPRITE_STUDY_CHARACTER_TEST'),
 ('sprite_study','inspection','SPRITE_INSPECTION'),('sprite_study','integration','SPRITE_INTEGRATION'),
 ('sprite_study','color','SPRITE_STUDY_COLOR_TEST'),
 ('company_loop','session','SESSION_TEST'),('company_loop','character','COMPANY_CHARACTER_TEST'),
 ('company_loop','camp_panel','CAMP_PANEL_TEST'),('company_loop','integration','COMPANY_INTEGRATION'),
 ('company_loop','boundary','COMPANY_BOUNDARY'),
 ('company_loop','checkpoint_ui','COMPANY_CHECKPOINT_UI'),
 ('company_loop','outfit','COMPANY_OUTFIT_TEST'),
 ('company_loop','glove','COMPANY_GLOVE_TEST'),
]
PYTHON_SUITES = [('native-lifecycle','prototype/tests/native_runner_test.py'),('source-art','sprite_study/tests/asset_test.py'),('entrypoint','company_loop/tests/entrypoint_test.py'),('check-runner','company_loop/tests/check_runner_test.py'),('outfit-art','company_loop/tests/outfit_assets_test.py'),('glove-art','company_loop/tests/glove_assets_test.py')]

def completed(log, code, marker):
    if code != 0 or ERRORS.search(log):
        return False
    warnings = re.findall(r'^WARNING:.*$',log,re.M)
    if warnings and not (marker == 'SPRITE_STUDY_CHARACTER_TEST' and warnings == [BASELINE_WARNING]):
        return False
    if marker == 'import':
        return True  # Godot's finite --import command has no assertion suite.
    if marker == 'python':
        return bool(re.search(r'^Ran [1-9]\d* tests? in ', log, re.M) and re.search(r'^OK$', log, re.M))
    prefix = r'^'+re.escape(marker)
    standard = re.search(prefix+r': (\d+) checks[,;] (\d+) failures$',log,re.M)
    equals = re.search(prefix+r' checks=(\d+) failures=(\d+)$',log,re.M)
    match = standard or equals
    return bool(match and int(match[1]) > 0 and int(match[2]) == 0)

def copy_project(source, destination):
    # Art provenance tests bind checked-in evidence images too; only omit
    # generated caches, Git metadata and local user saves.
    return shutil.copytree(source,destination,ignore=shutil.ignore_patterns('.git','.godot','__pycache__','.iron-user'))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--godot',default=os.environ.get('GODOT_BIN') or shutil.which('godot') or '/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64')
    args = parser.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    source = Path(__file__).resolve().parents[1]
    private = Path(tempfile.mkdtemp(prefix='company-check-',dir=os.environ.get('TMPDIR',str(Path.home()/'.cache'))))
    project = private/'project'
    copy_project(source,project)
    state = private/'state';state.mkdir()
    env = os.environ.copy()
    env.update(HOME=str(state),XDG_DATA_HOME=str(state/'data'),XDG_CONFIG_HOME=str(state/'config'),XDG_CACHE_HOME=str(state/'cache'),DISPLAY='',WAYLAND_DISPLAY='',DBUS_SESSION_BUS_ADDRESS='')
    results = []
    def run(name, command, marker, timeout=180):
        try:
            cp = subprocess.run(command,cwd=project,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout)
            log, code = cp.stdout, cp.returncode
        except subprocess.TimeoutExpired as exc:
            log = exc.stdout or b''
            if isinstance(log,bytes): log = log.decode(errors='replace')
            code = -1
        record = {'name':name,'command':[str(x) for x in command],'expected_marker':marker,'exit_code':code,'passed':completed(log,code,marker),'warnings':re.findall(r'^WARNING:.*$',log,re.M),'summaries':[x for x in log.splitlines() if re.search(r'checks|failures|Ran \d+ tests|^OK$|^FAILED',x)]}
        (args.output/(name+'.log')).write_text(log)
        results.append(record)
        print(json.dumps(record),flush=True)
        return record['passed']
    if run('cold-import',[args.godot,'--headless','--single-threaded-scene','--path',str(project),'--import'],'import'):
        for folder,stem,marker in SUITES:
            command = [args.godot,'--headless','--single-threaded-scene','--path',str(project),'--script',f'res://{folder}/tests/{stem}_test.gd']
            if folder == 'sprite_study' and stem == 'character': command += ['--','--real-assets']
            run(folder+'-'+stem,command,marker)
        for name,path in PYTHON_SUITES:
            run(name,['python3',str(project/path)],'python',120)
    summary = {'passed':len(results)==1+len(SUITES)+len(PYTHON_SUITES) and all(x['passed'] for x in results),'private_project':str(project),'results':results,'explicit_supersession':'sprite_study/tests/entrypoint_test.py has a default-project/title/state-directory assertion for the previous study. company_loop/tests/entrypoint_test.py replaces that assertion and still checks all preserved explicit launchers. No original test file was edited.'}
    (args.output/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    return 0 if summary['passed'] else 1

if __name__ == '__main__':
    raise SystemExit(main())
