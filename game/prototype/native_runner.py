#!/usr/bin/env python3
"""Private-desktop QA entrypoint; importing lifecycle helpers has no side effects."""
import argparse
import hashlib
import json
import os
import pathlib
import shutil
import subprocess


def run_owned_process(args, *, timeout, terminate_timeout=2.0, kill_timeout=2.0,
                      on_start=None, **popen_kwargs):
    """Wait for this exact Popen child; bounded cleanup also covers receipt errors.

    A cleanup failure is attached to, never substituted for, the original failure.
    No process-name lookup or process-group signal can reach an unrelated child.
    """
    proc = subprocess.Popen(args, **popen_kwargs)
    failure = None
    try:
        if on_start is not None:
            on_start(proc)
        return proc.wait(timeout=timeout)
    except BaseException as exc:
        failure = exc
        raise
    finally:
        try:
            if proc.poll() is None:
                try:
                    proc.terminate()
                    proc.wait(timeout=terminate_timeout)
                except BaseException:
                    # A timeout, signal interruption, or terminate error must
                    # not bypass escalation or leave an unreaped owned child.
                    try:
                        proc.kill()
                    finally:
                        proc.wait(timeout=kill_timeout)
            else:
                proc.wait(timeout=kill_timeout)
        except BaseException as cleanup_error:
            if failure is None:
                raise
            failure.add_note(f'owned-child cleanup failed: {cleanup_error!r}')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--skip-legacy', action='store_true', default=False,
                        help='run prototype QA only; explicitly skip the inherited full UI journey')
    options = parser.parse_args(argv)
    home = pathlib.Path.home()
    root = home/'ashen-prototype'
    source = pathlib.Path('/mnt/build')
    evidence = home/'ashen-evidence'
    evidence.mkdir(exist_ok=True)
    shutil.copytree(source, root, ignore=shutil.ignore_patterns('.git', '.godot', '__pycache__'))
    engine = '/mnt/engine/Godot_v4.4.1-stable_linux.x86_64'
    env = os.environ.copy()
    env.update({'LIBGL_ALWAYS_SOFTWARE': '1', '__EGL_VENDOR_LIBRARY_FILENAMES': '/usr/share/glvnd/egl_vendor.d/50_mesa.json', 'NO_AT_BRIDGE': '1'})

    def inventory():
        return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in root.rglob('*') if p.is_file() and '.godot' not in p.parts}

    try:
        with (evidence/'import.log').open('w') as log:
            cp = subprocess.run([engine, '--headless', '--single-threaded-scene', '--path', str(root), '--import'], stdout=log, stderr=subprocess.STDOUT, env=env, timeout=120)
        if cp.returncode:
            raise RuntimeError(f'import exited {cp.returncode}')
        before = inventory()
        args = [engine, '--path', str(root), '--rendering-method', 'gl_compatibility', '--display-driver', 'wayland', '--verbose', '--audio-driver', 'Dummy', '--resolution', '936x550', '--', '--observe']
        identity = {}

        def record_birth(proc):
            identity.update({'pid': proc.pid, 'argv': args, 'starttime': pathlib.Path(f'/proc/{proc.pid}/stat').read_text().split()[21]})
            (evidence/'birth.json').write_text(json.dumps(identity, indent=2))

        with (evidence/'native.log').open('w') as log:
            rc = run_owned_process(args, stdout=log, stderr=subprocess.STDOUT, env=env, timeout=600, on_start=record_birth)
        (evidence/'exit.json').write_text(json.dumps({'exit_code': rc, 'identity': identity, 'source_unchanged': before == inventory()}, indent=2))
        if options.skip_legacy:
            legacy_result = {'skipped': True, 'reason': '--skip-legacy requested: prototype-only QA'}
        else:
            legacy_args = [engine, '--path', str(root), '--rendering-method', 'gl_compatibility', '--display-driver', 'wayland', '--audio-driver', 'Dummy', '--script', 'res://tests/iron_ui.gd']
            with (evidence/'legacy-native.log').open('w') as log:
                legacy = subprocess.run(legacy_args, stdout=log, stderr=subprocess.STDOUT, env=env, timeout=240)
            (evidence/'legacy-exit.json').write_text(json.dumps({'exit_code': legacy.returncode, 'argv': legacy_args}, indent=2))
            if (root/'docs/iron-0.46').exists():
                shutil.copytree(root/'docs/iron-0.46', evidence/'legacy-screenshots', dirs_exist_ok=True)
            legacy_result = {'skipped': False, 'exit_code': legacy.returncode}
        (evidence/'runner-final.json').write_text(json.dumps({'completed': True, 'legacy': legacy_result}, indent=2))
    except BaseException as exc:
        try:
            (evidence/'runner-error.json').write_text(json.dumps({'error': repr(exc), 'notes': getattr(exc, '__notes__', [])}, indent=2))
        except BaseException as report_error:
            exc.add_note(f'runner-error receipt failed: {report_error!r}')
        raise


if __name__ == '__main__':
    main()
