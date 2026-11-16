# Legacy Mermaid Source Inventory

**Inspection date:** 2026-11-16  
**Source:** ChatGPT Library archive `/AtheerTradingPro/90_SOURCE_ARCHIVES/Project documents and questions and answers.zip`

## Verified extraction counts

| Measure | Result |
|---|---:|
| Markdown files in source archive | 564 |
| Markdown documents containing Mermaid fences | 31 |
| Mermaid blocks | 52 |
| Formal architecture/implementation documents in archive | 47 |
| Q&A documents in archive | 517 |

The 31-document figure is not the number of diagrams. The archive contains 52 Mermaid blocks across those 31 Markdown documents. Some source documents contain multiple blocks.

The original ZIP remains preserved and unmodified in the ChatGPT Library. The extractor `scripts/extract-mermaid-sources.py` is committed with the canonical diagram baseline and deterministically emits individual `.mmd` files plus a JSON provenance manifest.

## Migration acceptance criteria

- [ ] Run the extractor against the original Library ZIP.
- [ ] Confirm 31 source documents and 52 blocks.
- [ ] Review source-relative provenance and generated file names.
- [ ] Render all 52 diagrams using the pinned Mermaid CLI in CI.
- [ ] Correct syntax defects only in separate reviewed changes; retain raw extracted originals.
- [ ] Commit the 52 generated files and manifest.
- [ ] Map canonical diagrams to the current approved architecture and mark superseded/obsolete diagrams without deleting historical sources.

Until these criteria pass, the historical diagram migration remains **in progress**. The eight canonical diagrams in this directory are a current engineering baseline authored for the new repository, not replacements for the 52 historical source blocks.
