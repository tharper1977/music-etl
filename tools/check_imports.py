# python
\"\"\"
Simple import-edge checker to catch accidental cross-layer imports.
Run this in CI: python tools/check_imports.py
It scans imports and asserts:
 - src.core imports none of src.application, src.adapters or src.infra
 - src.application imports only from src.core (stdlib and typing are allowed)
 - src.adapters may import src.core and src.application and src.infra
 - src.infra imports only stdlib / typing (no app/adapters/core)
This is a coarse check and should be adapted for your exact package names.
\"\"\"
import ast
import pathlib
import sys

PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC_ROOT = PROJECT_ROOT / 'src'

RULES = {
    'src.core': [],  # core must not import app/adapters/infra
    'src.application': ['src.core'],
    'src.adapters': ['src.core', 'src.application', 'src.infra'],
    'src.infra': [],
    'src.scripts': ['src.core', 'src.application', 'src.adapters', 'src.infra'],
}

def package_of(path: pathlib.Path) -> str:
    rel = path.relative_to(SRC_ROOT)
    first = rel.parts[0] if rel.parts else ''
    return f'src.{first}' if first else 'src'

def check_file(path: pathlib.Path):
    text = path.read_text()
    tree = ast.parse(text)
    pkg = package_of(path)
    violations = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for n in node.names:
                name = n.name
                if name.startswith('src.'):
                    target_pkg = '.'.join(name.split('.')[:2])
                    allowed = RULES.get(pkg, [])
                    if target_pkg not in allowed and target_pkg != pkg:
                        violations.append((pkg, name, path))
        elif isinstance(node, ast.ImportFrom):
            module = node.module or ''
            if module.startswith('src.'):
                target_pkg = '.'.join(module.split('.')[:2])
                allowed = RULES.get(pkg, [])
                if target_pkg not in allowed and target_pkg != pkg:
                    violations.append((pkg, module, path))
    return violations

def main():
    violations = []
    for py in SRC_ROOT.rglob('*.py'):
        v = check_file(py)
        if v:
            violations.extend(v)
    if violations:
        for pkg, name, path in violations:
            print(f'Architecture violation: {pkg} imports {name} in {path}')
        sys.exit(2)
    print('No architecture import violations detected.')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
