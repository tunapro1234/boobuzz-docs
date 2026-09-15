# CHANGELOG — BOOBUZZ 2026-27

Gün bazlı kayıt. Her günün altında repo bazlı değişiklikler, commit hash'leri ve
**hangi ajanın yaptığı** yazılıdır. En yeni gün üstte.

> **Dal notu.** Faz 1 çalışması dokümanlarda `dev-phase-1` dalı olarak geçer
> (takım lideri kararı). Kod depolarında bu dalın fiziksel adı geçici olarak
> `dev-phase-2`; yeniden adlandırma kod tarafında ayrıca yapılacak. Aşağıdaki
> hash'ler değişmez.

> **Ajan kısaltmaları.** `ftc-main` = Claude Fable 5.1 orkestratör ·
> `ftc-main-cx` = geçici koordinasyon (Codex) · `robot-cx-NN` / `sim-cx-NN` =
> Codex (gpt-5.6) iş ajanı görevleri · `review` = sıfır bağlamlı Claude Opus
> review subagent'ı · `Tuna` = insan. Ayrıntı: `README.md` § AI metodolojisi.

---

## 2026-09-15 — Faz 0 kapandı, Faz 1 açıldı; Pedro oturdu, sim fiziği gerçekleşti

Sezonun ilk tam çalışma günü ve şimdiye kadarki en yoğunu. Anlatı hâli:
`gunluk/2026-09-15.md`.

### robot-code (Java)

**Faz 0 kapanışı** — `stable` @ `17c8cc3`
- `17c8cc3` Faz 0: `:core` / `:sim` modül bölünmesi ve C1 sim köprüsü — *ftc-main + ftc-robot*
  - `:core` saf Java, FTC SDK importu build'i kırıyor (guard kanaryayla doğrulandı)
  - 31 test yeşil; `SimMain` gerçek Python sunucusuna karşı 500 adım, aynı seed
    iki koşuda **bit-bit aynı** sonuç
- `567667f` Field-oriented sürüş: stick saha çerçevesinde, dönüşüm L3'te biter — *ftc-robot*
- `c9907c9` `SimMain`: viewer kapanınca temiz çıkış, stack trace yok — *ftc-robot*

**Faz 1 / `robot-cx-01` — Pedro Pathing 3.0 HAL üstüne** (spec: `gorevler/robot-cx-01-pedro-hal.md`) — *ftc-robot-cx (Codex)*
- `85be43f` HAL Pinpoint verisini Pedro localizer'a bağla
- `15e5721` Pedro drivetrain çıkışını HAL eylemine bağla
- `8a3d030` Pedro follower ve yol motorunu ekle
- `6e129ea` Sim koşucusuna Pedro engine ve yol seçimi ekle
- `67460be` Pedro HAL ve engine davranışlarını test et
- `dd4bd3f` Localizer son HAL durumunu saklasın
- Sonuç: 47/47 test yeşil, SDK guard geçti. Entegrasyon koşusu (port 5556,
  `test-line`, 1000 adım, seed=1): kabul aralığına **68. adımda** (1.36 s) girdi,
  son truth `(120.0030, 71.9562, 0.0001)`; iki koşu bit-bit aynı.
- Keşif çıktısı (Pedro 3.0 gerçek imzaları — jar'dan `javap` ile): `followPath`,
  `holdPoint`, `PathConstraints` **yok**; karşılıkları `follow`, `hold`,
  `ForesightConfig`. `DrivePowers` alan sırası `forward, strafe, turn`.

**Review** — sıfır bağlamlı Claude Opus subagent'ı, diff `c9907c9..dd4bd3f` — *review*
- BLOKER yok; 4 ÖNEMLİ + 8 KÜÇÜK bulgu → `gorevler/robot-cx-03-review-duzeltme.md`

**`robot-cx-03` — review düzeltmeleri** — *ftc-robot-cx (Codex)*
- `ceff098` Heading offsetinde localizer hızını döndür (A1 — `setPose` heading
  değişince `twist()` yanlış dönüyordu)
- `0a81e42` Doygun tabanda Pedro güç ölçeğini durdur (A2 — `maxScaling`)
- `6ae4e52` Localizer twist dönüşümünü doksan derecede test et (A3)
- `9ac5ce8` Pedro 3'te kullanılmayan kütle sabitini sil (A4 — `ForesightConfig`'de
  kütle alanı **bulunamadı**, ölü sabit silindi)
