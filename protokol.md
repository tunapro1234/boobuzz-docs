# Sim köprüsü protokolü (L1 seam) — BAĞLAYICI

`mimari.md` §3'ün somut hâli. İki ajan (ftc-robot ↔ ftc-sim) bu dosyaya karşı yazar.
Değişiklik önce burada, sonra kodda. Bu dosyayı ftc-main günceller.

## Roller
- **Python (re-cock-nize) = sunucu, fizik.** Önce açılır. `--mechanism <yol>` alır.
- **Java (`:sim` modülü) = istemci, saat sahibi.** `dt`'yi Java gönderir → headless koşu
  gerçek zamandan hızlı olabilir; pygame açıkken viewer gerçek zamana kilitler.
- **Lockstep:** her tick tam bir `step` ↔ `state` çifti. Python `step` gelmeden ilerlemez.
- Taşıma: TCP `127.0.0.1:5555`, satır sonlu JSON (bir mesaj = bir satır).

## Tek gerçek kaynak: `robot-code/mechanism.yaml`
İki taraf da **aynı dosyayı** okur. Motor/servo/sensör **adları** buradan gelir; protokol
şeması sabit kalır, adlar konfigürasyondur. Java başlangıçta ad listesini doğrular,
uyuşmazlık = anında çökme (sessiz kayma yasak).

```yaml
units: {length: in, angle: deg}          # dosyada derece; PROTOKOLDE RADYAN
robot: {width: 18, length: 18}            # ayak izi; duvar kırpma + çizim
frames:
  robot:  {parent: field}
  turret: {parent: robot, xyz: [0, 1.5, 8], joint: revolute, axis: z, limits: [-180, 180]}
  camera: {parent: turret, xyz: [0, 4, 2], rpy: [0, -20, 0], hfov: 63.3, vfov: 49.7}
drivetrain: {type: mecanum, track_width: 13.0, wheel_base: 11.0, wheel_diameter: 4.0}
motors:                                   # ad = protokol anahtarı
  # pos = [x ileri, y sol] robot çerçevesi (aşağıdaki çerçeve kuralı)
  fl: {drives: wheel, pos: [ 6.5, 5.5], roller: 45,  ticks_per_rev: 537.7, free_rpm: 312, kV: 0.0, kS: 0.0}
  fr: {drives: wheel, pos: [ 6.5,-5.5], roller: -45, ticks_per_rev: 537.7, free_rpm: 312, kV: 0.0, kS: 0.0}
  bl: {drives: wheel, pos: [-6.5, 5.5], roller: -45, ticks_per_rev: 537.7, free_rpm: 312, kV: 0.0, kS: 0.0}
  br: {drives: wheel, pos: [-6.5,-5.5], roller: 45,  ticks_per_rev: 537.7, free_rpm: 312, kV: 0.0, kS: 0.0}
servos: {}
sensors:
  imu: {parent: robot}
  pinpoint: {parent: robot, xyz: [0, 0, 0]}
```
Faz 0/1'de sadece 4 tekerlek. Shooter/turret/tof/limelight **eklendiğinde** buraya
girer, protokol değişmez.

## Çerçeve kuralı (Pedro/FTC ile aynı — Faz 2.5'te çevrim yok)
- **Saha:** 144×144 in, orijin köşe, `x`,`y` ∈ [0,144]. `h` = robotun ileri yönünün saha
  `+x` ekseninden **CCW** açısı, radyan. `h=0` ⇒ robot `+x`'e bakar.
- **Robot:** `+x` ileri, `+y` SOL, dönüş CCW pozitif. `Drive.Manual(vx,vy,ω)` de bu çerçevede
  (`vy>0` = sola kayma). `mechanism.yaml`'daki tüm `pos`/`xyz` bu çerçevede.
- `imu.yaw` ile `pinpoint.h` aynı tanım; ikisi de seed'li gürültülü (σ 0.002 rad).
  Gürültüsüz sensör `truth`'u `:core`'a sızdırır — yasak.
- `free_rpm`: `kV=0` "ideal" modunda hız = `power × free_rpm`. Zorunlu alan.
- **Pedro 3.0 doğrulaması (15 Eyl, ftc-robot bytecode+belge):** saha, robot çerçevesi ve mecanum
  karışımı (FL=f−s−t, FR=f+s+t, BL=f+s−t, BR=f−s+t) Pedro ile birebir; çevrim gerekmez.
  0..144 Pedro kütüphanesinde değil belgede; biz protokolde zorluyoruz (bizimki daha sıkı).
  Pinpoint → Pedro `Localizer` hiçbir eksen/işaret/orijin dönüşümü yapmaz; çerçeve = `setPose` çerçevesi.
- **FTC-standart (orijin merkez, +x seyirciden uzağa) ↔ bizim/Pedro:**
  `x_p = y_f + 72`, `y_p = 72 − x_f`, `h_p = h_f − π/2`; tersi `x_f = 72 − y_p`, `y_f = x_p − 72`, `h_f = h_p + π/2`.
- **MeepMeep saha görseli** (FieldUtil: 141×141 in, px=(x_f+70.5)s, py=(70.5−y_f)s): görselde Pedro
  `+x` YUKARI, `+y` SOLA. Viewer'da `+x` sağ/`+y` yukarı için görsel **90° saat yönünde** döndürülür,
  aynalama yok. Görsel 141 in'e ölçeklenir, sahada her kenarda 1.5 in boşluk kalır (144'e esnetme yasak).
  Görselden geometri okunmaz.
