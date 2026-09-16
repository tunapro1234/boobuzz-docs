# Bloat avı listesi (Opus, 15 Eyl 2026) — robot-code df0ead4 / re-cock-nize 2d8e679
## A) robot-code
1 hal/Probe.java + NullProbe.java + RobotLoop 4-arg ctor/probe.publish — ölü zincir — SİL
8 hal/RobotState enc(String)/vel(String) — 0 çağrı — SİL
9 hal/Mechanism Footprint + robot alanı — Java'da okunmuyor (Python kullanıyor, yaml kalır) — SİL (Java)
10 hal/Mechanism Drivetrain.type/trackWidth/wheelBase — yalnız wheelDiameter okunuyor — SİL alanlar
11 hal/Mechanism Physics.batteryV/motorTauSeconds — Java okumuyor (yaml kalır) — SİL alanlar
12 hal/Mechanism Motor.name — 0 çağrı — SİL
13 controller/GamepadController driveScale + 2-arg ctor — sabit 1.0 — SİL
14 CplxEngine1(Mechanism, PathRegistry) ctor — 0 çağrı — SİL
15 HalDrivetrain(Mechanism) ctor — yalnız testler — SİL, testler String[] ctor kullansın
16 HalDrivetrain drivePowers/manual alanları + debug() — kimse çağırmıyor — SİL
17 HalDrivetrain stop(boolean) — parametre okunmuyor — stop() ile BİRLEŞTİR
18 PedroConstants HEADING_KP/FORWARD_/STRAFE_ public — private yap
19 GamepadController fieldOriented()/headingOffset() — yalnız test — SİL, test davranışa baksın
20 DriveSubsystem activeCommand()/followerMode()/deltaTimeSeconds() — yalnız test — SİL, test davranışa baksın
22 DriveSubsystem.pedro() statik fabrika — ctor'u public yap, fabrikayı SİL
23 mecanum karışım matrisi DriveSubsystem:125 / HalDrivetrain:47 / (sim test FakeSimServer:108) — tek yardımcıya BİRLEŞTİR (core içinde tek yer; FakeSimServer test kopyası kalabilir)
24 HalDrivetrain drive() ile unnormalized() aynı 4 satır — BİRLEŞTİR
25 clip yardımcıları RealHal/HalDrivetrain/clip01/DriveSubsystem peak-normalizasyon — tek yerde BİRLEŞTİR
27 Mechanism compact ctor physics kopyası — SİL
28 MechanismLoader close IOException→MechanismException — BASİTLEŞTİR
29 MechanismLoader str/num/doubles/coordinate sessiz fallback'ler — kaldır, requireX kullan (sessiz kayma yasak)
30 sim/Json num() String/Boolean dalı — SİL
31 sim/SimHal fill() çift savunma — BASİTLEŞTİR
32 sim/SimHal dpad dörtlü savunma — BASİTLEŞTİR (protokol zorunlu+enum)
33 test dosyalarında kendi paketinden import — SİL
34 contract/WorldSnapshot, Drive, RequestType "C2/C4 ile gelir" yorumları — SİL (yalnız yorum; contract KODUNA DOKUNMA)
35 mechanism.yaml units.length — SİL
36 mechanism.yaml frames — SİL
37 mechanism.yaml track_width/wheel_base — kimse okumuyor — SİL (Python Drivetrain alanı da, bkz B6)
38 mechanism.yaml sensors.imu.parent / pinpoint.parent — SİL
39 RobotLoopTest gamepadControllerStickleriDogruCevirir — kopya — SİL
40 CplxEngine1Test manuel mecanum — DriveSubsystemTest kopyası — SİL
41 "bilinmeyen yol" 3 test — PathRegistryTest'te kalsın, diğer ikisi SİL
42 SimHalTest saatHaldenGelir — boş assert — SİL
YAPILMAYACAK: 2-7 (contract/ kodu: Request/RequestType/RequestStatus/cancels/Constraints/Velocity — Tuna dondurma kararı bekleniyor), 21 (SimHal.truth kabul çıktısı için kalır), 26 (Loader/Json birleştirme — riskli, değmez), 43.
## B) re-cock-nize
1 sim/encoder.py wheel_rpm_resolution — SİL
2 sim/viewer.py save_png — SİL
3 sim/field.py RED_WALL/BLUE_WALL — SİL
4 sim/field.py ELEMENTS + viewer döngüsü — SİL
5 sim/mechanism.py Mechanism.sensors — SİL
6 sim/mechanism.py Drivetrain.track_width/wheel_base — SİL (yaml'dan da kalkıyor, A37)
7 sim/mechanism.py Motor.gear — yaml'da yok, hep 1.0 — SİL (+ test assert)
8 sim/mechanism.py 6 ayrı doğrulama bloğu — tek küçük yardımcıya BASİTLEŞTİR (doğrulama kalır, tekrar gider)
9 sim/physics.py target_rpm kV/kS dalı — hiç koşmuyor — SİL (yaml kV/kS alanları da)
11 sim/server.py unknown motor kontrolü — SİL (protokol eksik=0)
12 tests/test_mechanism.py test_motor_order_follows_yaml — SİL
13 tests/test_kinematics.py test_forward_all_wheels_equal_and_positive — SİL
14 tests/test_determinism.py test_ready_state_is_bit_identical_across_runs — SİL
15 tests/test_kinematics.py:111 ölü assert — SİL
16 tests/test_signal.py _start kopyası — preexec_fn parametresiyle BİRLEŞTİR
YAPILMAYACAK: 10 (tools/fake_client araç), 17 (fixture bilinçli kopya).
