# sim-cx-01 raporu (ftc-sim-cx, 15 Eyl 2026) — re-cock-nize dev-phase-1
Commitler: 0770dd6 (YAML battery/tau/efficiency), f048c86 (strafe verimi + sıfır-güç yavaşlama + türetilmiş free_rpm), 41c637b (kabul/determinizm testleri), 6432808 (fixture Pinpoint 161/0 eşitleme).
Testler: ./run_tests.sh Ran 50, OK (skipped=6).
Ölçümler: ileri kararlı hız 73.630 in/s (hedef 73.63); sol strafe 54.089 in/s (hedef 54.09); ilk 20 ms hız/vmax 0.181 (<0.3, motor_tau_s=0.1); sıfır-güç ileri durma mesafesi 74.21 in, teori 74.94 in (%0.98 fark); aynı-seed 500 adım bit-bit aynı.
Pedro entegrasyonu (robot-code 3c115a7, test-line, 1000 adım): kabul bandına giriş adımı 64; 1000. adım truth (120.0020, 71.9599, 0.000102).
YAML physics: battery_v=12.0, motor_tau_s=0.1, efficiency fl/fr/bl/br=1.0, strafe_eff=0.7346, decel forward=36.17 / lateral=85.98 in/s², free_rpm=351.557 (73.63 in/s ve 4 in çaptan türetildi). Kaynak: geçen sezon (DECODE) Pedro Constants.java.
