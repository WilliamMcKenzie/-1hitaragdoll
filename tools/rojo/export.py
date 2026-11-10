"""Regenerate the Rojo model files from src/AssetKit.

Runs the bundled showcase script against tools/preview/mock.luau with the luau
CLI and writes rojo/AssetShowcase.model.json and rojo/AssetKitModels.model.json.

Usage: python3 tools/rojo/export.py [path/to/luau]
"""
import json
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
LUAU = sys.argv[1] if len(sys.argv) > 1 else "luau"

subprocess.run([sys.executable, str(ROOT / "tools" / "bundle.py")], check=True)
bundle = [l for l in (ROOT / "build" / "BuildAssetShowcase.lua").read_text().splitlines() if not l.startswith('print("[AssetKit]')]
script = "\n".join([(ROOT / "tools" / "preview" / "mock.luau").read_text(), *bundle, (ROOT / "tools" / "rojo" / "export.luau").read_text()])
with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False) as f:
    f.write(script)
out = subprocess.run([LUAU, f.name], check=True, capture_output=True, text=True).stdout
files = json.loads(out)
dest = ROOT / "rojo"
dest.mkdir(exist_ok=True)
for name, model in files.items():
    model.pop("name", None)  # Rojo names the instance after the file
    path = dest / f"{name}.model.json"
    path.write_text(json.dumps(model, separators=(",", ":")))
    print(f"wrote {path.relative_to(ROOT)} ({path.stat().st_size // 1024} KB)")
