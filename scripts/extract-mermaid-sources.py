#!/usr/bin/env python3
"""Extract Mermaid fenced blocks from the immutable ATHEER source ZIP.

The extractor preserves each source-relative path and block number. It does not
validate Mermaid syntax; rendering is performed by the repository CI workflow.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path

FENCE = re.compile(r"^\s*```mermaid\s*\r?\n(.*?)^\s*```\s*$", re.I | re.M | re.S)


def slug(value: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", "-", value).strip("-")
    return value[:90] or "diagram"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--expected-documents", type=int, default=31)
    parser.add_argument("--expected-blocks", type=int, default=52)
    args = parser.parse_args()

    if not args.archive.is_file():
        parser.error(f"Archive does not exist: {args.archive}")

    args.output.mkdir(parents=True, exist_ok=True)
    manifest = []
    source_documents = set()

    with zipfile.ZipFile(args.archive) as archive:
        for name in sorted(archive.namelist()):
            if name.startswith("__MACOSX/") or not name.lower().endswith(".md"):
                continue
            text = archive.read(name).decode("utf-8-sig", errors="replace")
            blocks = FENCE.findall(text)
            if not blocks:
                continue
            source_documents.add(name)
            for block_number, source in enumerate(blocks, start=1):
                digest = hashlib.sha256(f"{name}\0{block_number}".encode()).hexdigest()[:10]
                filename = f"{slug(Path(name).stem)}-{digest}-b{block_number:02d}.mmd"
                target = args.output / filename
                source = source.strip()
                target.write_text(
                    f"%% ATHEER source: {name}\n"
                    f"%% Mermaid block: {block_number}\n\n{source}\n",
                    encoding="utf-8",
                )
                manifest.append({
                    "file": filename,
                    "source_path": name,
                    "block_number": block_number,
                    "sha256": hashlib.sha256(source.encode()).hexdigest(),
                })

    (args.output / "manifest.json").write_text(
        json.dumps({
            "archive": args.archive.name,
            "source_documents": len(source_documents),
            "diagram_blocks": len(manifest),
            "diagrams": manifest,
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    print(f"Source documents with Mermaid: {len(source_documents)}")
    print(f"Mermaid blocks extracted: {len(manifest)}")
    if len(source_documents) != args.expected_documents:
        raise SystemExit(
            f"Expected {args.expected_documents} source documents; found {len(source_documents)}"
        )
    if len(manifest) != args.expected_blocks:
        raise SystemExit(
            f"Expected {args.expected_blocks} Mermaid blocks; found {len(manifest)}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
