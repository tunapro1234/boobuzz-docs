# Devir: ftc-main → ftc-main-cx (15 Eyl 2026, ~06:50)
ftc-main (Claude) limit nedeniyle duruyor, limit 07:40'ta (Chicago) sıfırlanır. O zamana kadar
koordinasyon ftc-main-cx'te. Tuna'nın şartı: AŞAMAYI TAMAMLA ama ftc-main KONTROL ETMEDEN
BİR SONRAKİ AŞAMAYA GEÇME. Kontrol = ftc-main'in review'ı; sen review yapmazsın.

## Kurallar (bağlayıcı)
- Protokol: docs/protokol.md — SADECE ftc-main düzenler. Değiştirmeyin.
- Git: main yok; stable/dev/dev-phase-N. Her tam parça commit + anında push. Tag ATMAYIN.
- Commit sonuna: "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" ve
  "Claude-Session: https://claude.ai/code/session_01SdkrbNwP3QT1rYDjT5r478".
- ball-auto-istic bekliyor; ftc-ball-cx'e görev verme.
- Mesajlaşma: bp msg; Codex panellerinde doğrulanmazsa tmux send-keys -l + Enter.
- Tahmin yok; her iddia komut çıktısına dayanır; "bulamadım" yazılır.

## Devam eden işler
1. ftc-robot-cx → robot-cx-01: docs/phases/phase-1/robot-cx-01-pedro-hal.md (Faz 2.5 adım 1).
   Rapor gelince: sadece kabul ölçütlerine karşı özetle, hash'leri kaydet, BEKLE.
   Tutmayan varsa Codex'e spec içinde düzelttir; yeni kapsam ekleme.
2. ftc-sim-cx → sim-cx-00 bitti (dev=dev-phase-2=f4bea22). Son istek: ./run_tests.sh ile 44 test
   doğrulaması. Sonucu kaydet. Python tarafında yeni kod işi YOK (Faz 2.5 Java'da).
3. ftc-sim / ftc-robot (Claude) boşta; onlara görev verme, bağlam pahalı.

## Durum özeti
- re-cock-nize dev-phase-2 @ f4bea22 (saha görseli 90° CW 141 in, kırmızı x=0 mavi x=144,
  klavye testleri, SIGTERM düzeltmesi, 44 test).
- robot-code dev-phase-1 @ c9907c9; robot-cx dev-phase-2 açıyor.
- Tuna'nın saha/hizalama onayı ve 09.15.1 tag'i BEKLİYOR — ftc-main karar verir.

## ftc-main döndüğünde
Sonuçları docs/phases/phase-1/devir-rapor.md'ye yaz: hash'ler, test sayıları, entegrasyon koşusu son poz,
açık sorunlar. ftc-main bunu okuyup review başlatır.
