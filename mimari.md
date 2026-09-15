# BOOBUZZ Mimarisi

> **Gall's Law:** Çalışan karmaşık bir sistem, her zaman çalışan basit bir sistemden
> evrilmiştir. Sıfırdan tasarlanan karmaşık bir sistem asla çalışmaz.
>
> Geçen sezon ~70.800 satır yazıldı, 10.751'i maça girdi. **%15.**

Bu doküman **nereye yazacağımızı** tanımlar. Sıra için → `plan.md`.

## 0. Dizin yerleşimi

Katman tanımları (§3/§4/§5) değişmez; **yerleşim** şudur — üç katman `TeamCode/`
klasörünün içinde, her biri ayrı dizin:

```
TeamCode/
├── core/                                      Gradle modülü :core — saf Java, SDK YOK
│   └── src/main/java/boobuzz/core/
│       ├── hal/          L1 sözleşmesi (arayüz; implementasyon yok)
│       ├── contract/     L2 ↔ L3 sözleşmeleri (§6)
│       ├── logic/        L2 — engine/ · drive/ · (world/, shooter/… sırası gelince)
│       ├── controller/   L3
│       └── RobotLoop · RobotFactory · mechanism/ · probe/     (katman dışı)
└── src/main/java/org/firstinspires/ftc/teamcode/
    ├── hal/      L1 implementasyonu — SDK'ya dokunan TEK yer (RealHal, Hardware)
    └── opmode/   kabuk: HAL + Engine + Controller birleştirir

sim/  →  :sim — L1'in sim tarafı, ince adapter: SimHal · SimMain · Json · fixture
```

`settings.gradle`: `project(':core').projectDir = file('TeamCode/core')`. Modül
sınırı — dolayısıyla kural 1'in derleyiciye devri — aynen korunur; `:sim` ve robot
**aynı bytecode'u** koşar. Gerekçe ve elenen seçenekler → `gorevler/faz1-katman-plani.md`.

---

## 1. Genel şema

```
┌─ L3  CONTROLLER ────────────────────────────────────────────────────────┐
│    Gamepad  │  Replay  │  AutoSequence  │  RLPolicy                     │
│                    Intent decide(Feedback)                              │
└──────▲──────────────────────────────────────────────────┬───────────────┘
       │ Feedback                                  Intent │
       │  ├ WorldSnapshot (poz, izler, ışınlar, öz-durum)  ├ Drive
       │  └ RequestStatus[]   (1 tick gecikmeli)           ├ Request[]
       │                                                   └ cancel[]
╔══════╪═══════════════════════════════════════════════════╪══════════════╗
║  L2  │  ENGINE (takılıp çıkarılabilir)  ▲ YUKARI   AŞAĞI ▼              ║
║ ┌────┴──────────────────────────────┐   ┌────────────────────────────┐  ║
║ │ Localizer (Pedro, salt odometri)  │   │ DriveExec                  │  ║
║ │        │ poz                      │   │   Manual/Velocity → 3 PID  │  ║
║ │        ▼                          │   │   GoTo/Path → Pedro follow │  ║
║ │ WorldModel                        │   │   + reaktif hız kesme      │  ║
║ │   Predictor · Associator          │   ├────────────────────────────┤  ║
║ │   Updater   · LookBook            │   │ TurretArbiter  SCAN↔TRACK  │  ║
║ │        ▲ Observation[]            │   │ ShooterExec    PIDF+FF     │  ║
║ │ ┌──────┴──────────────────────┐   │   │ FeederExec     pulse       │  ║
║ │ │ TofAdapter │ VisionAdapter  │   │   │ IntakeExec                 │  ║
║ │ └──────▲──────────────────────┘   │   └───────────┬────────────────┘  ║
║ └────────┼──────────────────────────┘               │                   ║
║  ─── saf hesaplayıcılar: Transforms · Ballistics · FieldGeometry ───    ║
╚══════════╪═══════════════════════════════════════════╪══════════════════╝
           │ RobotState (ham)              RobotAction │ (motor/servo)
┌──────────┴───────────────────────────────────────────▼──────────────────┐
│  L1  HAL         RealHal (REV)          │          SimHal (soket→Python) │
│                  hal.now()  ·  mechanism.yaml (tf ağacı + motor modeli)  │
└─────────────────────────────────────────────────────────────────────────┘
```

