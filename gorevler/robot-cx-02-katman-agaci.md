# Görev robot-cx-02 — TeamCode'da L1/L2/L3 katman ağacı (ÖNCE RAPOR, kod yok)

Repo /home/shared/projects/boobuzz/robot-code, dal dev-phase-2. Bu görevde KOD YAZILMAZ, dosya taşınmaz.
Çıktı: /home/shared/projects/boobuzz/docs/gorevler/robot-cx-02-rapor.md (≤120 satır) + bp msg ftc-main "rapor hazır".

Tuna'nın şartları (bağlayıcı):
- TeamCode ağacında L1 HAL / L2 logic-engine / L3 controller ayrımı dizin/paket düzeyinde GÖRÜNÜR olacak.
- Ortak mantık kopyalanmayacak; :core SDK'sız kalacak (gradle/sdk-guard.gradle); robot ve sim AYNI :core bytecode'unu koşacak.
- :sim modülü kalırsa yalnız ince L1 adapter olacak: SimHal, soket/protokol istemcisi, SimMain, test fixture'ları.
- Her bağımsız adım ayrı commit + anında push (uygulama aşamasında).

Rapor bölümleri:
1. MEVCUT AĞAÇ: TeamCode/src ve core/, sim/ altındaki tüm Java dosyaları, her biri için hangi katman (L1/L2/L3/diğer) ve neden. `find`/`tree` çıktısına dayan.
2. ÖNERİLEN AĞAÇ: paket adlarıyla (ör. org.firstinspires.ftc.teamcode.l1.hal / boobuzz.core.l2.engine / l3.control gibi; mevcut docs/mimari.md adlandırmasıyla tutarlı olsun, mimari.md'yi oku). :core içindeki paketlerin de katman öneki alıp almayacağına dair öneri + gerekçe.
3. TAŞIMA LİSTESİ: eski yol → yeni yol, satır satır; hangi sınıflar TeamCode'dan :core'a iner (SDK bağımsızsa), hangileri TeamCode'da kalır (SDK'lı). Her satır bir commit adayı olacak şekilde gruplandır (git mv + import düzeltme + build yeşil).
4. GRADLE YÖNÜ: bağımlılık oku TeamCode → :core, :sim → :core; tersi olmayacak. Pedro core (:core'da api) ve revhub (TeamCode) yerleşimi. Değişmesi gereken build dosyası varsa hangi satır.
5. :sim TUT/SİL GEREKÇESİ: :sim'de kalan her dosyanın "ince L1 adapter" tanımına uyup uymadığı; uymayan varsa nereye gider. Kararı ftc-main verecek, sen iki seçeneğin maliyetini yaz.
6. RİSKLER: TeamCode'daki OpMode kayıtları, Android paket adı kısıtları, mevcut Hardware.java (pinpoint ofsetleri) gibi taşınırken kırılabilecekler.

Yapılmayacaklar: kod/dosya değişikliği, commit, protokol.md/mechanism.yaml düzenleme, tahmin (görmediğin dosyayı "muhtemelen" diye yazma).
