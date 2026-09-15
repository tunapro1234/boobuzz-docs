# Engine iterasyonları

L2'nin tamamı **takılıp çıkarılabilir bir birimdir.** Her iterasyon yeni bir
`RobotEngine` bırakır; **eskiler silinmez.**

```java
RobotEngine engine = new C3VisionEngine(hal);   // C2'ye dönmek TEK SATIR
```

Amacı bu: world model bozulursa C3'e, vision bozulursa C2'ye, her şey bozulursa
C1'e dönersin — yarışma sabahı, tek satırla. Geçen sezon böyle bir geri dönüş
yoktu; `contingency/lvbelc5` paketi tam olarak bu eksikliğin panik hâlinde
yazılmış hâliydi.

Bu klasörde **her iterasyon için bir dosya** var. Kod ne yaptığını anlatır;
buradaki dosyalar **neyin değiştiğini, neyin daha iyi olduğunu ve neyin hâlâ
açık olduğunu** anlatır.

## Dosyalar

| Dosya | Engine | Durum |
|---|---|---|
| `01-c1.md` | `C1DriveEngine` — Localizer + manuel sürüş | Çalışıyor (sim) |
| `02-pedro.md` | `PedroDriveEngine` — Pedro Pathing 3.0 HAL üstünde | Çalışıyor (sim) |
| — | `C2SubsystemEngine` (Shooter/Intake/Feeder/Turret + balistik B1) | Faz 2, yazılmadı |
| — | `C3VisionEngine` (VisionAdapter, Turret TRACK, B2/B3) | Faz 3, yazılmadı |
| — | `C4WorldEngine` (WorldModel, Predictor, LookBook, SCAN) | Faz 4, yazılmadı |
| — | `C5FusionEngine` (ToF, erken füzyon, refleks hız kesme) | Faz 5, yazılmadı |

> `PedroDriveEngine` `plan.md`'deki C1–C5 harf dizisinde ayrı bir harf almaz;
> C1'in yol takibi kazanmış hâlidir ve C1'in yerine **geçmez** — `Drive.Manual`
> davranışını C1'e delege eder, ikisi yan yana durur.

---

## Şablon — yeni iterasyon açarken kopyala

```markdown
# NN-<ad> — <Engine sınıfı>

**Faz:** · **Dal:** · **İlk commit → son commit:** · **Yazan ajan:**

## 1. Amaç
Bu iterasyon neyi mümkün kılıyor? Bir cümle. Sonra: neden şimdi, önceki
iterasyonun neyi yapamadığı.

## 2. Mimari
Hangi sınıflar, hangi katmanda, tick sırası nasıl. Hangi dış kütüphane, hangi
sürüm, hangi gerçek imzalarla (varsayım değil — `javap`/kaynak çıktısı).

## 3. Neler değişti
Bir önceki iterasyona göre madde madde. Silinen, eklenen, davranışı değişen.
Sözleşme (`contract/`) değiştiyse ayrıca belirt — L3'ü kırar.

## 4. Ölçümler
Test sayısı, entegrasyon koşusu çıktısı, determinizm, ölçülen fiziksel değerler.
**İddia değil, komut çıktısı.** Ölçülmediyse "ölçülmedi".

## 5. Neyi daha iyi yaptı
Önceki iterasyona göre somut kazanç. Ölçülebiliyorsa sayı, ölçülemiyorsa neden.

## 6. Açık sorunlar
Bilinen eksikler, doğrulanmamış varsayımlar, sonraki iterasyona devredilenler.
Bilmediğini **"doldurulacak"** diye işaretle; uydurma.

## 7. Geri dönüş
Bu engine bozulursa hangi satır değişir, hangi engine'e düşülür.
```