**Tick — beş satır, sırası sabit:**

```java
RobotState  state    = hal.read();
Feedback    feedback = engine.sense(hal.now(), state);   // YUKARI
Intent      intent   = controller.decide(feedback);      // L3
RobotAction action   = engine.act(intent);               // AŞAĞI
hal.write(action);
```

---

## 2. Anayasa

| # | Kural | Gerekçe |
|---|---|---|
| 1 | **L2/L3 FTC SDK import etmez.** | `:core` ayrı Gradle modülü (dizini `TeamCode/core/`) → kural **derleme hatası**, disiplin değil. |
| 2 | **Zaman HAL'den** (`hal.now()`). | Sim hızlandırılamazsa RL ölür. |
| 3 | **L1 üstünde `if (isSim)` yok.** | Bir tane bile tak-çıkarlığı bitirir. |
| 4 | **Geri ok yok.** L2, L3'ü çağırmaz. | Geçen sezonun döngüsel bağımlılığı. |
| 5 | **Tek thread, sabit timestep, deterministik.** | Tekrarlanmayan sistem ne debug edilir ne eğitilir. |
| 6 | **Robot kodunun tek kaynağı vardır.** Sim kopyalamaz. | Geçen sene kopyalıyordu, kod değişince patladı. |
| 7 | **Python yalnızca fizik ve çizim içerir.** | 6'nın uygulanabilir hali. |
| 8 | **ROS yok** — kütüphane, protokol, isimlendirme. | — |
| 9 | **Kapatılan özellik silinir.** `if (false && ...)` yok. | Geçen sezondan ders. |

---

## 3. L1 — HAL

```java
interface Hal { long now(); RobotState read(); void write(RobotAction a); }
```

`RealHal` (`TeamCode/…/teamcode/hal/`, Android/SDK) · `SimHal` (`:sim`, soketle Python fizik sunucusuna)

**Seam motor seviyesindedir**, subsystem seviyesinde değil.

> Seam, arayüzün **stabil** olduğu yere konur. Motor arayüzü fiziği kodlar (değişmez);
> subsystem arayüzü tasarım varsayımını kodlar (her hafta değişir).

```
aşağı  { fl:0.5, fr:-0.3, bl:.., br:.., shooter:0.8, turret:.., hood:0.42 }
yukarı { enc:{...}, imu:1.57, tof:[...], limelight:{...}, t:12.34 }
```

~15 alan, asla değişmez. JPype yok — ayrı süreç, lockstep soket.

`RobotState`/`RobotAction` **ad-anahtarlı `Map`**'tir (motor adları `mechanism.yaml`'dan;
motor eklemek `:core`'u değiştirmez) — soket protokolünün tüm ayrıntısı → `docs/protokol.md`.

---

## 4. L2 — Logic / Engine

İki yönlü: yukarı algı, aşağı icra. Tamamı takılıp çıkarılabilir:

```java
interface RobotEngine {
    String      name();
    Feedback    sense(long now, RobotState state);   // yukarı
    RobotAction act(Intent intent);                  // aşağı
}

RobotEngine engine = new C3VisionEngine(hal);   // C2'ye dönmek TEK SATIR
```

Engine sürümleri (`C1`→`C5`) → `plan.md`.

| Modül türü | Örnek | Özellik |
|---|---|---|
| Durumlu | Localizer, WorldModel, TurretArbiter | Hafızası var |
| **Saf hesaplayıcı** | Transforms, **Ballistics**, FieldGeometry | Durumsuz, birim testi bedava |

### Command-based YOK

Kanıt: geçen sezon `FTCLib SubsystemBase` kullanılmış, **`CommandScheduler` hiç
çağrılmamış**; `periodic()` elle çağrılmış. (Aynı build'de RoadRunner'ın 3 artifact'ı
vardı, tek satır kullanılmamıştı.) **Pedro 3 `core` jar'ında command/subsystem/
scheduler sınıfı yok** — gerektirmiyor.

Scheduler eşzamanlı komutlar arası kaynak çakışmasını çözer. Tek `Intent`'li tek
döngüde çakışma yok — **`Intent`'in kendisi arbitrajdır.**

