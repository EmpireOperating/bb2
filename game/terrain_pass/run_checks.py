#!/usr/bin/env python3
"""Cold terrain + predecessor checks with separate private project/state origins."""
import argparse
from contextlib import contextmanager
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('company_checks', ROOT/'company_loop/run_checks.py')
assert spec is not None and spec.loader is not None
BASE = importlib.util.module_from_spec(spec)
spec.loader.exec_module(BASE)
NEW_SUITES = [
    ('terrain_pass','rules','TERRAIN_RULES_TEST'),
    ('terrain_pass','maps','TERRAIN_MAPS_TEST'),
    ('terrain_pass','session','TERRAIN_SESSION_TEST'),
    ('terrain_pass','ui','TERRAIN_UI_TEST'),
    ('terrain_pass','terrain','TERRAIN_RENDER_TEST'),
]
SUITES = BASE.SUITES + NEW_SUITES
PYTHON_SUITES = [
    ('terrain-check-runner', 'terrain_pass/tests/check_runner_test.py'),
    ('terrain-entrypoint', 'terrain_pass/tests/entrypoint_test.py'),
    ('terrain-art-preservation', 'terrain_pass/tests/art_preservation_test.py'),
]
# These mixed suites move to the successor wrapper, not out of coverage.
RELOCATED_ART_SUITES = {
    ('outfit-art', 'company_loop/tests/outfit_assets_test.py'),
    ('glove-art', 'company_loop/tests/glove_assets_test.py'),
}
completed = BASE.completed
copy_project = BASE.copy_project

@contextmanager
def cohort_settings(project, cohort):
    """Only mutate a detached test copy; restore its exact config even on failure."""
    project = Path(project).resolve()
    if project == ROOT.resolve():
        raise ValueError('Cannot rewrite live source project settings')
    if cohort not in ('predecessor','successor'):
        raise ValueError('Unknown cohort')
    path = project/'project.godot'
    original = path.read_bytes()
    try:
        if cohort == 'predecessor':
            text = original.decode()
            settings = {
                'config/name':'The Ashen Company — Company Outfitting',
                'config/custom_user_dir_name':'ashen-company-company-loop',
                'run/main_scene':'res://company_loop/main.tscn',
            }
            for key,value in settings.items():
                text, count = re.subn(r'^'+re.escape(key)+r'="[^"\n]*"$',
                                     key+'="'+value+'"', text, flags=re.M)
                if count != 1:
                    raise ValueError('Missing or duplicated project setting: '+key)
            path.write_text(text)
        yield
    finally:
        path.write_bytes(original)


def inventory(root):
    return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest()
            for p in root.rglob('*') if p.is_file()
            and not any(x in p.relative_to(root).parts for x in ('.git','.godot','__pycache__','.iron-user'))}


def art_report(log):
    scopes = [json.loads(line.split('ART_COHORT: ', 1)[1])
              for line in log.splitlines() if line.startswith('ART_COHORT: ')]
    preservation = [json.loads(line.split('ART_PRESERVATION: ', 1)[1])
                    for line in log.splitlines() if 'ART_PRESERVATION: ' in line]
    if len(scopes) != 1 or len(preservation) != 2 or len({r['manifest'] for r in preservation}) != 2:
        raise ValueError('Missing or duplicated explicit art preservation receipts')
    return {**scopes[0], 'preservation': preservation,
            'retained_original_test_count': len(scopes[0]['retained_tests']),
            'replacement_test_count': len(preservation),
            'historical_seal_entries_verified': sum(r['immutable_entries_verified'] for r in preservation)}


def python_checks(cohort):
    return ([row for row in BASE.PYTHON_SUITES if row not in RELOCATED_ART_SUITES]
            if cohort == 'predecessor' else PYTHON_SUITES)


