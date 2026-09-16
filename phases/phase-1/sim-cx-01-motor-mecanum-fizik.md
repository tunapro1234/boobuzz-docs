# sim-cx-01 — Motor elektriği + gerçek mecanum kinematiği + geçen sezon kalibrasyonu

Repo: re-cock-nize, dal `dev-phase-2` (f4bea22'den devam). Her bağımsız adım AYRI commit + anında push.
Protokol (docs/protokol.md) DEĞİŞMEZ; state/step mesaj alanlarına dokunma. Viewer'a dokunma.
Kod yazmadan önce mevcut fizik kodunu oku (sim/ altında robot/physics/model ne varsa) ve
§0 raporunu ver; tahmin yok. Bloat yok: yeni sınıf yalnız gerekirse.

## §0 Önce rapor (≤15 satır, bp msg ftc-main; cevap beklemeden §1'e geç)
Mevcut hareket modeli: motor gücü → hız nasıl çevriliyor, atalet/gecikme var mı, mecanum
matrisi nerede, hangi parametreler mechanism.yaml'da.

## §1 Motor elektrik modeli (commit 1)
Her tekerin gücü p∈[−1,1] doğrudan hız olmasın. Model, teker başına:
  V_uygulanan = p · V_batarya (V_batarya = 12.0 nominal, mechanism.yaml'da)
  ω_hedef = (V_uygulanan / V_nominal) · ω_max
  ω_teker, ω_hedef'e birinci dereceden gecikmeyle yaklaşır: τ_motor = 0.12 s (varsayılan, yaml'da)
Teker başına verimlilik çarpanı: efficiency: {fl:1.0, fr:1.0, bl:1.0, br:1.0} (yaml; veri yok,
1.0 bırak, parametre olsun). Teker RPM/tick/çap verisi YOK → ω_max hız hedefinden türetilecek (§2).

## §2 Mecanum kinematiği + kalibrasyon (commit 2)
Robot çerçevesi: +x ileri, +y SOL, CCW+. Protokoldeki matrisin tersi (forward kinematics):
  vx = (fl+fr+bl+br)/4 · v_scale
  vy = (−fl+fr+bl−br)/4 · v_scale · strafe_eff
  ω  = (−fl+fr−bl+br)/4 · v_scale / r_eff
(fl,fr,bl,br burada teker çevre hızı; işaretleri protokoldeki fl=vx−vy−ω … ile TUTARLI olacak,
birim testle doğrula: yalnız fl=fr=bl=br=1 → saf ileri; fl=−1,fr=1,bl=1,br=−1 → saf sola.)
Kalibrasyon (geçen sezon, archive/ftc/de-cock … pedroPathing/Constants.java — yaml'a kaynak
yorumu ile yaz):
  max_forward_in_s: 73.63      # xVelocity
  max_strafe_in_s:  54.09      # yVelocity → strafe_eff = 54.09/73.63 = 0.7346
  zero_power_decel_forward_in_s2: 36.17
  zero_power_decel_lateral_in_s2: 85.98
  mass_kg: 13.8
  track_width_mm: 400  wheelbase_mm: 449   # HardwareConstants.Chassis
  r_eff = (track+wheelbase)/4 türet, mm→inç
Sıfır-güç yavaşlama: güç 0 iken robot hızı eksen başına yukarıdaki ivmeyle sıfıra sürtünsün
(ileri/yanal ayrı, robot çerçevesinde). Bu "kayma"nın yaml'daki tek temsili; ayrı slip modeli
YAZMA.

## §3 Testler (commit 3)
- Tam ileri güç: 2 s sonra hız 73.63 ±5 %. Tam sol strafe: 54.09 ±5 %.
- Güç kesilince ileri hızdan durma mesafesi ≈ v²/(2·36.17) ±10 %.
- τ_motor: ilk adımda hız sıçramıyor (|v| < 0.3·v_max ilk 50 ms'de).
- Determinizm: aynı seed iki koşu bit-bit aynı (mevcut test varsa genişlet).
- `./run_tests.sh` yeşil (unittest; pytest YOK).

## §4 Entegrasyon kabulü (rapor; kod değil)
robot-code dev-phase-2 (3c115a7) SimMain `--engine pedro --path test-line`, port 5556, 1000 adım:
kabul bandına giriş adımı, son truth. Pedro sabitleri aynı kalibrasyondan geldiği için
ulaşmalı; ulaşmazsa DÜZELTME YAPMA, çıktıyı rapora koy.
Komut ortamı: `export JAVA_HOME=/usr/lib/jvm/java-21-openjdk`.

## §5 Rapor (≤20 satır, bp msg ftc-main): commit hash'leri, §3 ölçülen değerler, §4 çıktısı,
yaml'a eklenen parametre listesi. Commit dipnotu:
  Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01SdkrbNwP3QT1rYDjT5r478
