#!/usr/bin/env python3
"""Private Omabox lifetime wrapper. No game commands; ordinary GUI input only."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--resume', action='store_true')
    parser.add_argument('--lifetime', type=int, choices=[1,2], required=True)
    options = parser.parse_args()
    source = Path('/mnt/build')
    if not (source/'company_loop/main.tscn').is_file():
        raise RuntimeError('Reviewed read-only build mount required')
    root = Path.home()/'company-native-project'
    evidence = Path.home()/f'company-native-{options.lifetime}'
    evidence.mkdir(exist_ok=False)
    if options.resume:
        if options.lifetime != 2 or not (root/'company_loop/main.gd').is_file():
            raise RuntimeError('Resume requires the previous private project')
    else:
        if options.lifetime != 1: raise RuntimeError('Fresh run is lifetime 1')
        shutil.copytree(source,root,ignore=shutil.ignore_patterns('.git','.godot','__pycache__'))
    spec = importlib.util.spec_from_file_location('owned_runner',root/'prototype/native_runner.py')
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    engine = '/mnt/engine/Godot_v4.4.1-stable_linux.x86_64'
    env = os.environ.copy()
    env.update(LIBGL_ALWAYS_SOFTWARE='1',__EGL_VENDOR_LIBRARY_FILENAMES='/usr/share/glvnd/egl_vendor.d/50_mesa.json',NO_AT_BRIDGE='1')
    def inventory():
        return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts}
    try:
        with (evidence/'import.log').open('w') as log:
            cp = subprocess.run([engine,'--headless','--single-threaded-scene','--path',str(root),'--import'],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=120)
        if cp.returncode: raise RuntimeError('Private import failed')
        before = inventory()
        (evidence/'source-before.json').write_text(json.dumps(before,sort_keys=True))
        args = [engine,'--path',str(root),'--rendering-method','gl_compatibility','--display-driver','wayland','--verbose','--audio-driver','Dummy','--resolution','936x550','--','--observe']
        identity = {}
        def birth(proc):
            identity.update(pid=proc.pid,argv=args,starttime=Path(f'/proc/{proc.pid}/stat').read_text().split()[21])
            (evidence/'birth.json').write_text(json.dumps(identity,indent=2))
        with (evidence/'native.log').open('w') as log:
            code = module.run_owned_process(args,timeout=650,on_start=birth,env=env,stdout=log,stderr=subprocess.STDOUT)
        after = inventory()
        (evidence/'source-after.json').write_text(json.dumps(after,sort_keys=True))
        result = {'completed':True,'exit_code':code,'identity':identity,'source_unchanged':before==after}
        (evidence/'runner-final.json').write_text(json.dumps(result,indent=2))
        if code != 0 or before != after: raise RuntimeError('Native process failed or source changed')
    except BaseException as exc:
        (evidence/'runner-error.json').write_text(json.dumps({'error':repr(exc)},indent=2))
        raise

if __name__ == '__main__': main()
