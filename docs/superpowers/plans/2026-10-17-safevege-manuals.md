# SafeVege Manuals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create two polished Thai PDF manuals for SafeVege: a non-developer user guide and a developer/operations guide grounded in the current Flutter, PHP API, and MySQL repository.

**Architecture:** Keep the manuals as maintainable Markdown source files under `docs/manuals/`, then render both through one Python ReportLab generator so typography, headers, tables, page numbering, and Thai font embedding remain consistent. Final PDFs live under `output/pdf/`; rendered inspection images live temporarily under `tmp/pdfs/`.

**Tech Stack:** Markdown source, Python 3, ReportLab, pypdf/pdfplumber, Poppler `pdftoppm`, embedded `NotoSansThai-Variable.ttf` from the Flutter app assets.

## Global Constraints

- Write all explanatory content in Thai; keep code, paths, endpoint names, and commands in their real English form.
- Use only verified repository facts for current behavior; label recommendations and limitations clearly.
- Preserve the user's existing uncommitted Flutter edits and do not modify those four map-related files.
- Do not include real credentials, tokens, populated `.env` content, or production data.
- Final PDFs must be under `output/pdf/` and intermediate files under `tmp/pdfs/`.
- Validate the final PDFs by extraction and page rendering before claiming completion.

---

### Task 1: Capture verified content facts

**Files:**
- Create: `notes.md`
- Read: `fn/safevege/README.md`, `bn/README.md`, `bn/ER.md`, `bn/schema.sql`, `bn/docs/super-admin-operations.md`, `fn/safevege/pubspec.yaml`
- Read: `fn/safevege/lib/main.dart`, `fn/safevege/lib/config/app_config.dart`, `fn/safevege/lib/config/api_endpoint.dart`, `fn/safevege/lib/data/api/api_client.dart`, `fn/safevege/lib/data/repositories/safevege_repository.dart`, `fn/safevege/lib/state/remote_app_state.dart`

**Interfaces:**
- Consumes: current repository files and indexed code relationships.
- Produces: `notes.md` fact list used by both manuscripts.

- [x] Record the frontend/backend roots, entry points, configuration files, and test locations.
- [x] Record user roles, public/private flows, API prefix, database tables, certificate handling, map services, and known evidence boundaries.
- [x] Mark any draft, migration, or production-readiness caveat so it cannot be stated as a confirmed feature.

### Task 2: Write the two Thai manuscripts

**Files:**
- Create: `docs/manuals/safevege-user-manual.md`
- Create: `docs/manuals/safevege-developer-manual.md`

**Interfaces:**
- Consumes: `notes.md` and the current repository README/schema/API facts.
- Produces: complete source manuscripts with stable section headings that the renderer can turn into a table of contents.

- [ ] Write the user guide with role-based steps for guest, consumer, shop, Inspector Admin, and Super Admin users, including statuses, troubleshooting, safety notes, and a glossary.
- [ ] Write the developer guide with system architecture, directory map, data flow, roles/auth, API groups, ER/data model, setup, commands, testing, extension workflow, migrations, security, deployment notes, and known limitations.
- [ ] Add a source-reference section to the developer guide with exact repository paths and the documentation date.
- [ ] Run a placeholder scan for `TBD`, `TODO`, and unfinished headings; fix every hit before rendering.

### Task 3: Build the shared PDF renderer

**Files:**
- Create: `tools/generate_safevege_manuals.py`
- Create: `output/pdf/.gitkeep` only if the output directory otherwise cannot be represented
- Create: `tmp/pdfs/.gitkeep` only if the temporary directory otherwise cannot be represented

**Interfaces:**
- Consumes: the two Markdown manuscripts and the Thai font at `fn/safevege/assets/fonts/NotoSansThai-Variable.ttf`.
- Produces: `output/pdf/safevege-user-manual-th.pdf` and `output/pdf/safevege-developer-manual-th.pdf`.

- [ ] Define a reusable ReportLab `DocTemplate`, page callback, Thai font registration, heading styles, code style, table style, callout style, and page-number footer.
- [ ] Parse the manuscript's headings, paragraphs, bullet lists, numbered lists, tables, code fences, and callout markers into ReportLab flowables without dropping Thai text.
- [ ] Add cover pages, generated contents pages, section hierarchy, source references, and document metadata for each PDF.
- [ ] Keep long code/command lines wrapped inside the page width and repeat table headers when tables span pages.
- [ ] Make the generator deterministic so rerunning it produces the same filenames and layout inputs.

### Task 4: Generate and verify PDF artifacts

**Files:**
- Modify: `task_plan.md`
- Generate: `output/pdf/safevege-user-manual-th.pdf`
- Generate: `output/pdf/safevege-developer-manual-th.pdf`
- Generate temporarily: `tmp/pdfs/user-page-*.png`, `tmp/pdfs/developer-page-*.png`

**Interfaces:**
- Consumes: `tools/generate_safevege_manuals.py`, both manuscripts, and the approved PDF operation marker.
- Produces: two readable PDFs and rendered page images for inspection.

- [ ] Run `node container_tools/mark_artifact_operation_started.mjs --operation-kind create --expected-output-count 2 --output-format pdf` exactly once immediately before the first PDF generation command.
- [ ] Run the generator and record its exit code and output paths.
- [ ] Run `pdfinfo` on both PDFs and confirm page counts are greater than zero.
- [ ] Run `pdftotext` or `pdfplumber` to confirm Thai headings, key commands, API prefix, and schema table names are extractable.
- [ ] Run `pdftoppm -png` for every page into `tmp/pdfs/`.
- [ ] Inspect every rendered page using the image viewer and record any repair needed in `task_plan.md`.

### Task 5: Repair, final audit, and handoff

**Files:**
- Modify: `docs/manuals/safevege-user-manual.md` or `docs/manuals/safevege-developer-manual.md` only when a verification issue is found
- Modify: `tools/generate_safevege_manuals.py` only when a layout issue is found
- Modify: `task_plan.md`

**Interfaces:**
- Consumes: verification output and rendered page inspection.
- Produces: final PDFs with no known clipping, missing glyphs, stale placeholders, or unsupported claims.

- [ ] Re-run generation after any content/layout repair and repeat extraction plus rendering checks.
- [ ] Confirm both PDFs embed a Thai font and contain footer/page numbering.
- [ ] Confirm the user guide has no required developer setup steps and the developer guide includes the database/API/setup details approved in the spec.
- [ ] Confirm `git status` shows only intentional manual deliverables plus the pre-existing Flutter edits; do not stage or revert unrelated edits.
- [ ] Update `task_plan.md` with exact verification commands, page counts, and any limitations.
- [ ] Deliver both PDFs with concise descriptions and no claim beyond the recorded evidence.