İşe yarayan yarısını alıyoruz: istek yaşam döngüsü (`RequestStatus`).
Subsystem = düz sınıf, `update()` Engine'in sabit sırasından çağrılır.

---

## 5. L3 — Controller

```java
interface Controller { Intent decide(Feedback fb); }
```

`GamepadController` · `ReplayController` · `AutoController` · `RLController`

`decide(Feedback) → Intent` aynı zamanda `policy(obs) → action` imzasıdır.

---

## 6. Sözleşmeler

```java
// AŞAĞI
Intent { Drive drive; Request[] newRequests; int[] cancels; }

sealed interface Drive {
    record Manual  (double vx, double vy, double omega) {}  // robot çerçevesi, -1..1
    record Velocity(double vx, double vy, double omega) {}  // saha çerçevesi, m/s
    record GoTo    (Pose target, Constraints c) {}
    record FollowPath(String pathId) {}
    record Hold() {}
}
Request { int id; RequestType type; Params params; }        // kenar tetikli

// YUKARI
Feedback      { WorldSnapshot world; RequestStatus[] statuses; long t; }
RequestStatus { int id; State state; double progress; String note; }
                // ACCEPTED · ACTIVE · DONE · FAILED · REJECTED
```

**Geçirilerek, global değil:** (a) doğrudan RL gözlemi, (b) replay için kaydedilebilir,
(c) test edilebilir. Singleton üçünü de öldürür.

**Status 1 tick gecikmelidir** — Engine controller'dan sonra koşar (kural 4).

### RL hangi `Drive` modunu kullanmalı: `Velocity`

| | |
|---|---|
| Motor gücü | ❌ `güç→hareket` sürtünmeye, halıya, **pil voltajına** bağlı; voltaj tek başına %20+ kaydırır. Sim-to-real'in en kötü yeri. |
| **`Velocity`** | ✅ Farkı **hız takipçisi** soğurur, politika değil. Temas davranışı öğrenilebilir. |
| `GoTo` | ❌ Follower araya girer → **çarpışmaya dayanıklılık öğrenilemez**, asıl hedef oydu. |

**Şart:** `Velocity` kapalı çevrim olmalı (localizer geri beslemeli 3 PID, ~60 satır).
Açık çevrim güç eşlemesi kullanılırsa `Velocity` gizliden gizliye "güç" olur.

---

## 7. WorldModel

```
logic/world/            Observation · Track · WorldSnapshot · WorldModel
                        Predictor · Associator · Updater · LookBook · MotionModel
logic/world/adapters/   TofAdapter · VisionAdapter     ← sensöre özel TEK yer
(tam yol: TeamCode/core/src/main/java/boobuzz/core/logic/world/)
```

**Ham veri `WorldModel`'e girmez.** Adapter'lar ortak formata çevirir:

```java
Observation { long t; double bearing, range, sigmaB, sigmaR;
              ObjClass cls; double conf; Source src; }   // robot çerçevesi, YAKALAMA anı
```

| | Menzil (`sigmaR`) | Açı (`sigmaB`) |
|---|---|---|
| **ToF** | **±3 cm** | ±12° |
| **Vision** | ~%10 | **±1°** |

Tam zıt eksenlerde iyiler → **erken füzyon** (gözlem seviyesi), geç füzyon değil.
Sensör başına harita çıkarıp birleştirmek belirsizliğin *yönünü* yok eder.
`src` füzyonda **kullanılmaz**, sadece teşhis.

### Tick döngüsü

```
obs'u zaman damgasına göre sırala      ← vision ~60 ms geç, 3 tick eski olabilir
her obs için:
  1. PREDICT    izleri obs.t'ye ilerlet
  2. POLAR→XY   σB,σR → 2×2 kovaryans elipsi
  3. ASSOCIATE  Mahalanobis geçidi + en yakın
  4. UPDATE     lineer Kalman
  5. BIRTH      eşleşmeyen → tentative iz
tüm izleri now'a ilerlet
  6. NEGATIVE   fov içinde ama eşleşmedi → conf ↓↓
  7. DEATH      conf < eşik → sil
  8. LOOKBOOK   bakılan konileri kaydet
```

