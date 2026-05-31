# Sunum — TrafikPuls (5 dk demo)

## Sunum öncesi (5 dk)

1. Telefonda/emülatörde uygulamayı **bir kez aç** (Render uyanır, ~30 sn)
2. Giriş: `demor.uzay@gmail.com` + şifren
3. **Profil → Dil** isteğe bağlı English
4. Haritada **M2** veya **500T** dene — rota çizgisi düzgün mü bak

> **Rota çizgisi hâlâ yanlışsa:** Backend henüz Render’a gitmemiş demektir. Tahmin + bildirim yine çalışır; haritada rota yerine **yoğunluk paneli**ne odaklan.

```bash
./scripts/run_demo.sh
```

---

## Açılış (20 sn)

> Merhaba, ben Uzay Demir, 210218027. TrafikPuls — İstanbul’da hat bazlı yoğunluk tahmini ve yolcu bildirimlerini birleştiren mobil bir karar destek uygulaması.

---

## Demo akışı (3–4 dk)

| # | Ne yap | Ne söyle |
|---|--------|----------|
| 1 | Giriş yap | Firebase Auth, kullanıcı profili |
| 2 | Haritada **M2** ara, seç | Hat arama + durak/rota haritada |
| 3 | Alt panel açılır | Anlık yoğunluk, **güven skoru**, 30/60 dk tahmin |
| 4 | **Aktif Olaylar** (varsa) | Olay/g gecikme bilgisi |
| 5 | **Report** → **Full** → kaydet | Crowdsourcing, Firestore |
| 6 | Haritaya dön | Tahmin güncellenir (`/report_density`) |
| 7 | Profil → Admin (senin mail) | Admin-lite metrikler *(opsiyonel)* |

**Yedek hatlar:** `500T`, `34B`, `T1` — aynı akış.

---

## 3 teknik cümle (soru gelirse)

- **Mimari:** Flutter + Firebase + Flask backend (Random Forest)
- **Veri:** Kullanıcı feedback → Firestore + API → tahmine karışır
- **Kapsam:** Prototype; canlı IBB API env ile genişletilebilir, 27 acceptance test Pass

---

## Sık sorular — kısa cevap

| Soru | Cevap |
|------|--------|
| Canlı IBB verisi? | Env ile desteklenir; sunumda mock + statik güzergah |
| Production ready? | Mezuniyet prototipi; FCM/tam RBAC sonraki adım |
| Neden Random Forest? | Tabular veri, hızlı inference, açıklanabilir |

---

## Sorun çıkarsa

| Problem | Çözüm |
|---------|--------|
| Tahmin gelmiyor | Render uyuyor; 30 sn bekle veya tekrar hat seç |
| Giriş olmuyor | Hot restart `R`; Firebase Auth’ta kullanıcı var mı bak |
| Admin görünmüyor | Sadece `demor.uzay@gmail.com` |
| Rota garip | Sunumda panele odaklan; backend deploy sonrası düzelir |

---

## Komutlar

```bash
# Uygulama (Render API)
./scripts/run_demo.sh

# Backend canlı mı?
curl https://stanbul-traff-c-forecast.onrender.com/health
```
