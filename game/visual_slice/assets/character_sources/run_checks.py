#!/usr/bin/env python3
"""Cold headless character gates with isolated state; never opens a GUI."""
from pathlib import Path
import argparse, hashlib, json, os, re, subprocess, tempfile
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
DEFAULT_GODOT="/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64"

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--godot",default=os.environ.get("GODOT_BIN",DEFAULT_GODOT))
    parser.add_argument("--output",type=Path,default=HERE/"evidence/final")
    args=parser.parse_args()
    out=args.output.resolve(); out.mkdir(parents=True,exist_ok=True)
    (out/".gdignore").write_text("")
    scratch=Path(os.environ.get("TMPDIR",str(Path.home()/".hermes/cache/scratch")))
    scratch.mkdir(parents=True,exist_ok=True)
    home=Path(tempfile.mkdtemp(prefix="painted-character-home-",dir=scratch))
    env=os.environ.copy(); env.update(HOME=str(home),XDG_DATA_HOME=str(home/"data"),XDG_CONFIG_HOME=str(home/"config"),XDG_CACHE_HOME=str(home/"cache"))
    report={"mode":"headless-contract-only","native_visual_acceptance":False,"home":str(home),"runs":[],"passed":False}
    (out/"summary.json").write_text(json.dumps(report,indent=2)+"\n")
    scripts=["visual_slice/tests/character_test.gd","prototype/tests/character_test.gd","prototype/tests/view_test.gd"]
    for script in scripts:
        cmd=[args.godot,"--headless","--single-threaded-scene","--path",str(ROOT),"--script","res://"+script]
        run=subprocess.run(cmd,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=120)
        stem=script.replace("/","_").replace(".gd","")
        (out/(stem+".log")).write_text(run.stdout)
        marker=re.findall(r"(?:PAINTED_CHARACTER_TEST|CHARACTER_TEST|VIEW): (\d+) checks, (\d+) failures",run.stdout)
        clean=not re.search(r"(?:SCRIPT ERROR|ERROR:|FAIL:)",run.stdout)
        passed=run.returncode==0 and bool(marker) and int(marker[-1][1])==0 and clean
        row={"script":script,"command":cmd,"exit":run.returncode,"marker":marker,"passed":passed}
        report["runs"].append(row)
        print(run.stdout,end="")
    report["passed"]=all(r["passed"] for r in report["runs"])
    report["source_sha256"]={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/"visual_slice/character.gd",ROOT/"visual_slice/tests/character_test.gd",HERE/"build_layers.py",HERE/"layer-manifest.json",HERE/"run_checks.py"]}
    (out/"summary.json").write_text(json.dumps(report,indent=2)+"\n")
    print("PAINTED_HEADLESS_RECEIPT:",json.dumps(report))
    return 0 if report["passed"] else 1

if __name__=="__main__": raise SystemExit(main())
