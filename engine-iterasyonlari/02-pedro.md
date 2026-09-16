# 02-pedro — `PedroDriveEngine`

**Faz:** Faz 1 · **Dal:** `dev-phase-1`
**Commit'ler:** `85be43f` → `dd4bd3f` (uygulama, `robot-cx-01`),
`ceff098` → `3c115a7` (review düzeltmeleri, `robot-cx-03`)
**Yazan ajan:** ftc-robot-cx (Codex gpt-5.6) · spec: ftc-main ·
review: sıfır bağlamlı Claude Opus subagent'ı

Spec: `../phases/phase-1/robot-cx-01-pedro-hal.md` · Rapor:
`../_parked/phases/phase-1/devir-rapor.md` (untracked)
Review maddeleri: `../phases/phase-1/robot-cx-03-review-duzeltme.md`

---

## 1. Amaç

**Yol takibi.** C1 sürüyor ama nereye gideceğini bilmiyor; `Drive.GoTo` ve
`Drive.FollowPath` intent'lerini gerçek bir path follower'a bağlamak gerekiyordu.

Neden Pedro: geçen sezon zaten Pedro Pathing kullanıldı, sabitleri ölçülmüş
durumda (`mass 13.8 kg`, `forwardZeroPowerAccel −36.17`, `lateralZeroPowerAccel
−85.98`, `xVel 73.63`, `yVel 54.09`). Yeniden yazmanın hiçbir faydası yok.

**Asıl zorluk:** Pedro 3.0'ın hazır `Mecanum` ve `PinpointLocalizer` sınıfları
`hardwareMap`'ten kendi motorunu yaratıyor → HAL'i atlıyor → simde çalışmıyor.
Bu iterasyon, Pedro'yu **HAL'in üstüne** oturtmakla ilgili.

## 2. Mimari

`core/.../pedro/` altında beş sınıf (hepsi `:core`, SDK yok):

| Sınıf | İş |
|---|---|
| `HalLocalizer implements Localizer` | `feed(RobotState)` ile her tick beslenir; `pose()` = pinpoint pozu (**çerçeve dönüşümü yok** — bizim çerçeve = Pedro çerçevesi); hız ardışık iki pinpoint farkından; `twist()` saha hızının −heading ile döndürülmüşü; `setPose` offset tutar |
| `HalDrivetrain implements Drivetrain` | Donanıma **yazmaz**; son gücü tutar, `RobotAction lastAction()` üretir. Motor adları `mechanism.yaml`'dan (`fl,fr,bl,br`), sabitleme yok |
| `PedroDriveEngine implements RobotEngine` | Tick: `localizer.feed(state)` → `follower.update()` → `drivetrain.lastAction()`. `Drive.Manual` → **C1DriveEngine'e delege** |
| `PedroConstants` | Geçen sezon sabitleri tek yerde, "yeni robotta yeniden ölçülecek" yorumuyla |
| `PathRegistry` | `Map<String, Path>`; `test-line` (72,72,h=0)→(120,72,h=0) |

`:sim` tarafı: `SimMain --engine pedro|c1` (varsayılan `c1`, mevcut davranış
değişmez) ve `--path <id>`.

**Pedro 3.0'ın gerçek imzaları** (jar'dan `javap`, varsayım değil):
- `Follower(Localizer, Drivetrain, Algorithm)`; `update()`, `update(double)`,
  `follow(Path)`, `hold(Pose)`, `hold(Pose, boolean)`, `isBusy()`, `atParametricEnd()`
- `DrivePowers` alan sırası: `forward, strafe, turn`
- Revhub Mecanum teker sırası FL/FR/BL/BR, karışım `f−s−t, f+s+t, f+s−t, f−s+t`
- `Pose(double,double,double)` değişmez; `x() y() heading()`
- **Bulunamadı:** `followPath`, `holdPoint`, `PathConstraints` — bu isimler
  Pedro 3.0'da yok; plan bunları varsayıyordu, düzeltildi
- **Bulunamadı:** `Drivetrain` arayüzünde voltaj telafisi girdisi →
  `RobotState.voltage` bağlanmadı
- **Bulunamadı:** `ForesightConfig`'de kütle alanı → `MASS_KG` ölü sabit olarak
  **silindi** (`9ac5ce8`)

## 3. Neler değişti (C1'e göre)

- **Eklendi:** `Drive.GoTo` → `hold(Pose)`, `Drive.FollowPath(id)` →
  `PathRegistry` + `follow(Path)`, `Drive.Hold` → mevcut pozda `hold`
- **Değişmedi:** `Drive.Manual` davranışı — bilerek C1'e delege edilir; test
  `PedroDriveEngineTest` bunun **bit-bit aynı** `RobotAction` ürettiğini sınar
