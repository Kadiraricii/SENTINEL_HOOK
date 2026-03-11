# 🛡️ Sentinel Hook - CI/CD Pipeline & Webhook Analizi
> Phase 0.0 - Adım 3 Çıktısı

## 1. Repodaki CI/CD Pipeline İncelemesi
Bu projede GitHub Actions (`.github/workflows/main.yml`) kullanılarak bir Sürekli Entegrasyon (CI) akışı oluşturulmuştur.

### A. Tetikleyici Koşulları (Triggers)
Pipeline şu durumlarda tetiklenir:
1. `main` veya `develop` dalına (branch) doğrudan bir kod atıldığında (`push`).
2. `main` branch'ine bir Pull Request açıldığında (`pull_request`).
3. Dışarıdan özel bir **Webhook** isteği (`repository_dispatch` eventi) gönderildiğinde.

### B. Adım Adım İş Akışı Analizi (Build & Test Job)
Runner Ortamı: `ubuntu-latest` (Geçici, temiz bir taze container ortamı)

1. **Checkout:** Projenin son kaynak kodu ortam içine klonlanıp alınır.
2. **Setup Node & Python:** Frida'nın JS ve Python binding'leri için 2 ortam da `npm` ve `pip` cache'leme desteği ile kurulur (hız için).
3. **Linting Tools Kurulumu:** Kod standarlarını denetlemek için ESLint, Flake8 ve Bandit paketleri indirilir.
4. **Secret Leak Scan (Kritik Güvenlik Adımı!):** `trufflesecurity/trufflehog` Action'u çalıştırılır. Amacı geliştiricinin yanlışlıkla Apple Developer Key veya AWS API Key gibi şifreleri (`hardcoded secrets`) commit'leyip commit'lemediğinin Repository genelinde taranmasıdır.
5. **Lint & Test:** Statik kod analizi yapılır, ardından birim testler koşturulur. Eğer birim testlerden biri patlarsa, `set -e` yapısı gereği işlem kodu Unix standartlarında non-zero (0 hariç) döneceği için CI/CD pipeline **kırmızı**ya döner, durur ve Pull Request onaylanması engellenir.
6. **Build Payloads:** Frida tabanlı `.js` dosyaları ECMAScript6 ve modern import'lar kullanılarak yazılacaksa `frida-compile` gibi paketler üzerinden enjekte edilebilir, tek dosya (bundle) haline paketlenir.

## 2. CI/CD Simülasyon Sonuçları 🚀
*Senaryo: Bozuk bir kod push edildiği simülasyon.*
- **Olay:** Geliştirici, içerisinde `AKIAIOSFODNN7EXAMPLE` gibi bir AWS test anahtarı olan kodu push etti.
- **Tepki:** TruffleHog adımı çalışır. Şifreyi bulur bulmaz `exit 1` döner.
- **Sonuç:** Pipeline "Lint Python" ve "Test" kısımlarına geçemeden iptal olur (Fail). Geliştirici hata loglarını görür.

---

## 3. KRİTİK SORU: "Webhook" nedir ve bu proje özelinde ne işe yarar?

### Webhook Nedir?
Webhook'lar (kullanıcı tanımlı HTTP geri çağırımları - HTTP Callbacks), bir uygulamanın diğer bir uygulamaya belirli olaylar gerçekleştiğinde **gerçek zamanlı veri göndermesini** sağlayan mekanizmalardır.
- "Sürekli gidip sormak (Polling)" yerine "Olay olunca adresime veri at" mantığıyla çalışır. Genelde olay bir JSON verisi (payload) olarak HTTP POST isteğiyle iletilir.

### Bu Projede (Sentinel Hook) Ne İşe Yarar?
1. **Dışarıdan CI/CD Tetikleme (Repository Dispatch):**
   - Workflow dosyamızda `repository_dispatch: types: [target_analyzed_webhook]` ayarı mevcuttur.
   - Sentinel Hook için bir "Otomatik Keşif Scripti (Recon)" arka planda bir APK veya IPA analizini bitirdiğinde, GitHub'a bir HTTP POST (Webhook) atabilir. GitHub bunu aldığında otomatik olarak hook'ları build etmeye ve emülatördeki test senaryolarını koşturmaya (CI) başlayabilir.

2. **Hook Payload Data İletimi Sömürüsü (Saldırı / Bilgi Toplama):**
   - **Bypass Bağlamı:** Uygulamaya (Kamera / Biyometrik) müdahale edip başarılı girişi (`true`) sağladığımızda çalışan Frida scripti, bunu başardığı anda arka planda kendi kontrolümüzdeki bir C2 (Command and Control) veya Dinleme sunucusuna sessizce bir webhook (HTTP POST isteği) atarak "Bypass başarılı oldu, kullanıcının gerçek eylemleri şu anda devrede" bilgisini iletebilir.
   - **Log ve Görüntü Çalma:** İndirilen/çekilen kamera frame'leri bypass sırasında kaydedilirse (Replay Attack), bu by-pass bittiğinde sızdırılan veriler bir dış webhook aracılığıyla saldırgan sunucuya (Dropzone) postalanabilir.

### Webhook Güvenliği
Webhook'lar dışarıya (İnternete) açık uç noktalar (endpoints) olduğundan izinsiz kişilerin sahte istek (Spoofing) üretmesini engellemek için:
1. Kaynağın kimliğini doğrulamak amaçlı istek başlığında (Header) **HMAC (Hash-based Message Authentication Code)** ile özel bir imzalı token yollanmalıdır.
2. Webhook'u karşılayan sunucu ip sadece beklenen CI/CD sunucularından (Örn: GitHub IP Whitelist) gelecek isteklere açılmalıdır.