- `3c115a7` Review küçük düzeltmelerini tamamla (B1–B8; `reset()` heading sarma
  hatası — `6.282678 rad` çıktısının kaynağı — burada kapandı)

**`robot-cx-02` — katman ağacı envanteri** (ÖNCE RAPOR, kod yok) — *ftc-robot-cx (Codex)*
- Çıktı: `gorevler/robot-cx-02-rapor.md` (mevcut ağaç + katman etiketleri, taşıma
  listesi, Gradle yönü, riskler)
- `ftc-main` + Tuna kararı: raporun §2 önerisi (L2/L3'ü TeamCode dışında tutmak)
  **reddedildi**; bağlayıcı yerleşim `gorevler/faz1-katman-plani.md`'ye yazıldı —
  üç katman `TeamCode/` içinde, `:core` fiziksel olarak `TeamCode/core/`

**`robot-cx-04` — katman taşıma** (`gorevler/faz1-katman-plani.md`) — *ftc-robot-cx (Codex)*, `dev-phase-1`'de sürüyor
- `981b8a9` Core modülünü TeamCode altına taşı
- `acd0c1c` SDK guard taramasını sourceSet'lere bağla (guard'ın sessizce ölme
  riski — `robot-cx-02` §6 — burada kapatıldı)
- `a516504` Sözleşme ve controller paketlerini ayır
- `3539fe1` L2 motor ve Pedro kodunu logic altına taşı
- `868a50d` Core testlerini katman paketlerine aynala
- `7c8bf60` Drive davranışını subsystem altında birleştir
- `a0edfe1` TeamCode HAL ve OpMode paketlerini ayır
- `2620514` **`RealHal`** ile robot donanımını ortak `:core`'a bağla — robot
  tarafında ilk gerçek HAL implementasyonu (o güne kadar TeamCode'da `RealHal` yoktu)
- `e41d59a` Sim fizik parametrelerini robot kaynağına eşitle (`mechanism.yaml`
  `physics:` bloğu)

### re-cock-nize (Python sim)

**Faz 1 taşıma + sim sunucusu** — *ftc-sim / ftc-main*
- `f1e1f52` Mimari temizliği: `ftc_sim` → `java_runner`, `game_sim` ayrıldı
- `ed0515f` Faz 1 taşıma kararı: **8.614 satırdan 704'ü kalıyor**
- `a4856e8` Faz 1: sim sunucusu, mecanum fiziği, üstten saha görünümü
- `4757c1c` Çerçeve kuralı: robot x ileri / y sol (`protokol.md` güncellemesi)
- `8165ba2` Saha orijini köşeye: x,y ∈ [0,144]
- `43c6e73` `ready` mesajı ilk durumu taşıyor

**Saha görseli ve koordinat doğrulaması** — *ftc-sim-cx (Codex) + Tuna (görsel onayı)*
- `1605dda` Saha görünümü: karo ızgarası, duvarlar, eksen okları, periyodik poz logu
- `d3b94d7` BIOBUZZ düzeltmesi + bağlantı beklerken pencere donmuyor
- `bd853e6` Saha arka plan görseli yolu + hizalama parametreleri (görsel henüz yok)
- `d35d18f` Panel not satırları panele sığıyor
- `38051f4` BIOBUZZ saha görseli: **90° CW, 141 inç, ortalanmış**
- `8501168` İttifak kenarları görsele uydu: **kırmızı x=0, mavi x=144**

**Kararlılık + klavye** — *ftc-sim-cx (Codex)*
- `bdd5cee` Klavye → `state.gamepad` yolunu testle bağla
- `f4bea22` SIGTERM/SIGINT ile temiz kapanış
- Doğrulama: `./run_tests.sh` → 44 geçti, 6 atlandı

**`sim-cx-01` — motor elektriği + gerçek mecanum kinematiği + kalibrasyon**
(spec: `gorevler/sim-cx-01-motor-mecanum-fizik.md`) — *ftc-sim-cx (Codex)*
- `0770dd6` Motor elektriğini YAML parametrelerine bağla — batarya voltajı
  (`battery_v: 12.0`), motor zaman sabiti (`motor_tau_s: 0.1`), teker başına
  verimlilik (`efficiency`, hepsi 1.0 — **ölçülmedi**) `physics:` bloğuna taşındı
- `f048c86` Mecanum fiziğini sezon verileriyle kalibre et — en küçük kareler
  kinematiği korunarak yanal hız verimi (`strafe_eff: 0.7346 = 54.09/73.63`)
  uygulandı; sıfır güçte ileri/yanal hızlar ölçülmüş ivmelerle (`36.17` / `85.98`
  in/s²) sıfıra çekiliyor; fixture teker devri `73.63 in/s`'den türetildi
  (`free_rpm: 351.557` — doğrudan RPM verisi **bulunamadı**)
- `41c637b` Kalibre fizik davranışlarını testlerle kilitle — ileri/yanal kararlı
  hız, sıfır-güç durma mesafesi, motor gecikmesi, verimlilik ve mecanum
  işaretleri; determinizm programı kayma evresini de kapsıyor
- Kaynak: geçen sezon `archive/ftc/de-cock` `pedroPathing/Constants.java`; her
  parametrenin yanına kaynak yorumu yazıldı

### docs

- `plan.md` güncellendi: eski Faz 1 (sim) / Faz 2 (C1) / Faz 2.5 (Pedro) **tek
  Faz 1'e katlandı**; Faz 0 "BİTTİ" olarak işaretlendi — *ftc-main*
- `mimari.md` §0 "Dizin yerleşimi" eklendi (üç katman `TeamCode/` içinde) — *ftc-main*
- `protokol.md`: çerçeve kuralı, saha orijini, `ready` mesajı, `physics:` bloğu — *ftc-main*
- `gorevler/`: `robot-cx-01`, `robot-cx-02` (+rapor), `robot-cx-03`, `sim-cx-01`
  spec'leri, `faz1-katman-plani.md`, `devir-ftc-main-cx.md`, `devir-rapor.md`
- Bu depo kuruldu: `README.md`, `CHANGELOG.md`, `gunluk/`, `engine-iterasyonlari/`

### Koordinasyon olayları

- ~06:50 — `ftc-main` model limitine takıldı; koordinasyon geçici olarak
  `ftc-main-cx`'e (Codex) devredildi. Tuna'nın şartı: **aşamayı tamamla ama
  `ftc-main` kontrol etmeden bir sonraki aşamaya geçme.** Devir notu:
  `gorevler/devir-ftc-main-cx.md`.
- Limit sıfırlanınca koordinasyon `ftc-main`'e geri döndü; `ftc-main-cx` devir
  raporunu yazdı (`gorevler/devir-rapor.md`) ve review başlatıldı.
- `ftc-ball-cx` gün boyu **beklemede** tutuldu (Tuna kararı: aktif kapsam yalnız
  robot + sim).

---

## 2026-09-14 — Geçen sezonun envanteri ve yeni iskelet

### robot-code

- `bcf82ce` FTC SDK 12.0 + Pedro Pathing 3.0 iskeleti — *ftc-main + Tuna*
- `5fc8c47` `docs/miras`: geçen sezon kod envanteri, konu konu — *Claude envanter ajanı*
  - 12 dosya, geçen sezonun ~70.800 satırı konu konu taranıp **[A] maçta koştu /
    [B] robotta koştu / [C] test edilmedi / [D] simde koştu** etiketleriyle
    sınıflandırıldı
  - Tuna'nın uyarısı kayda geçti: "contingency dışındaki kodlar test edilmedi,
    mimariler temiz olsa bile take it with a grain of salt"
- Bu envanter `plan.md`'nin Gall's Law çerçevesinin kanıt tabanı oldu.

---

## Sezon öncesi — DECODE 2025-26 mirası

BIOBUZZ sezonu başlamadan önce elde olan iki Python deposu. Bu depoların o
sezondaki günlük kaydı tutulmadı; aşağıdaki liste git geçmişinden çıkarılmış
**gün ve konu** özetidir, hepsi insan (Tuna + takım) eliyle yazılmıştır.
Bu sezonda `re-cock-nize` 8.614 satırdan 704 satıra indirildi; `ball-auto-istic`
beklemede (plan.md: "B5/RK4 bu sezon yok").

### re-cock-nize (sim)

| Gün | Konu | Commit'ler |
|---|---|---|
| 2025-12-11 | Mimari temizliği, direct mode, task cancel | `df52bfd` `40a161f` `31c7f35` `9938252` `e06cb7e` `4150812` |
| 2025-12-10 | Otonom ve büyük değişiklikler | `4529faa` `89784e6` |
| 2025-12-09 | PyBullet denemesi | `169619d` `bcd04e9` |
| 2025-12-07 | Vision logic | `7db83b8` |
| 2025-12-06 | Robot kodu güncellemesi | `9b9cf59` |
| 2025-12-05 | Balistik | `0d8fff2` |
| 2025-12-04 | Replay, cartographer, Java taban, pure rotation, temel RL | `fe916ae` `8879fdb` `2096428` `b3915e4` `1b7d70a` `6697ba9` `b87d262` |
| 2025-12-03 | Gate mantığı ve akışı, animasyon, Python logic'in kaldırılması | `401d1ae` `5e713b5` `a4d64cc` `f97da15` `22c8cbd` `e44e885` `45852dc` `1d1de4b` `1cdfc35` `7574be6` `2706ec9` |
| 2025-12-02 | Sensör grid, sim adapter, interaktifler | `fe0c6d3` `07a3531` `52daa76` |
| 2025-12-01 | Turret Java, drive + shooter, TeamCode'un kaldırılması | `2bfa46a` `b0f86d1` `1ee8347` `f8694de` |
| 2025-11-29 | Subsystem'ler, robot kodlarının eklenmesi | `cb44336` `d61d266` |
| 2025-11-28 | 2D logic test ortamı sadeleştirmesi | `18b6e4c` `090ffa6` |
| 2025-11-19 | Gerçekçi Gate fiziği, top yerleşimi | `c3c123e` `b2d3f99` |
| 2025-11-18 | Top fiziği, field-oriented kontrol | `ff92bf3` `ba141d4` `7a1b144` |
| 2025-11-17 | 60 fps, fizik motoru denemesi | `be87ad1` `79d9ef2` |
| 2025-11-16 | init | `f8e5dda` |

### ball-auto-istic (balistik)

| Gün | Konu | Commit'ler |
|---|---|---|
| 2025-12-07 | `messi` engine tabanı, RK4 doğruluk + optimizasyon, bilinear/bicubic gradient | `fa36174` `0c72f6d` `4d1294d` `4398724` `bb349d7` `e95b4fc` `deac48c` |
| 2025-12-06 | `ronaldinho` engine, Monte Carlo, hedef hacim entegrasyonu, vx/vy grafikleri | `a7b5c64` `1eb7ce3` `4d32122` `d42e6a9` `80419b9` `7b38a0d` `a332a47` |
| 2025-12-05 | Kalibrasyon, senaryoların kaldırılması | `9336c3f` `83b2eca` `e881867` |
| 2025-11-21 | Kalibrasyon araçları, slow-motion varsayılanları | `58a4cdf` |
| 2025-11-20 | Caliber dinamik tuning | `24de1f3` `fb4303a` |
| 2025-11-19 | Python video kalibrasyon araçları, Java solver fizik güncellemeleri | `2cd1419` `5bc2d87` `308c70b` `645ba83` |
| 2025-11-18 | Auto-aim, 3D görselleştirme, lineer spin modeli, proje yapısı ayrımı | `25d2c1b` `df10078` `50617ff` `78fbaf6` |
| 2025-11-13 | init, 254 örnek kodları, dosyalara bölme, aynalı hedefler, 3D saha | `bb79825` `d3939a8` `135fdac` `0cde7d7` `b4804ed` `3259174` |

> 2026-09-15 itibarıyla `ball-auto-istic`'te yalnız `cf45945` (messi çıktısı +
> FRC klasörü) bu sezona ait; depo Tuna kararıyla beklemededir.