- **Sözleşme (`contract/`) değişmedi** → L3 kırılmadı, `GamepadController` aynen
- **Hata davranışı:** bilinmeyen path id'si sessiz no-op değil,
  `IllegalArgumentException`
- Pedro sabitleri sim `mechanism.yaml` `physics:` bloğuyla **aynı kaynaktan**
  (geçen sezon `pedroPathing/Constants.java`) besleniyor — `sim-cx-01` ile
  eşitlendi (`e41d59a`)

### Review sonrası düzeltmeler (`robot-cx-03`)

| # | Bulgu | Commit |
|---|---|---|
| A1 | `setPose` heading değiştirince `twist()` `offsetHeading` kadar yanlıştı | `ceff098` |
| A2 | `maxScaling` taban doygunken 1.0 döndürüyordu → 0 döner | `0a81e42` |
| A3 | `twist()` yalnız heading=0'da sınanıyordu → heading=π/2 testi | `6ae4e52` |
| A4 | `MASS_KG` hiçbir yere bağlı değildi → silindi | `9ac5ce8` |
| B1–B8 | `reset()` heading sarma (`6.282678 rad`'ın kaynağı), ölü kod, `--path`+`--drive` çakışması, `PathRegistry` testi | `3c115a7` |

## 4. Ölçümler

```
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :core:test :sim:test :sim:installDist
BUILD SUCCESSFUL — 47/47 test, 0 failure, 0 error, SDK guard geçti
```

Entegrasyon (Python sunucu headless port 5556; Pedro engine, `test-line`,
başlangıç `(72,72,0)`, dt=20 ms, 1000 adım, seed=1):

- Kabul aralığına giriş: **adım 68 (1.36 s)**
- Son truth: `(120.00295950334511, 71.95624330809692, 0.00010558009382677369)`
- Son pinpoint: `(120.00902775124669, 71.95490866957033, -0.0005071966842020714)`
- İki `seed=1` koşusunda truth ve pinpoint x/y/h **double bitleri birebir aynı**
- Kabul ölçütü (x ∈ [118,122], |y−72| < 2, |h| < 0.1 rad): **geçti**
- `robot-cx-03` düzeltmeleri sonrası koşu tekrarlandı (A5) — çıktının rapor dökümü
  `phases/phase-1/` altına düşmedi → **doldurulacak**

## 5. Neyi daha iyi yaptı

- **Pedro artık HAL'in üstünde.** Aynı `:core` bytecode'u hem simde hem (robot
  gelince) robotta koşacak. Geçen sezon Pedro doğrudan `hardwareMap`'e bağlıydı;
  simde hiç koşturulamadı.
- **Yol takibi ölçülebilir hâle geldi:** 48 inçlik düz çizgi 1.36 saniyede kabul
  bandına giriyor, tekrarlanabilir (bit-bit determinizm).
- **Geri dönüş korundu:** `--engine c1` hâlâ varsayılan; Pedro bozulursa C1 tek
  bayrakla geri geliyor.
- **Varsayımlar kanıta dönüştü:** plan.md'nin Pedro API varsayımlarının üçü
  yanlıştı ve kod yazılmadan önce yakalandı.

## 6. Açık sorunlar

- **`test-turn` gerçek bir dönüş yolu değil.** Pedro 3.0 sıfır uzunluklu `Line`
  kabul etmiyor, ayrı dönüş-path tipi **bulunamadı**; `test-turn` aynı konumda
  `hold(Pose(120,72,π/2))` olarak kayıtlı. Saf dönüş davranışı **ölçülmedi.**
- **Voltaj telafisi yok.** Pedro `Drivetrain` arayüzünde girdi bulunamadı;
  `RobotState.voltage` kullanılmıyor. Pil düşerken davranış **bilinmiyor.**
- **`Drive.GoTo`'nun `constraints` alanı uygulanmıyor** (Javadoc'ta yazılı, B5).
- **PID kazançları makul varsayılan.** `PedroConstants` geçen sezonun robotundan;
  yeni robotta **yeniden ölçülecek.**
- **Gerçek robotta koşmadı.** Aynı yolu simde ve gerçekte koşturup sapmayı ölçmek
  Faz 1'in kapanış şartı → **doldurulacak (robot gelince).**
- Sim fiziği kalibre edildi ama teker verimlilik çarpanları 1.0 (**ölçülmedi**) ve
  `free_rpm` doğrudan ölçüm değil, `73.63 in/s`'den türetildi.

## 7. Geri dönüş

`SimMain --engine c1` (zaten varsayılan) veya `RobotFactory`'de tek satır. Pedro
katmanı `core/.../pedro/` altında izole; C1 ona hiç bağlı değil.