def godot_checks(cohort, godot, project):
    """One command is one process; the cold reader immediately follows its writer."""
    suites = BASE.SUITES if cohort == 'predecessor' else NEW_SUITES
    for folder, stem, marker in suites:
        command = [godot, '--headless', '--single-threaded-scene', '--path', str(project),
                   '--script', f'res://{folder}/tests/{stem}_test.gd']
        if folder == 'sprite_study' and stem == 'character':
            command += ['--', '--real-assets']
        yield folder + '-' + stem, command, marker
        if cohort == 'successor' and (folder, stem) == ('terrain_pass', 'session'):
            yield 'terrain_pass-session-cold-load', command + ['--', '--cold-load'], marker


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--cohort',choices=['all','predecessor','successor'],default='all')
    parser.add_argument('--godot',default=os.environ.get('GODOT_BIN') or shutil.which('godot') or '/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64')
    args = parser.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    private = Path(tempfile.mkdtemp(prefix='terrain-check-',dir=os.environ.get('TMPDIR',str(Path.home()/'.cache'))))
    project = private/'project'
    source_before = inventory(ROOT)
    copy_project(ROOT,project)
    copied = inventory(project)
    if source_before != copied:
        raise RuntimeError('Private copy does not match source inventory')
    (args.output/'source-manifest.json').write_text(json.dumps(source_before,sort_keys=True,indent=2)+'\n')
    results = []
    cohorts = ['predecessor','successor'] if args.cohort == 'all' else [args.cohort]
    for cohort in cohorts:
        state = private/(cohort+'-home');state.mkdir()
        env = os.environ.copy()
        env.update(GODOT_BIN=str(args.godot),PYTHONDONTWRITEBYTECODE='1',HOME=str(state),XDG_DATA_HOME=str(state/'data'),XDG_CONFIG_HOME=str(state/'config'),XDG_CACHE_HOME=str(state/'cache'),DISPLAY='',WAYLAND_DISPLAY='',DBUS_SESSION_BUS_ADDRESS='')
        def run(name, command, marker, timeout=240):
            command = [str(x) for x in command]
            try:
                cp = subprocess.run(command,cwd=project,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout)
                log,code = cp.stdout,cp.returncode
            except subprocess.TimeoutExpired as exc:
                log = exc.stdout or b''
                if isinstance(log,bytes): log = log.decode(errors='replace')
                code = -1
            row = {'name':cohort+'-'+name,'cohort':cohort,'command':command,'home':str(state),'expected_marker':marker,'exit_code':code,'passed':completed(log,code,marker),'warnings':re.findall(r'^WARNING:.*$',log,re.M),'summaries':[line for line in log.splitlines() if re.search(r'checks|failures|Ran \d+ tests|^OK$|^FAILED',line)]}
            if name == 'terrain-art-preservation':
                try:
                    row['art_verification'] = art_report(log)
                except (ValueError, KeyError, TypeError) as exc:
                    row['passed'] = False
                    row['art_verification'] = {'report_error': str(exc)}
            (args.output/(row['name']+'.log')).write_text(log)
            results.append(row)
            print(json.dumps(row),flush=True)
            return row['passed']
        with cohort_settings(project,cohort):
            if not run('cold-import',[args.godot,'--headless','--single-threaded-scene','--path',project,'--import'],'import'):
                continue
            for name, command, marker in godot_checks(cohort, args.godot, project):
                run(name, command, marker)
            python_suites = python_checks(cohort)
            for name,path in python_suites:
                run(name,['python3',project/path],'python',120)
    expected = sum(1 + len(list(godot_checks(cohort, args.godot, project))) + len(python_checks(cohort)) for cohort in cohorts)
    original_files_unchanged = all((project/path).is_file() and hashlib.sha256((project/path).read_bytes()).hexdigest()==digest for path,digest in source_before.items())
    source_unchanged = inventory(ROOT) == source_before
    summary = {'passed':len(results)==expected and all(row['passed'] for row in results) and original_files_unchanged and source_unchanged,'cohort':args.cohort,'expected_commands':expected,'actual_commands':len(results),'private_project':str(project),'source_unchanged':source_unchanged,'executed_original_files_unchanged':original_files_unchanged,'results':results,'scope':'Predecessor mode runs with its original scene/name/userdir only inside the private copy. Successor restores original candidate settings and uses a separate private HOME. No old save migration or full-game parity claim.'}
    summary['art_verification'] = next(
        (row['art_verification'] for row in results if 'art_verification' in row),
        {'status': 'not_run', 'reason': 'Art cohort is required in --cohort all or successor.'})
    summary['explicit_supersession'] = (
        'The outfit/glove mixed Python suites move from predecessor to successor. '
        'The successor wrapper selects all 12 original pixel/provenance cases unchanged; only '
        'OutfitAssetsTest.test_protected_inputs and GloveAssetsTest.test_protected_source_validator '
        'are superseded by two strict historical-manifest checks. Their only byte-equality '
        'exception is src/battle.gd, the sole authorized changed path in either seal. '
        'No art/support/UID path is exempt; no original test, manifest or battle bytes are rewritten. '
        'The prior default-project assertion remains exercised under predecessor settings; '
        'current config, scene, preserved launchers and a real headless launch are checked separately. '
        'Historical failed aggregate evidence is retained separately, not relabeled as passing.')
    summary['source_project'] = str(ROOT)
    (args.output/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    return 0 if summary['passed'] else 1

if __name__ == '__main__':
    raise SystemExit(main())
