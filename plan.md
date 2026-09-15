# BOOBUZZ Planı

> ## ⚠️ GALL'S LAW — 1/3
> **Çalışan karmaşık bir sistem, her zaman çalışan basit bir sistemden evrilmiştir.
> Sıfırdan tasarlanan karmaşık bir sistem asla çalışmaz ve yamayarak çalıştırılamaz.**
>
> Geçen sezon: **~70.800 satır yazıldı, 10.751'i maça girdi (%15).** 289 dosya /
> 60.060 satır tek commit'te silindi. Mimariler temizdi. Hiçbiri çalışmadı — çünkü
> hepsi, altındaki katman çalışmadan önce yazıldı.
>
> Bu plandaki her fazın sonunda **sürülebilir bir robot** vardır. İstisna yok.

Mimari için → `mimari.md`.

---

## Engine sürümleri

L2'nin tamamı takılıp çıkarılabilir bir birimdir. Her iterasyon yeni bir Engine
bırakır; **eskiler silinmez.**

```java
RobotEngine engine = new C3VisionEngine(hal);   // C2'ye dönmek TEK SATIR
```

| | Engine | İçerir | Eklenen |
|---|---|---|---|
| **C1** | `C1DriveEngine` | Localizer (Pedro) + DriveExec (Manual) | — |
| **C2** | `C2SubsystemEngine` | + Shooter, Intake, Feeder, Turret (manuel) | balistik **B1** |
| **C3** | `C3VisionEngine` | + VisionAdapter, Turret TRACK | balistik **B2/B3** |
| **C4** | `C4WorldEngine` | + WorldModel (izler, Predictor, LookBook), Turret SCAN | — |
| **C5** | `C5FusionEngine` | + TofAdapter, erken füzyon, refleks hız kesme | — |

**Amacı bu:** world model bozulursa C3'e, vision bozulursa C2'ye, her şey bozulursa
C1'e dönersin — yarışma sabahı, tek satırla. Geçen sezon böyle bir geri dönüş yoktu;
`contingency/lvbelc5` paketi tam olarak bu eksikliğin panik hâlinde yazılmış hâliydi.

---

## Balistik merdiveni

Saf hesaplayıcı (`core/calc/Ballistics`), durumsuz, birim testi bedava.
Her basamak bir öncekinin yerine geçer, **arayüz aynı kalır**:

```java
interface Ballistics { Shot solve(double distance, double heightDelta); }
```

| | Yöntem | Ne zaman |
|---|---|---|
| **B1** | **Sabit** — tek RPM + tek hood açısı, tek mesafeden atış | C2 ile |
| **B2** | **Lookup + interpolasyon** — ölçülmüş mesafe→(RPM, açı) tablosu | C3 ile |
| **B3** | **Polinom oturtma** — geçen sezon kullanılan yöntem | C3 ile |
| **B4** | **Basit fizik** — sürtünmesiz/basit sürtünmeli balistik | gerekirse |
| ~~B5~~ | ~~RK4~~ | **BU SEZON YOK.** `ball-auto-istic/messi` orada duruyor, girmiyoruz. |

B1 aptalca görünüyor ama **B1 ile gol atılır.** B2'ye ancak B1 çalıştıktan sonra
geçilir — çünkü B2'nin tablosunu doldurmak için B1 ile atış yapman lazım.

---

## Fazlar

### Faz 0 — İskelet
Soket protokolü ve `mechanism.yaml` şeması: **`docs/protokol.md`** (bağlayıcı, ftc-main günceller).
- [x] `:core` / `TeamCode` / `:sim` Gradle modül bölünmesi
- [x] `:core` içinde `Hal`, `RobotState`, `RobotAction`, `Intent`, `Feedback`, `Controller`, `RobotEngine` — **boş arayüzler**
- [x] Tick döngüsü (5 satır) + `NullProbe`
- [x] `mechanism.yaml` şeması + okuyucu (tf ağacı + motor modelleri)
- [x] CI: `:core` içinde `com.qualcomm`/`org.firstinspires` importu varsa build kırılır

**Bitti tanımı:** `:core` derleniyor, SDK'ya dokunmuyor, iki HAL de boş implementasyon.
→ **BİTTİ** (15 Eyl 2026, robot-code `17c8cc3`). Guard kanaryayla doğrulandı; 31 test;
`SimMain` gerçek Python sunucusuna karşı 500 adım, aynı seed iki koşuda bit-bit aynı.
Faz 0'ın ötesine geçen iki parça: `C1DriveEngine` + `GamepadController` (Faz 1'in
C1'i, simde koşuyor) ve `:sim` `SimHal`/`SimMain` — ikisi de yeni **Faz 1**'e ait.

### Faz 1 — Katmanlar + Pedro + gerçek sim fiziği
Eski Faz 1 (sim) / Faz 2 (C1) / Faz 2.5 (Pedro) **bu faza katlandı.** Robot bir süre
elimizde yok → kanıt sim'de üretilir, robot geldiğinde aynı bytecode robota çıkar.

Tasarım notu ve adım adım uygulama listesi: **`gorevler/faz1-katman-plani.md`** (bağlayıcı).

