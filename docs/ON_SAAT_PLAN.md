# 10 Saatlik Final Plan (rapor + sunum + kod)

## Saat 0–1 — Rapor (Word)
- [x] `python3 scripts/fix_trafikpuls_report.py` → Desktop **TRAFİKPULS_FIXED.docx**
- [ ] Word’de aç: her resmin altına **Caption** (Figure 9.1 …)
- [ ] **Table 2.1** tablosu yoksa 2.2’ye ekle (aşağıdaki tablo)
- [ ] References → **Update Table of Contents**
- [ ] PDF: `TRAFIKPULS_UzayDemir_210218027.pdf`

### Table 2.1 (Word’e yapıştır)

| Existing apps | TrafikPuls |
|---------------|------------|
| Route / schedule info | Route info + live density |
| Static experience | Feedback-influenced score |
| Limited personalization | Favorite route + threshold alerts |
| Fragmented tools | Map + ETA + incidents + alternatives |

---

## Saat 1–2 — Sunum PPT
- 12 slayt: kapak, problem, mimari (Figure 5.1), modüller, demo, ML, test 27/27, limits, sonuç
- `SUNUM_YARIN.md` metnini slaytlara böl

---

## Saat 2–3 — Demo provası
```bash
./scripts/run_demo.sh
```
- Login → M4 → panel → feedback → profil
- Render cold start: sunumdan 2 dk önce uygulamayı aç

---

## Saat 3–4 — Render env (opsiyonel canlı IBB)
Render Dashboard → Environment:
- `ADMIN_EMAILS` = senin Firebase email
- `IBB_STOPS_API_URL` / `IBB_TRAFFIC_API_URL` (varsa)

---

## Saat 4–5 — Kod (yapıldı)
- [x] Default API → Render
- [x] `train_model.py` — `cd backend && python3 train_model.py`
- [x] Admin `ADMIN_EMAILS` + `X-User-Email` header
- [x] `TRAFİKPULS_FIXED.docx`

---

## Saat 5–10 — Buffer
- Sunum provası x2
- Jüri soruları (`SUNUM_YARIN.md`)
- Acceptance PDF yanında taşı
- Uyku

---

## Bilinçli olarak yapılmayan (söyle, sorun değil)
- Tam FCM broadcast
- Gerçek IBB her hat
- Enterprise RBAC
