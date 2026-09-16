# BOOBUZZ — Zağanos #25577, 2026-27 sezon yolculuğu

Bu depo **kod değil, yolculuk** tutar. FTC takımı **Zağanos #25577**'nin 2026-27
**BIOBUZZ** sezonunda robot yazılımını nasıl kurduğunun günü gününe kaydı: plan,
mimari kararları, görev spec'leri, ajan raporları, changelog, günlükler ve her
logic engine iterasyonunun karşılaştırması.

Yazım dili **Türkçe**. Sezon içinde Chief Delphi'de yayımlanmak üzere bu
dokümanların **İngilizce özeti** ayrıca çıkarılacak (`en/` klasörü açılacak,
henüz yok).

---

## Neden bu depo var

Geçen sezon (DECODE 2025-26) **~70.800 satır yazıldı, 10.751'i maça girdi — %15.**
289 dosya / 60.060 satır tek commit'te silindi. Mimariler temizdi; hiçbiri
çalışmadı, çünkü hepsi altındaki katman çalışmadan önce yazılmıştı. Bu sezonun
birinci kuralı bunu tekrarlamamak (`plan.md`, Gall's Law kutuları).

Geçen sezon doküman tarafında ~60 sayfalık bir çıkarım yapmıştık
(`robot-code/docs/miras/`, kanıt etiketli kod envanteri). Bu depo onun devamı:
bu kez **süreci** de yazıyoruz, sonucu değil sadece.

---

## Nasıl gezilir

| Dosya | Ne işe yarar |
|---|---|
| `plan.md` | Faz 0 → Faz 6 yol haritası, engine (C1–C5) ve balistik (B1–B4) merdivenleri. **Tek bağlayıcı sıra.** |
| `mimari.md` | Katmanlar (L1 HAL / L2 logic / L3 controller), dizin yerleşimi, sözleşmeler. **Nereye yazacağımız.** |
| `protokol.md` | Java ↔ Python sim köprüsü (L1 seam), `mechanism.yaml` şeması, çerçeve kuralı. **Bağlayıcı; yalnız `ftc-main` günceller.** |
| `CHANGELOG.md` | Gün bazlı, repo bazlı, commit hash'li değişiklik kaydı; hangi ajanın yaptığı yazılı. |
| `gunluk/` | Her gün bir dosya: ne denendi, ne yanlış gitti, ne öğrenildi. Şablon: `gunluk/SABLON.md`. |
| `engine-iterasyonlari/` | Her logic engine iterasyonu için karşılaştırmalı doküman (C1, Pedro, …). |
| `phases/phase-1/` | Ajanlara verilen görev spec'leri — yolculuğun ham kaydı. Park edilen raporlar `_parked/` altındadır. |

Okuma sırası ilk kez gelen biri için: bu dosya → `plan.md` → `mimari.md` →
`CHANGELOG.md` → `gunluk/` (en yeniden geriye).

---

## AI metodolojisi — saklamıyoruz, tam tersi

Bu sezonun yazılımı **hiyerarşik bir AI ajan düzeniyle** üretiliyor. Bu bir
utanç kaynağı değil, takımın bilinçli bir mühendislik tercihi; ve bu deponun
varlık sebeplerinden biri de tam olarak bunu şeffaf biçimde belgelemek.

### Düzen

```
                    İNSAN — Tuna (takım lideri)
        karar · spec onayı · kabul ölçütü · "bu olmadı" deme yetkisi
                              │
                    ┌─────────▼──────────┐
                    │  ftc-main          │  Claude (Fable 5.1) — ORKESTRATÖR
                    │  plan · protokol   │  görev yazar, review başlatır,
                    │  koordinasyon      │  kimse onun izni olmadan faz atlamaz
                    └─┬────────┬───────┬─┘
                      │        │       │
        ┌─────────────▼┐  ┌────▼─────┐ └──▼───────────┐
        │ ftc-robot-cx │  │ftc-sim-cx│    │ftc-ball-cx │   Codex (gpt-5.6)
        │ Java / core  │  │ Python   │    │ balistik   │   İŞ YAPAN AJANLAR
        │ TeamCode     │  │ fizik    │    │ (beklemede)│
        └──────┬───────┘  └────┬─────┘    └────────────┘
               │               │
        ┌──────▼───────────────▼──────┐
        │  Claude Opus review ajanı   │  SIFIR BAĞLAM — diff'i ilk kez görür,
        │  + temizlik subagent'ları   │  "çalışıyor" iddiasına inanmaz
        └─────────────────────────────┘
```

**Roller**

- **İnsan (Tuna).** Kararı verir: hangi faz, hangi yerleşim, neyi kesiyoruz. Spec'i
  onaylar, raporu okur, kabul eder ya da reddeder. Ajanlar hiçbir mimari kararı
  kendi başına vermez — `phases/phase-1/*.md` dosyalarındaki "Tuna'nın şartları
  (bağlayıcı)" blokları bunun kaydıdır.
- **`ftc-main` — Claude (Fable 5.1), orkestratör.** `plan.md`, `mimari.md`,
  `protokol.md`'nin tek sahibi. Görev spec'lerini yazar (kabul ölçütleri, yasaklar
  ve "yapılmayacaklar" listesiyle birlikte), gelen raporu ölçütlere karşı denetler,
  review başlatır, sonraki aşamayı açar.
- **Codex ajanları (gpt-5.6) — `ftc-robot-cx`, `ftc-sim-cx`, `ftc-ball-cx`.** Asıl
  kodu bunlar yazar. Her biri tek repo/tek dal üzerinde, net spec ile çalışır;
  spec dışına çıkmaz, "muhtemelen" yazmaz, bulamadığını **bulamadım** diye
  raporlar. Her bağımsız parça ayrı commit + anında push → GitHub üzerinden
  adım adım izlenebilirlik.
- **Sıfır-bağlamlı Claude Opus review/temizlik subagent'ları.** Bir diff'i,
  onu üreten konuşmayı hiç görmeden inceler. Bağlam yokluğu özelliktir: yazan
  ajanın "bunu zaten konuşmuştuk" savunması review'a ulaşmaz. `robot-cx-03`
  görevi (`phases/phase-1/robot-cx-03-review-duzeltme.md`) doğrudan böyle bir
  review'ın çıktısıdır — A1'den B8'e kadar madde madde.
- **`bp` (blueprint).** Ajanların haberleştiği tmux tabanlı ajan altyapısı.
  `bp msg <ajan>` ile mesaj, ayrı tmux oturumlarında canlı paneller. Hiyerarşik
  düzeni mümkün kılan şey bu: ajanlar birbirini görüyor, insan hepsini görüyor.

### Neden böyle

1. **Bağlam pahalı.** Orkestratörün bağlamı planla dolu; implementasyon detayı
   onu kirletir. İş yapan ajan spec'i alır, kendi bağlamını doldurur, raporla
   döner. Orkestratör raporu okur, diff'i değil.
2. **Review'ın bağımsız olması lazım.** Kodu yazan ajan kendi kodunu onaylayamaz.
   Sıfır bağlamlı ikinci bir model, diff'i taze gözle okur.
3. **Model başına doğru iş.** Mekanik, net spec'li, bol token isteyen implementasyon
   Codex'e; plan/mimari/karar Claude'a; şüpheci okuma Opus'a.
4. **İzlenebilirlik.** Her commit'in altında hangi oturumda üretildiği yazıyor
   (`Claude-Session:` dipnotu). Hangi ajanın ne yaptığı `CHANGELOG.md`'de.

### Sınırlar — bunu da yazıyoruz

- Ajanlar **tahmin ettiğinde** işe yaramıyor. Spec'lere "tahmin yok; her iddia bir
  komut çıktısına dayansın" satırını koymak zorunda kaldık; koymadığımızda
  "çalışıyor" raporu geldi, çalışmıyordu.
- Ajan teslimatı bazen kayboluyor (bkz. `gunluk/2026-09-15.md` — Codex panelinde
  doğrulanmayan `bp msg`).
- Orkestratör limitine takılabiliyor; 15 Eylül'de koordinasyon geçici olarak bir
  Codex ajanına devredildi (`_parked/phases/phase-1/devir-ftc-main-cx.md`, untracked), sonra geri alındı.

---

## Depo düzeni

- Tek dal: **`stable`**. Doküman deposu için dallanmaya gerek yok.
- Kod depoları ayrı: `robot-code` (Java, FTC SDK + `:core` + `:sim`),
  `re-cock-nize` (Python sim/fizik), `ball-auto-istic` (balistik, bu sezon
  beklemede). Onların dal düzeni: `stable` / `dev` / `dev-phase-N`.
- `_parked/` untracked handoff/report dosyalarını tutar; geçmiş notlar yerelde korunur.
- Bu depodaki hiçbir dosya kod üretmez; kaynak kodun tek gerçeği kod depolarıdır.

## Durum (15 Eylül 2026)

- **Faz 0 — İskelet: BİTTİ** (`robot-code 17c8cc3`).
- **Faz 1 — Katmanlar + Pedro + gerçek sim fiziği: sürüyor**, dal `dev-phase-1`.
- Robot henüz elimizde yok → kanıt sim'de üretiliyor; robot geldiğinde **aynı
  bytecode** robota çıkacak.