- **İttifak kenarları (15 Eyl, görsel 38051f4'e göre):** KIRMIZI `x=0`, MAVİ `x=144`. Kaynak yalnızca
  Team Juice görseli; BIOBUZZ kılavuzuyla henüz doğrulanmadı. Viewer ızgarası 24 in'de kalır (çerçeve
  ölçüsü); görselin 23.5 in karosuyla kenarlara doğru ≤1 in ayrışma normaldir, hata değildir.
- **Uyarı:** `PoseFactory.mirrorX(a)` x→2a−x, h→−h; `mirrorY(a)` y→2a−y, h değişmez. Katı yansıma
  değil; ittifak aynalaması için kullanmadan önce test yaz.

## Mesajlar

### Java → Python
```json
{"type":"reset","seed":0,"pose":{"x":0,"y":0,"h":0}}
{"type":"step","dt_ms":20,"motors":{"fl":0.5,"fr":-0.3,"bl":0.5,"br":-0.3},"servos":{}}
{"type":"bye"}
```
`motors` değerleri −1..1 güç. Eksik anahtar = 0.

### Python → Java
```json
{"type":"ready","motors":["fl","fr","bl","br"],"servos":[],"proto":1,
 "state":{ ...aşağıdaki state ile aynı şema, t_ms=0, reset pozu... }}
{"type":"state","t_ms":1240,
 "enc":{"fl":1203,"fr":-870,"bl":1199,"br":-865},
 "vel":{"fl":2400.0,"fr":-1700.0,"bl":2400.0,"br":-1700.0},
 "imu":{"yaw":0.12},
 "pinpoint":{"x":3.1,"y":0.4,"h":0.12},
 "voltage":12.6,
 "gamepad":{"lx":0,"ly":-0.8,"rx":0,"ry":0,"a":false,"b":false,"x":false,"y":false,
            "lb":false,"rb":false,"lt":0,"rt":0,"dpad":"none"},
 "truth":{"x":3.0,"y":0.5,"h":0.12}}
```
- `enc` tam sayı tick, `vel` tick/s, açılar **radyan**, uzunluk **inç**.
- `ready` **başlangıç `state`'ini taşır** (t_ms=0): `RobotLoop` ilk tick'te `read()` çağırır, saat
  ilerlemeden geçerli bir durum olmalı. `dt_ms=0` geçersizdir.
- `t_ms` sim saati; Java tarafında `hal.now()` **budur** (anayasa kural 2).
- `gamepad`: pygame klavyesi/joystick'i. `SimHal` bunu `GamepadSource` olarak sunar;
  robotta aynı arayüzü `RealHal` OpMode'un `gamepad1`'inden doldurur.
- `truth`: **yalnızca viewer ve `:sim` testleri** okur. `:core` bu alanı hiç görmez —
  `RobotState`'e girmez.
- `voltage`: Faz 1'de sabit 12.6 olabilir; alan şimdiden var.

## Java tarafı tipler (`:core`, SDK'sız)
```java
record RobotAction(Map<String,Double> motors, Map<String,Double> servos) {}
record RobotState (long t, Map<String,Integer> enc, Map<String,Double> vel,
                   double yaw, Pose pinpoint, double voltage) {}
interface Hal           { long now(); RobotState read(); void write(RobotAction a); }
interface GamepadSource { GamepadState get(); }
```
Ad-anahtarlı map = `mechanism.yaml`'a motor eklemek `:core`'u değiştirmez.
(Kayıt/sealed Android'de derlenmezse düz final sınıf; buna zaman gömme.)

## Determinizm
Aynı `seed` + aynı `step` dizisi ⇒ bit-bit aynı `state` dizisi. Python tarafında
gürültü yalnızca `seed`'li RNG'den. Test: 500 adım iki kez koş, `truth` eşit olmalı.

## Faz 1 fizik (Python) — asgari
- Motor: `power → hedef hız = (power·V − kS)/kV`, birinci derece gecikme (τ ≈ 0.1 s).
  Faz 1'de kV/kS 0 ise "ideal": hız = power × serbest hız.
- Mecanum ters/düz kinematik → şasi twist → pozu Euler'le ilerlet. Sürtünme yok, çarpışma
  yok, duvar = kırpma. **PyBullet kapalı.**
- Enkoder: `carryover/encoder.py` (tick kuantizasyonu). Pinpoint = truth + seed'li gürültü
  (σ 0.05 in / 0.002 rad). Duvar kırpma çevrel yarıçapla (heading'den bağımsız).

## Karar günlüğü
- 15 Eyl: çerçeve kuralı, `robot` bloğu, `free_rpm`, imu gürültüsü eklendi (ftc-sim'in 4 sorusu).
  Robot çerçevesi ilk taslakta x-sağ/y-ileri idi; Pedro ile çakışmasın diye x-ileri/y-sol yapıldı.
- 15 Eyl: `ready` başlangıç state'i taşır (ftc-robot'un boşluğu; alternatif dt_ms=0 reddedildi — sıfır adım fizik için anlamsız).
- 15 Eyl: Pedro çerçeve araştırması → protokolde değişiklik YOK; FTC-standart çevrim, MeepMeep yönelimi (90° CW, 141 in) ve mirror uyarısı eklendi.
- 15 Eyl: ittifak kenarı görsele göre kırmızı x=0 / mavi x=144 (viewer yer tutucusu tersti, takas edildi); ızgara 24 in kaldı.
