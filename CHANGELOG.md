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

## 2026-09-25 — Spec düzeltmesi: drive end hold, socket tek teslim, B09 nectar yeri

### docs

- **Drive end hold (ftc-main onayı, arşivden doğrulandı).** Spec 00'a eklendi:
  GOTO/PATH/TURN_TO `DONE` sonrası iki engine de son pozu tutar (arşiv
  AutoBuilder.java:764-768 bitişte stop yok; simple-code DriveSubsystem.java:66 hold).
  Hold'u yalnız yeni drive request, manual drive, o id'nin cancel'ı, CANCEL_ALL ve
  RESET_POSE bitirir. R `590b98e`; A-drive .54 in hatasını çözdüğü `evidence-B.md`'de.
  (ftc-robocode)
- **R4.5 SocketController metni (ftc-main onayı).** "Her tick son alınan batch
  kullanılır" yerine: manual-drive seviyesi her tick taşınır, request/cancel batch
  başına bir kez tüketilir (yeniden teslim yok). R `7174d77`. (ftc-robocode)
- **B09 B-collect-feed nectar (54,78) → (54,84) (ftc-main kararı).** 18 in robot y=72
  hattında y63..81'i süpürüyor; (54,78) gövdeyle temas ediyordu. 82.8 tam temas sınırı,
  84 seed42 ±.1 için marj. "untouched" tanımı değişmedi; rolling resistance eklenmedi
  (kaynak yok), sürtünmesiz zemin sim sınırlaması olarak evidence'a yazıldı.
  (ftc-robocode)

---

## 2026-09-25 — Spec düzeltmesi: drive FLOAT (B01) ve B05 reset metni

### docs

- **Drive BRAKE → FLOAT (ftc-main onayı, arşivden doğrulandı).** Spec 02 ve
  `hardware-profile-v0.md` "mevcut drive BRAKE değişmez" diyordu. Arşiv drive için
  zero-power modu ayarlamıyor, bunu Pedro 2.0.4'e bırakıyor. Pedro'da Mecanum
  constructor `setMotorsToFloat` çağırıyor, `breakFollowing` FLOAT kullanıyor ve
  `startTeleopDrive` yalnızca `useBrakeModeInTeleOp=true` ise BRAKE yapıyor
  (arşivde bu false). simple-code de FLOAT. Kod tarafındaki FLOAT doğru; spec
  metni düzeltildi. (ftc-robocode)
- **B05 reset metni (ftc-main onayı, arşivden doğrulandı).** Spec 03 B05
  "hedef değişimi/disable/geçersiz sensörde controller ve dwell temizlenir"
  diyordu. Arşivde (`ShooterPidfPowerSubsystem:64-68`, `:79-86`) >50 RPM hedef
  değişimi yalnızca hazırlık bayrağını ve sayacını sıfırlıyor; integral ve önceki
  hata yalnızca disable'da sıfırlanıyor. Kod bunu izliyor (robot-code 393dbc1).
  Tuning değişiminde ve sensör kaybında tam reset arşivde yok (tuning statik,
  sensör kaybı kavramı yok). Bunlar güvenlik eklemesi olarak kabul edildi ve
  spec'te ve kodda "deliberate non-archive addition" diye işaretlendi. (ftc-robocode)

## 2026-09-25 — Spec düzeltmesi: hood_left yönü (B01/B06)

### docs

- **Spec düzeltmesi (ftc-main onayı, arşivden doğrulandı).** B01 metni ve
  `adr-device-seam-v2.md` hood_left için `REVERSE, initial 1.0` diyordu. Arşiv
  `HoodSubsystem` hiçbir servonun yönünü ayarlamıyor; soldaki tek ters çevirme,
  `mechanicalMax - pos` / `1-u` pozisyon eşlemesi. `REVERSE` ile `1-u` birlikte
  kullanılınca sol servo iki kez ters çevriliyordu. Doğrusu: hood_left `FORWARD`,
  ters çevirme profildeki eşlemede, init'te servo hareketi yok (arşivle aynı).
  `initialPos` yalnızca simülatörün tuttuğu değer.
  Commitler: `cb5779c` (yön, spec 02 B01 metni) ve bu kayıt (ADR init ifadesi).
  Uygulayan: ftc-robocode (Claude Opus 5.5).
- simple-code bunu tersinden çözüyor: sol `REVERSE`, iki servoya aynı pozisyon
  (SDK `REVERSE` = `1-p`). Bu da eşdeğer; simple-code'a dokunulmadı.
