#!/usr/bin/env python3
"""Package only our helper files; third-party APKs/SDK and local data stay out."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED, ZipInfo
import hashlib
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'artifacts'
OUT.mkdir(exist_ok=True)
shared = ['README.md', 'GUIDE-KO.md', 'LICENSE', 'VERIFICATION.md', 'downloads.tsv']
for os_name, files in [('Windows', ['Setup-Windows.cmd', 'scripts/setup-windows.ps1']), ('Mac', ['Setup-Mac.command', 'scripts/setup-mac.sh'])]:
    archive = OUT / f'AndroidAutoSetup-{os_name}-v1.0.0.zip'
    with ZipFile(archive, 'w', ZIP_DEFLATED) as bundle:
        for name in shared + files:
            payload = (ROOT / name).read_bytes()
            if name.endswith(('.cmd', '.ps1')):
                payload = payload.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
            member = ZipInfo(f'AndroidAutoSetup-{os_name}/{name}')
            member.create_system = 3
            member.external_attr = (0o100755 if name.endswith(('.command', '.sh')) else 0o100644) << 16
            member.compress_type = ZIP_DEFLATED
            bundle.writestr(member, payload)
    with ZipFile(archive) as bundle:
        assert bundle.testzip() is None
        assert len(bundle.namelist()) == len(shared + files)
    print(f'{archive.name}: {archive.stat().st_size} bytes')
checksums = '\n'.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}' for p in sorted(OUT.glob('AndroidAutoSetup-*-v1.0.0.zip')))
(OUT / 'SHA256SUMS.txt').write_text(checksums + '\n')