**EKF yok.** Polar ölçümü kovaryansıyla kartezyene çevir → düz lineer Kalman.
Bearing ekseninde elips `diag(σR², (range·σB)²)`, bearing kadar döndür. Altı satır —
ToF/vision elipslerinin dikliği burada görünür. İz `[x,y,vx,vy]`, ölçüm `[x,y]`.

### İki ayrı hafıza — karıştırma

| | Anlamı | Sınıf başına |
|---|---|---|
| `cov` | **Nerede** bilmiyorum | top yavaş büyür, robot hızlı |
| `confidence` | **Var mı** bilmiyorum | top yavaş düşer (toplar kaybolmaz), robot hızlı |

### Predictor iki tüketicili

```java
List<Track> predictAt(long t);   // YIKICI DEĞİL, kopya döner
```

İçeride izleri `now`'a getirir; dışarıda "top nerede olmalı / nereye bakayım".

```
tarama önceliği(yön) = f( beklenen yoğunluk, belirsizlik(cov), en son bakış(LookBook) )
```

### Çıktı

```java
WorldSnapshot { long t; Pose pose; Twist vel; Track[] tracks;
                double[] rays; SelfState self; }
```

`rays` **ham olarak da** geçer — refleks hız kesme ve RL gözlemi tracker'dan geçmemeli.

### Localizer bağlantısı

**Localizer = Pedro, salt odometri. WorldModel onu güncellemez.**
Gerekçe [A]: geçen sezon Pedro tek başına iyiydi, AprilTag füzyonu eklenince bozuldu.

Statik dönüşler adapter'da işaretlenir, iz olmaz. Sınıflandırma **izin özelliğidir,
gözlemin değil** — robot hareket ederken saha çerçevesinde sabit kalan dönüş statiktir
(paralaks). Tek ölçümden karar verilmez.

> **Açık risk:** kamera süpüren turret'ta olduğu için AprilTag görüşü kesintili olacak.
> ToF duvar düzeltmesi değerini burada kazanabilir. Ölçülecek, tahmin edilmeyecek.

---

## 8. `mechanism.yaml`

Tek kaynak: sim geometrisi **ve** gerçek robotun koordinat matematiği.

```yaml
frames:                     # tf ağacı — turret-kamera problemini bu çözer
  robot:  {parent: field}
  turret: {parent: robot,  xyz: [0,1.5,8], joint: revolute, axis: z, limits: [-180,180]}
  camera: {parent: turret, xyz: [0,4,2], rpy: [0,-20,0], hfov: 63.3, vfov: 49.7}
  tof0:   {parent: robot,  xyz: [8,0,3.5], rpy: [0,4,0], fov: 25}
motors:
  fl:      {drives: wheel, pos: [-6,6], roller: 45, kV: .., kS: ..}
  shooter: {drives: flywheel, gear: 1.0, kV: 0.00013514, kS: 0.18766200}
  turret:  {drives: joint.turret, gear: 40.0}
```

Motor modeli ile feedforward **aynı matematiktir** — `kS`/`kV` ölçümü hem kontrolcüyü
hem simülatörü besler. Motor seviyesi seam'inin bedeli bu yüzden zaten ödenmiş.

---

## 9. Probe

Zincir doğrudan fonksiyon çağrısıdır; her ara değer isimli ve musluklanabilirdir.

```java
interface Probe { <T> void publish(String name, T msg, long t); }
```

`NullProbe` (yarışma) · `SocketProbe` (görselleştirici) · `FileProbe` (replay)

Bu bir node framework'ü **değildir**: tek zincir, çok gözlem noktası.

---

## 10. Simülasyon