- **Backlog:** Hata sim'de görünmedi, çünkü simülatör servo yönünü uygulamıyor.
  Ya sim'e servo direction desteği eklenecek ya da profil yönü ile pozisyon
  eşlemesinin çift ters çevirmesini yakalayan bir test yazılacak.
- **Backlog kapandı (aynı gün, ftc-robocode).** Not yanlış çıktı: sim hood plant'ı
  (S `1ae3da2`) yönü zaten uyguluyordu, ancak Java düzeltmesinden (`e5c633e`)
  sonra yazıldığı için çift ters çevirme sim'de hiç denenmedi. S `77bf256` SDK
  semantiğini (RobotCore 12.0.0: pozisyon clip → REVERSE `1-p`; CR negate → clip)
  tek yerde topladı. Çift ters çeviren profil artık Pymunk hood plant'ında yüklenirken
  reddediliyor ve regresyon testi var. Loader seviyesinde henüz reddedilmiyor (review minor #3).

---

## 2026-09-16 — Faz 1.1 açıldı; R3 sözleşmesine ve çift fizik backend'ine geçiş

Günün anlatısı: `gunluk/2026-09-16.md`. Bu bölümdeki commitler, gün içindeki
`dev-phase-1` tabanından açılan `dev-phase-1.1` çalışmasını da kapsar.

### Koordinasyon ve repo kimlikleri

- GitHub depoları sırasıyla `boobuzz-robocode`, `boobuzz-ballautoistic` ve
  `boobuzz-recocknize` olarak yeniden adlandırıldı; yerel klasör adları
  (`robot-code`, `ball-auto-istic`, `re-cock-nize`) değişmedi.
- Codex iş ajanları `gpt-5.6-luna max` profiline taşındı. Kullanım limiti
  nedeniyle Claude Opus review'ları durdu; çapraz review Codex ajanlarına
  devredildi. Bu bir koordinasyon kararıdır, tek başına bir kod commit'i yoktur.
- Robot kodu ve yorumları `8c23e15`, sim kodu ve testleri `2a6165e` ile
  İngilizceye çevrildi. Faz 1.1 spec/task metinleri de İngilizce tutuldu;
  yolculuk anlatısı bu depoda Türkçe kalır.

### robot-code — `dev-phase-1.1`

`dev-phase-1` üzerindeki RobotConstants tabanı `656f166` ile sabitlendi; yeni
konfigürasyon artık YAML değil derleme-zamanı Java sabitleri. Günün aşamalı
taşıma ve sözleşme commitleri:

- `89d7277` DTO'ları `contract` paketine taşıdı.
- `1b68195` subsystem katmanını ve Pedro sürüşünü ekledi.
- `6e77340` direct ve subsystem-backed engine seçimini bağladı.
- `3d42b41` subsystem olaylarını simülasyon sınırında serileştirdi.
- `f9bec30` core katman bağımlılık yönünü korudu; `9795f38` stub/direct akışını
  test etti.
- `454e876` gamepad DTO'larını sözleşmeye aldı; `01db267` ve `384fc3f`
  otonom istek akışını genişletip yürüttü.
- `6bb87e5` `AutoController`/fluent builder'ı, `5ad15fd` geçen sezonun altı
  otonom rutin verisini, `900dba9` da sim ve FTC girişlerini ekledi. Faz 1.1
  tasarım kabulünde bu altı rutin chassis-only olarak simde kanıtlanmış durumda.
- `9e4b776` Pedro sınırında sonlu motor gücü korumasını ekledi; `87db6cd`
  doğrusal heading yönünü korudu; `2573880` sonlu güç sınır testlerini ekledi.
- `5defadf` R3.1 isim ağacını uyguladı: `IHal`, `IRobotEngine`, `IController`,
  `cplx1`, `direct`, `teleop` ve `opmodes` paket adları.

### re-cock-nize — `dev-phase-1.1`

- `5cc95cf` Python okuyucuyu robot-code'daki `RobotConstants.java` dosyasına
  bağladı; mekanizma YAML'ı artık kaynak değil.
- `461d6a9` backend arayüzü ve kinematik backend'i, `9fe12df` Pymunk rijit
  cisim backend'ini, `cbb0f07` duvar kayması ve determinism testlerini ekledi.
- `5e02ea9` sim adımlarındaki olayları kaydetti; `d753cd8` viewer uyumunu
  backend seçimine taşıdı.
- `e260e02` deterministik PyBullet backend'ini, `fd364c8` yerel PyBullet GUI
  modunu, `486a8d2` iki backend'i birlikte test etmeyi ekledi; `1f23b37`
  robot kütlesini backend testlerine açtı.
- `3ff0113` eski notları `_parked/` altına aldı, `a449b52` bunları ignore etti;
  `9423f12` sanal ortam komutlarını README'ye yazdı.
- `8af8281`, ftc-main'in tick 147'de 10× encoder uyuşmazlığından fark ettiği
  NaN zincirini, encoder entegrasyonunu doğrudan motor teker hızlarına bağlayarak
  düzeltti. Robot tarafındaki `9e4b776` sonlu-güç guard'ı bunun bağımsız güvenlik
  katmanıdır.

### docs ve açık iş

- `2203d83` Faz 1.1 pre-write design spec'i ve faz görevlerini açtı; `73104b0`
  R3 isimlendirme/ağaç, `Request` + `RequestStream`, logic modülleri ve altı
  akış diyagramını kayda aldı; `d2a9a8f` gamepad haritası analizini ekledi.
- Markdown temizliğiyle eski devir/rapor notları `_parked/` altına taşındı
  (`0f13c41`, `28898b2`, `541ce24`).

### R3 completion — robot-code `dev-phase-1.1` — *ftc-robot-cx (Codex)*

After `5defadf`, the remaining R3 implementation landed in order:

- `09f7d71` replaced `Intent` with `RequestBatch`.
- `3dd773f` split the direct request map from `DirectEngine`.
- `3f44c75` added the turret contract and stub.
- `1622a27` added the `cplx1` motion, turret, and shooter logic modules.
- `a4a42a6` added the button map and teleop sequences.
- `f185ce1` moved engine switching to the `RobotLoop` boundary.
- `d4226eb` documented the core architecture in robot-code.

### R4 debug seams — robot-code `dev-phase-1.1` — *ftc-robot-cx (Codex)*

- `c80e4ff` published HAL, subsystem, and logic seam records from the loop.
- `023c273` added deterministic seam bagging; `ad7307c` moved serialization and
  bag I/O off the loop thread.
- `c1921b4` added deterministic bag replay; `0fead81` added the asynchronous
  feedback/command `SocketController`.
- `33ace3f` added the tap and drive command-line tools and real-robot debugging
  notes.

### R5 review fixes and follow-ups — robot-code `dev-phase-1.1` — *ftc-robot-cx (Codex)*

The R3/R4 findings in `review-sim-cx-12-r3.md` and
`review-sim-cx-15-r4-r5.md` were addressed by these commits (the review files
also record residual test gaps):

- `aca0f19` selected the recorded initial sensor state (later corrected by
  `8329676`, which gives the bag header pose precedence).
- `20f3812` yielded the FTC loop; `4f0b38f` made `RESET_POSE` a consumer path.
- `3775131` aligned SHOOT RPM semantics; `5ef4a18` zeroed stale output on an
  engine handoff; `8c11fb7` quiesced the turret during cancel-all.
- `658c3d4` routed per-request shooter cancellation; `ef039a5` cancelled all
  sequence-owned work on manual takeover; `164619d` made attached requests
  completion barriers.
- `1620e33` fixed axis-aligned velocity interpolation; `2fa9655` forwarded
  switch statuses and rejected malformed switches; `3e7ab31` removed the
  unreachable `ACCEPTED` status; `4e8f5fe` validated path constraints.
- `4151143` added R3 safety integration coverage.
- `5fbc7c1` granted Android network permission; `46bf2ba` added per-client
  bounded tap queues; `826b83e` kept drop metadata out of the three-seam bag.
- `8bf55f7` made socket timeout cancel active work; `68aeace` rejected malformed
  batches without refreshing the watchdog; `99d1551` closed tap/socket threads
  during opmode shutdown.
- `2094bc0` removed APIs newer than Android minSdk 24; `3c52351` added bounded
  feedback queues for socket clients.
- `8329676` fixed replay reset-pose precedence; `7a7cbfb` added seeded,
  bit-equal simulator replay; `ed28303` separated intake ownership from terminal
  status IDs; `8e3fa97` added direct-engine, SDK-shaped cadence, and bag-shutdown
  coverage; `2a649b4` made bag path failures synchronous; `907c31a` replaced
  remaining Java 9 collection factories for minSdk compatibility.

### S3 and simulator follow-ups — re-cock-nize `dev-phase-1.1` — *ftc-sim-cx (Codex)*

- `6dfabff` added multi-robot contact and determinism tests; `238e91d` added
  viewer robot selection; `76db5f4` added the two-robot convenience runner.
- `b083b92` added `back` and `start` gamepad fields (sim-cx-13). No commit named
  or identified as sim-cx-14 is present in the inspected history.
- The later simulator hardening sequence added a non-blocking tap reader and
  HUD/bag tools (`c8ff50e`, `3ef567c`, `49c1330`, `05a367b`), protocol and
  lockstep validation/timeouts (`37d45b7`, `0a348c6`, `e3eee77`), reset epochs
  (`d9b3320`), strict seam groups and tap-drop metadata (`c16b676`, `d81c138`),
  numeric event and servo validation (`f501507`, `f6666b0`), reconnect backoff
  (`bfa9c29`), and the demo launcher (`518bf9c`).

### docs on `stable` — *ftc-main / review records*

- `d1d009c` recorded the S3 and R4 design-spec revisions; `8512985` added the
  `back`/`start` fields to `protokol.md`.
- `9a9c9c2`, `b3df1ae`, and `8a97ddb` established the architecture PDF pipeline,
  real-TeX diagram rendering, and verbatim Mermaid source retention;
  `979c891` refreshed the R3 architecture draft.
- `d14bf3d` added `review-sim-cx-12-r3.md`; `0fd851b` and `c67e172` recorded the
  teleop map and request catalog.
- `77ba16a` added `review-sim-cx-15-r4-r5.md`; `f207977` added
  `review-robot-cx-16-sim.md`; `ca8632f` appended the R5 robot review; and
  `9a0babd` appended the simulator review response (81 Python tests passed in
  that response).
- `fed3467` replaced the prose architecture with the rendered diagram-first
  reference (18-page PDF, 23 rendered diagrams).

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

**Faz 1 / `robot-cx-01` — Pedro Pathing 3.0 HAL üstüne** (spec: `phases/phase-1/robot-cx-01-pedro-hal.md`) — *ftc-robot-cx (Codex)*
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
- BLOKER yok; 4 ÖNEMLİ + 8 KÜÇÜK bulgu → `phases/phase-1/robot-cx-03-review-duzeltme.md`

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
- Çıktı: `_parked/phases/phase-1/robot-cx-02-rapor.md` (untracked; mevcut ağaç +
  katman etiketleri, taşıma listesi, Gradle yönü, riskler)
- `ftc-main` + Tuna kararı: raporun §2 önerisi (L2/L3'ü TeamCode dışında tutmak)
  **reddedildi**; bağlayıcı yerleşim `phases/phase-1/faz1-katman-plani.md`'ye yazıldı —
  üç katman `TeamCode/` içinde, `:core` fiziksel olarak `TeamCode/core/`

**`robot-cx-04` — katman taşıma** (`phases/phase-1/faz1-katman-plani.md`) — *ftc-robot-cx (Codex)*, `dev-phase-1`'de sürüyor
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
(spec: `phases/phase-1/sim-cx-01-motor-mecanum-fizik.md`) — *ftc-sim-cx (Codex)*
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
- `phases/phase-1/`: `robot-cx-01`, `robot-cx-02`, `robot-cx-03`, `sim-cx-01`
  spec'leri, `faz1-katman-plani.md`; handoff/rapor dosyaları
  `_parked/phases/phase-1/` altında (untracked)
- Bu depo kuruldu: `README.md`, `CHANGELOG.md`, `gunluk/`, `engine-iterasyonlari/`

### Koordinasyon olayları

- ~06:50 — `ftc-main` model limitine takıldı; koordinasyon geçici olarak
  `ftc-main-cx`'e (Codex) devredildi. Tuna'nın şartı: **aşamayı tamamla ama
  `ftc-main` kontrol etmeden bir sonraki aşamaya geçme.** Devir notu:
  `_parked/phases/phase-1/devir-ftc-main-cx.md` (untracked).
- Limit sıfırlanınca koordinasyon `ftc-main`'e geri döndü; `ftc-main-cx` devir
  raporunu yazdı (`_parked/phases/phase-1/devir-rapor.md`, untracked) ve review başlatıldı.
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
