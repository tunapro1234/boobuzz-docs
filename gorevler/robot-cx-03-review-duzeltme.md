# robot-cx-03 — robot-cx-01 review düzeltmeleri

Repo: robot-code, dal `dev-phase-2` (HEAD dd4bd3f). Review kaynağı: ftc-main'in Opus review ajanı,
diff `c9907c9..dd4bd3f`. BLOKER yok; aşağıdakiler yapılacak. Her madde AYRI commit + anında push.
Kod yazmadan önce ilgili dosyayı oku; tahmin yok. Bloat ekleme, yeni soyutlama açma.

## A. ÖNEMLİ (zorunlu)
A1. `HalLocalizer.java:58` — `applyOffset` heading'e `offsetHeading` ekliyor ama saha hızını
    döndürmüyor → `setPose` heading değiştirince `twist()` offsetHeading kadar yanlış.
    Yap: hızı da `offsetHeading` kadar döndür (rotate). Test: heading offset π/2 ile
    `twist()` beklenen değerleri.
A2. `HalDrivetrain.java:58` — `maxScaling` testsiz; taban zaten doygunsa 1.0 dönüyor.
    Yap: taban |·|>1 ise 0 döndür. Birim test: doygun taban, ters işaretli delta, delta=0.
A3. `HalLocalizerTest.java:36` — `twist()` yalnız heading=0'da sınanıyor (dönüşü test etmiyor).
    Yap: heading=π/2 örneği ekle: `twist().vx ≈ vy_saha`, `twist().vy ≈ −vx_saha`.
A4. `PedroConstants.java:16` — `MASS_KG` hiçbir yere bağlı değil.
    Yap: Pedro 3.0 `ForesightConfig`'de kütle alanı var mı `javap` ile bak. Varsa bağla;
    yoksa sabiti SİL (ölü sabit tutma), rapora yaz.
A5. Entegrasyon koşusu: spec robot-cx-01 §3 koşusunu (port 5556, test-line, 1000 adım,
    seed=1 ×2) düzeltmelerden SONRA tekrar koştur; son truth/pinpoint satırlarını ve iki
    koşunun bit-bit eşitliğini rapora KOPYALA (iddia değil çıktı).

## B. KÜÇÜK (zorunlu, tek commit'te toplanabilir: "review küçük düzeltmeler")
B1. `HalLocalizer.java:98` — `reset()` heading'i sarmıyor (6.282678'in kaynağı). `wrap()` uygula.
B2. `HalLocalizer.java:23` — `lastState` alanı `rawPose` ile aynı; sil, `reset()` `rawPose` kullansın.
B3. `PathRegistry.java:44` `paths()` ve `PedroDriveEngine.java:116-126` `localizer()/drivetrain()/follower()`
    kullanılmıyor → sil.
B4. `PedroDriveEngine.java:106-107` `sameCommand` → parantezle ya da ayrı if'lere böl.
B5. `PedroDriveEngine.java:85` — Javadoc: "GoTo.constraints Faz 2.5'te uygulanmıyor".
B6. `SimMain.java:55` — `--path` ile `--drive` birlikte verilirse hata at (sessiz yutma yok).
B7. `PedroDriveEngineTest.java:36-40` — `assertEquals` sonrası bit-bit döngü fazlalık; birini kaldır.
B8. `PathRegistry` için küçük birim test: bilinen id döner, bilinmeyen id hata. `test-turn`
    hedefinin (120,72) olduğunu yorumla sabitle.

## C. Yapılmayacaklar
- `HalDrivetrain.java:33` C1DriveEngine örneği (KÜÇÜK bulgu) — DOKUNMA, katman taşıma (robot-cx-02) ile birlikte ele alınacak.
- Protokol, mechanism.yaml, Python, TeamCode'a dokunma. Dosya taşıma yok.

## D. Kabul
- `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :core:test :sim:test` yeşil.
- Her commit tek madde, push edilmiş. Commit dipnotu:
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01SdkrbNwP3QT1rYDjT5r478`
- Bitince ≤20 satır rapor: commit hash listesi, A4 kararı, A5 çıktısı. `bp msg ftc-main` ile gönder.
