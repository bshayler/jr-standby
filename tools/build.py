#!/usr/bin/env python3
"""Build helpers for the web sign.

  python3 tools/build.py                 write web/lines.js from data/lines.json
  python3 tools/build.py --standalone F  also write a single-file copy of the page (lines inlined) to F
"""
import json, pathlib, sys

root = pathlib.Path(__file__).resolve().parent.parent
data = json.loads((root / "data" / "lines.json").read_text(encoding="utf-8"))
js = "window.EKIMEI_LINES = " + json.dumps(data, ensure_ascii=False, separators=(",", ":")) + ";\n"
(root / "web" / "lines.js").write_text(js, encoding="utf-8")
print("wrote web/lines.js")

if "--standalone" in sys.argv:
    out = pathlib.Path(sys.argv[sys.argv.index("--standalone") + 1])
    page = (root / "web" / "index.html").read_text(encoding="utf-8")
    page = page.replace('<script src="lines.js"></script>', "<script>" + js + "</script>")
    out.write_text(page, encoding="utf-8")
    print("wrote", out)