| | |
|---|---|
| Fizik | **Python** — `re-cock-nize`'dan `sensor_grid.py` (445), `limelight.py` (357), `ballistics.py` (335), `config.yaml` |
| Köprü | **Soket**, motor seviyesi, ~15 alan, lockstep → deterministik |
| Görsel | pygame — mevcut grafik/panel kodu + yeni üstten saha görünümü |
| Kapsam | 2B + ışın atma. **PyBullet kapalı** (top etkileşimi gerekene kadar). |
| Motor | **Elektriksel:** güç → voltaj → `kS`/`kV` ile tork → teker hızı; pil voltajı dahil; dört teker ayrı. Parametreler `mechanism.yaml`'dan. |
| Drivetrain | Mecanum **ters kinematiği** `pos` + `roller` açılarından türetilir (sabit katsayı kısayolu değil). |
| Kalibrasyon | Kayma, sağ/sol verimlilik farkı vb. geçen sezon verisinden. **Bulunamazsa makul varsayılan kullanılır ve "varsayılan, ölçülmedi" diye işaretlenir** — sessiz sihirli sayı yasak. |
| **Atılan** | `ftc_sim/subsystems/` — özellikle `drivetrain.py` (881 satır, Pedro Bezier matematiğinin Python kopyası; kural 6/7 ihlali, geçen senenin patlama sebebi) |
| **Durum** | Kinematik taban + köprü bitti (`re-cock-nize` `faz1-sim` `43c6e73`, Java `:sim` `robot-code` `17c8cc3`). **Kalan:** elektriksel motor modeli, gerçek mecanum ters kinematiği, kalibrasyon — Faz 1. |

Sim ile gerçek arasındaki **tek fark L1'dir.**

---

## 11. Karar günlüğü

| Karar | Gerekçe |
|---|---|
| Üç seviye, L2 iki yönlü | Yığın değil döngü |
| `:core` / `TeamCode` / `:sim` | Kural 1 derleyiciye devredilir |
| Katmanlar `TeamCode/` içinde görünür dizinler | Kod okunduğunda mimari görünsün; modül sınırı korunsun diye `:core`'un `projectDir`'i `TeamCode/core/` (→ `gorevler/faz1-katman-plani.md`) |
| `TeamCode/src` altına `:core` kaynağı konmadı | AGP exclude filtresi deprecated yüzeyde; elle senkron iki filtre = sessiz çift derleme riski |
| Sözleşmeler ayrı `contract/` paketinde | `Intent`/`Feedback` ne L2 ne L3'tür (§6) |
| Seam motor seviyesinde | Arayüzün stabil olduğu yer |
| Soket, JPype değil | Seam inceldi; ayrı süreç, dilden bağımsız |
| Command-based yok | İthal edildi, sıfır fayda; Pedro gerektirmiyor |
| Localizer salt Pedro odometri | [A] AprilTag füzyonu geçen sezon bozdu |
| Occupancy grid yok | Saha geometrisi biliniyor; toplara **kimlik** lazım, grid hücre verir |
| `ScanCoverageMap` → `LookBook` kalıyor | Geçen sezonun doğru fikri; negatif kanıt süpürme için şart |
| Erken füzyon | ToF/vision belirsizlikleri dik; harita seviyesinde birleşim bunu yok eder |
| Kamera Limelight, turret üstü | Zaman damgası; 180°/s'de 60 ms = 11° kayma |
| ToF şasiye | Turret yüksek → yatay ışın topların üstünden geçer, eğik ışın sabit halka görür |
| ToF harita değil: refleks + teyit + RL gözlemi | 12 cm koyu küre 1 m'de koninin %7'sini doldurur |
| RL `Velocity` kullanır | `güç→hareket` pil voltajıyla %20+ kayar |
| Engine sürümleri C1..C5 | Bozulan katmandan geri dönmek bir satır olmalı |
| `RobotState`/`RobotAction` ad-anahtarlı `Map` | Motor eklemek `:core`'u değiştirmez |
| Robot çerçevesi x-ileri/y-sol, saha orijini köşe | Pedro ile aynı; çevrim yok |
| `ready` başlangıç state'ini taşır | `RobotLoop` ilk tick'te `read()` çağırır |

---

## 12. Açık sorular

| | Etkisi |
|---|---|
| Turret slip ring? | Yoksa ±180° süpürme; sadece `mechanism.yaml` limiti değişir |
| BIOBUZZ topunun çapı | ToF montaj yüksekliği (~8-10 cm hedef) |
| Süpürmede AprilTag görme sıklığı | ToF→localizer bağlantısı gerekli mi |
| Kaç ToF? | Expansion Hub ile ~7 bus; asıl tavan **loop hızı** (okuma başına 5-10 ms) |