**Yerleşim kararı (takım lideri):** L1 HAL / L2 logic / L3 controller katmanları
`TeamCode/` klasörünün **içinde**, her biri ayrı dizin. `:core` modülü fiziksel olarak
`TeamCode/core/` altına taşınır (`settings.gradle`'da `projectDir`); saf Java kalır,
FTC SDK görmez, `:sim` ve robot **aynı bytecode'u** koşar. `:sim` yalnız ince L1 adapter
(`SimHal`, protokol istemcisi, `SimMain`, fixture) olarak kalır.

**Katman iskeleti**
- [ ] `:core` → `TeamCode/core/`; `sdk-guard` sourceSet tabanlı (kanaryayla doğrulanır)
- [ ] `hal/` (L1 sözleşmesi) · `contract/` (L2↔L3) · `logic/` (L2) · `controller/` (L3)
- [ ] Subsystem mekanizması: `logic/Subsystem` + `logic/drive/DriveSubsystem`;
      engine sabit sırayla çağırır (scheduler yok — mimari §4)
- [ ] `TeamCode/…/teamcode/hal/` (`RealHal`, `Hardware`) · `teamcode/opmode/` (kabuk)
- [ ] `RobotFactory` — engine+controller kurulumu tek yerde (`SimMain` ve OpMode ondan
      çağırır; bugünkü kopya kural 6'ya aday)

**Pedro oturuyor**
- [ ] `HalDrivetrain` / `HalLocalizer` — Pedro'nun `Drivetrain`/`Localizer` arayüzleri
      **HAL üstünde** (hazır `Mecanum`/`PinpointLocalizer` `hardwareMap`'ten kendi
      motorunu yaratıyor → HAL'i atlıyor → simde çalışmaz)
- [ ] `Follower` + `Foresight` **tek yerde** — `Hardware`'in ayarsız
      `ForesightConfig(cfg -> {})` kopyası kaldırılır
- [ ] `Drive.Manual` / `Drive.GoTo` / `Drive.FollowPath` → `DriveSubsystem`
- [ ] Pinpoint ofsetleri `mechanism.yaml`'a (bugün `Hardware` 161.0 mm diyor,
      `mechanism.yaml` `[0,0,0]` diyor → sim ile robot farklı)
- [ ] `PoseFactory.degrees().mirrorX(144)` ile Blue/Red aynalama

**Sim fiziği gerçekleşiyor** (`re-cock-nize`, Python)
- [x] Soket protokolü, lockstep, motor seviyesi (~15 alan) — `docs/protokol.md`
- [x] `SimHal` + `SimMain` (Java tarafı), pygame üstten saha görünümü
- [ ] **4 tekere giden motor güçleri elektriksel olarak simüle edilir** — güç → voltaj →
      `kS`/`kV` ile tork → teker hızı, pil voltajı dahil, her teker ayrı
- [ ] **Mecanum hareketi gerçek kinematikle çevrilir** — `mechanism.yaml`'daki `pos` +
      `roller` açılarından ters kinematik (katsayı kısayolu değil)
- [ ] **Geçen sezon kalibrasyonu uygulanır** — kayma, sağ/sol verimlilik farkı vb.
      *Kalibrasyon verisi bulunursa uygulanır; bulunmazsa makul varsayılan kullanılır ve
      kaynağı ("varsayılan, ölçülmedi") açıkça belirtilir.* Veriyi ayrı bir ajan arıyor.

**Robot geldiğinde** (Faz 2'nin ön şartı, Faz 1 içinde kapanır)
- [ ] `RealHal` — motorlar, Pinpoint, voltaj
- [ ] Robot gamepad'le sürülüyor; **aynı `:core` hem simde hem robotta**
- [ ] Aynı yolu simde ve gerçekte koştur, sapmayı ölç → sim fiziğinin kalibrasyonu

**Aşırı gerçekçilik hedef değil.** Hedef: *Pedro ile çalışan, kalıpları hazır sistem.*

**Bitti tanımı:** katmanlar TeamCode'da kurulu; subsystem logic + controller mekanizması
doğru kurulmuş; Pedro çalışıyor; 4 tekere giden motor güçleri gerçekten simüle ediliyor;
mecanum hareketi sim tarafından gerçek kinematikle çevriliyor; kalibrasyon verileri sim'e
uygulanmış (ya da varsayılan olarak işaretlenmiş). Sim artık oyuncak değil, **ölçüm aracı.**

---

> ## ⚠️ GALL'S LAW — 2/3
> Faz 2'ye geçmeden önce Faz 1 **çalışıyor** olmalı. "Çalışacak gibi duruyor" değil,
> ekranda hareket ediyor olmalı.
>
> Geçen sezon `cartographer` (4.399 satır), `Ashtar` (3.319), turret tuner'ları
> (4.483) yazıldı. Hiçbiri robota çıkmadı, çünkü altlarındaki katman hiç oturmadı.
> **Sıra atlamak, iş yapmak gibi hissettiren tek şeydir.**

---

### Faz 2 — Subsystem'ler (C2)
Vision'dan ve ToF'tan **önce.** Geçen sezonun kanıtlı [A] kodu burada.

- [ ] `ShooterExec` — PIDF + FF, gains hazır (`kS=0.18766200`, `kV=0.00013514`)
- [ ] `FeederExec` — pulse modeli
- [ ] `IntakeExec` — 42 satırlık kazanan
- [ ] `TurretArbiter` — önce sadece MANUAL
- [ ] `Request`/`RequestStatus` yaşam döngüsü (SHOOT, INTAKE)
- [ ] **Balistik B1** — sabit mesafeden gol
- [ ] Karakterizasyon koşusu (`tunaing` FF/PID relay) → **çıktı hem kontrolcüye hem sime gider**

**Bitti tanımı:** robot sabit bir noktadan gol atıyor.

### Faz 3 — Vision + turret tarama (C3)
Vision'ın çalışma ihtimali ToF'tan yüksek, o yüzden önce.

- [ ] `Limelight` sürücüsü (geçen sezon [A], 172 satır)
- [ ] **Zaman damgalı turret açı ring buffer'ı** — kamera turret'a çıktığı an şart
- [ ] tf zinciri `camera→turret→robot→field` (`mechanism.yaml`'dan)
- [ ] `VisionAdapter` → `Observation[]`
- [ ] `TurretArbiter` SCAN↔TRACK önceliği
- [ ] Simde: `limelight.py` görüş modeli, **süpürme sırasında nereleri görüyoruz** ölçümü
- [ ] Simde: süpürme sırasında AprilTag görme sıklığını ölç → ToF→localizer kararı
- [ ] **Balistik B2 → B3**

**Bitti tanımı:** turret süpürüyor, gördüğü topları raporluyor, hareketli hedefe nişan alıyor.

### Faz 4 — WorldModel (C4)
- [ ] `Observation`, `Track` (`vx,vy,cov` alanları **dahil**, doldurulmasa bile)
- [ ] `Predictor` (sınıf başına hareket modeli) + `predictAt()`
- [ ] `Associator` (Mahalanobis geçidi)
- [ ] `Updater` (polar→kartezyen kovaryans + lineer Kalman)
- [ ] `LookBook` + negatif kanıt
- [ ] Sınıf başına `cov` büyümesi / `confidence` düşüşü ayrı parametreler
- [ ] Tarama hedeflemesi: "en çok bilmediğim yere bak"

**Bitti tanımı:** görülmeyen topların nerede olduğunu tahmin ediyor, tarama rastgele değil.

### Faz 5 — ToF (C5)
En sona. Vision çalışmıyorsa bu faz **öne alınır**, plan buna izin verir.

- [ ] 4-6 sensör, öne ağırlıklı, ~8-10 cm yükseklik, **3-5° yukarı pitch** (yatayda halı dönüş verir)
- [ ] Round-robin okuma (döngü başına 1 sensör; 8 sensör × 5-10 ms loop'u öldürür)
- [ ] `TofAdapter` → `Observation[]` (aynı format)
- [ ] Erken füzyon — `sigma`'lar burada işe yarıyor
- [ ] Refleks hız kesme (`rays`'ten doğrudan, tracker'dan geçmeden)

### Faz 6 — Otonom / Replay / RL
- [ ] `AutoController`, `ReplayController`
- [ ] `Drive.Velocity` **kapalı çevrim** (3 PID, ~60 satır) — RL'in ön şartı
- [ ] Python trainer ↔ soket ↔ Java sim, N paralel kopya
- [ ] `RLController`

---

## TODO — sırasız, küçük işler

- [ ] Android Studio güncelle (Quail 2 → Quail 4, `sudo pacman -Syu android-studio`)
- [ ] BIOBUZZ kılavuzu: top çapı, ek elektronik maddesi
- [ ] Turret slip ring var mı? → mekanik ekibe
- [ ] Boş `tunapro1234/de-cock` reposunu sil
- [ ] `boobuzz/` klasörünü git'e al — `boobuzz/docs` hâlâ git dışı, sürümlenmiyor
- [ ] `robot-code` `17c8cc3` ve `re-cock-nize` `faz1-sim` `43c6e73` **push edilmedi** — Tuna kararı
- [ ] `re-cock-nize`: hangi parçalar taşınacak, karar ver (ayrı agent)
- [ ] `ball-auto-istic`: B2/B3 için hangi kalibrasyon verisi kullanılabilir (ayrı agent)
- [ ] **Geçen sezon drivetrain kalibrasyonu** (kayma, sağ/sol verimlilik farkı) bulunacak —
      Faz 1 girdisi (ayrı agent). Bulunamazsa varsayılan + "ölçülmedi" işareti.

---

> ## ⚠️ GALL'S LAW — 3/3
> **Basit sistemle başlamak zorundasın.**
>
> Bu plan Faz 0'dan Faz 6'ya uzanıyor ve her birinin sonunda çalışan bir robot var.
> Fazları atlamak, aynı anda iki faz yazmak, ya da "nasılsa sonra lazım olacak" diye
> bir katmanı erken açmak — üçü de geçen sezonun %15'ini üreten davranış.
>
> **Bir özellik, altındaki katman robot üzerinde çalışmadan yazılmaz.**
