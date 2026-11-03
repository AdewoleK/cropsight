"""Lists every phrase the app translates: literal keys passed to tr() /
context.tr() in lib/, plus the field-guide names in domain.py (crops,
problem types, chips, problem titles), and the DiagnosisMode labels.

    python3 tool/l10n/extract.py          # print keys, one per line
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from domain import ALL  # noqa: E402

# tr('...') or tr("...") — single literal, possibly with escapes.
_CALL = re.compile(r"""\btr\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")""")


def _unescape(s):
    return (s.replace("\\'", "'").replace('\\"', '"').replace("\\n", "\n")
             .replace("\\$", "$").replace("\\\\", "\\"))


def code_keys():
    keys = []
    for path in sorted((ROOT / "lib").rglob("*.dart")):
        if path.name.startswith("translations_") or path.name == "dev_preview.dart":
            continue
        for m in _CALL.finditer(path.read_text()):
            raw = m.group(1) if m.group(1) is not None else m.group(2)
            keys.append(_unescape(raw))
    return keys


def mode_keys():
    s = (ROOT / "lib/core/settings/app_settings.dart").read_text()
    block = s[s.index("enum DiagnosisMode"):]
    block = block[:block.index(";")]
    return re.findall(r"\w+\('([^']+)'\)", block)


def all_keys():
    seen, out = set(), []
    for k in code_keys() + mode_keys() + [row[0] for row in ALL]:
        if k not in seen:
            seen.add(k)
            out.append(k)
    return out


if __name__ == "__main__":
    for k in all_keys():
        print(repr(k))
