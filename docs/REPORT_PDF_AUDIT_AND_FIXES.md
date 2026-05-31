# TRAFIKPULS.pdf — Audit & Remaining Fixes

Based on **TRAFIKPULS.pdf** (34 pages) vs project code.

---

## PDF vs project — summary

| Item | PDF | Code | Action |
|------|-----|------|--------|
| Core app (login, map, ML, feedback) | Described | Implemented | OK for demo |
| 27 acceptance tests | Conclusion mentions | PDF report exists | OK |
| Student no **210218027** | Missing on cover | — | **Add in Word** under PREPARED BY |
| Duplicate heading block (Ch 6→11 titles only) | Pages ~7–9 | — | **Delete in Word** (see below) |
| Figure captions (5.1, 7.x, 9.x) | Not in text | SVGs in `docs/` | **Add captions** in Word |
| List of Figures / Tables | Missing | — | **Insert** (text in `LIST_OF_FIGURES_AND_TABLES.md`) |
| Table 2.1 reference | Missing | Table may exist | Add one sentence in 2.2 |
| Section 9 UI text | Headings + images only | Screenshots OK | Add 2–3 sentences + captions per figure |
| Acknowledgment tone | "our", "thesis" | — | Optional: change to "I", "graduation project" |
| Default API URL | Render in text | Was local emulator | **Fixed** → Render default in `app_config.dart` |

---

## Word fix (before final PDF) — 15 minutes

### 1) Delete duplicate outline (critical)

After **Declaration / Ethics** and before real **1. INTRODUCTION** body, remove the block that is **only titles**:

`1) Introduction` … through `11) References` **with no paragraphs under them**.

Keep the second copy where full text starts at **"1. INTRODUCTION"** and **Objective** has real paragraphs.

### 2) Cover

```
PREPARED BY:
Uzay Demir
210218027
```

### 3) Add captions under each image

Copy from `docs/LIST_OF_FIGURES_AND_TABLES.md`.

### 4) List of Figures (new page after TOC)

References → Table of Figures → Automatic Table 1 (if captions use **Caption** style).

Or paste manual list from `LIST_OF_FIGURES_AND_TABLES.md`.

### 5) One sentence in Section 2.2

> A summary comparison is presented in **Table 2.1**.

### 6) One sentence in Section 5 (before or after architecture image)

> The overall system interaction is illustrated in **Figure 5.1**.

### 7) Section 7 headings — line break

Change  
`7.2 Use Case DiagramThe main actor`  
to  
**7.2) Use Case Diagram** (new paragraph) The main actor…

Repeat for 7.3–7.7 if merged.

### 8) Re-export PDF

File → Save As → **TRAFIKPULS_UzayDemir_210218027.pdf**

---

## Code / demo (done in repo)

- `lib/config/app_config.dart` — default API = Render HTTPS
- `scripts/run_demo.sh` — flutter run with cloud API
- `scripts/run_backend_local.sh` — local Flask
- `backend/.env.example` — IBB env template
- `SUNUM_YARIN.md` — presentation cheat sheet

---

## Still prototype (do not claim as done)

- Full IBB live data on all lines (needs Render env vars)
- Server-side FCM broadcast
- Admin RBAC
- Real model retrain pipeline

Say in defense: *"prototype stage; documented as future work."*
