# 🛡️ Sentinel Hook - Kaynak Kod, Oturum (Auth) Analizi ve STRIDE Tehdit Modellemesi
> Phase 0.0 - Adım 5 Çıktısı

## 1. Uygulama İçi Kimlik Doğrulama (Authentication) Akışı ve Entrypoint
Bu projede amacımız, halihazırda biyometrik güvenlik (Face ID, Touch ID, Android BiometricPrompt) kullanan kapalı kaynak (proprietary) bir uygulamaya müdahale etmektir. 

Standart bir hedef bankacılık/kasa uygulamasında kimlik doğrulamanın **Başlangıç Noktası (Entrypoint)** şöyledir:
- **iOS:** `sceneDidBecomeActive` -> `LoginViewController: viewDidLoad` -> `LAContext().evaluatePolicy()`.
- **Android:** `MainActivity: onResume` -> `BiometricPrompt.authenticate()`.

### Auth Mekanizması:
- Mobil uygulamalar günümüzde REST API'lerle haberleştikleri için ana mekanizma genellikle **JWT (JSON Web Token)** veya **OAuth 2.0 Access Token**'dır.
- Biyometrik algılayıcı (`LocalAuthentication` veya `BiometricManager`) sadece *Yerel Cihazda* (Device-bound) kullanıcının cihaz sahibi olup olmadığını onaylar.
- Eğer biyometrik API'den `Successful` (olumlu) yanıt dönerse, mobil cihaz donanımsal güvenlik çipinde (iOS Secure Enclave, Android Keystore) saklanan şifrelenmiş Refresh/Access Token'ı çözer ve sunucuya gönderir.

## 2. Biz Nasıl Saldıracağız? (Saldırı Vektörü)
Bir hacker (veya projemiz olan Sentinel Hook aracı) doğrudan sunucuya saldırmak yerine, cihazın hafızasındaki fonksiyonları modifiye eder; yani **Dinamik Bellek Enjeksiyonu** (Frida) kullanır.

- **Vektör 1: API Hooking (Mantıksal Kısa Devre).** `evaluatePolicy()` fonksiyonunun geri döndürdüğü değeri bellekte anlık olarak manipüle edip `True`'ya çevirmek.
- **Vektör 2: Sensör Aldatmacası (Kamera Frame Injection).** Uygulama ML Kit kullanarak canlı kameradan yüz koordinat ve liveness (canlılık - örn: göz kırpma) tespiti yaparken, `AVCaptureSession` (iOS) veya `CameraDevice` (Android) katmanlarında araya girip, sensöre önceden çekilmiş statik bir ".jpg" dosyasını veya video tamponunu (replay-attack) yedirmek.

## 3. STRIDE Tehdit Modellemesi Simülasyonu 🕵️‍♂️
STRIDE metodolojisi uygulandığında, Sentinel Hook'un bir hedef uygulamaya yarattığı risk haritası şu şekildedir:

| STRIDE Unsuru | Sentinel Hook'un Rolü (Tehdit) | Hedef Uygulamadaki Zafiyet Noktası |
| :--- | :--- | :--- |
| **S**poofing (Kimlik Sahteciliği) | **Kritik:** Başka birinin biyometrik verisi/yüzü ile (veya hiç olmadan callback true yapılarak) içeri sızılması. | Face ID/Biometric API'nin cihaz dışından maniple edilmesine açık olması. |
| **T**ampering (Veri Manipülasyonu) | **Kritik:** Bellek içindeki `Boolean` doğrulama yanıtını (true/false) veya Kamera Stream Array'ini manipüle etmek. | Dinamik hafızanın (RAM) korunmaması. Jailbreak/Root kontrolünün yapılmaması veya bypass edilebilmesi. |
| **R**epudiation (İnkar Edilebilirlik) | **Orta:** Başarılı bir bypass sonrasında token alındığı için sunucu bunu yasal kullanıcının yaptığını zanneder. | Sunucunun yerel biyometrik istekle gelen onayı ayırt edememesi. |
| **I**nformation Disclosure (Bilgi Sızıntısı) | **Yüksek:** Uygulamanın statik analizi esnasında, APK/İPA tersine çevrilerek (Ghidra, Hopper) harcode edilmiş keylerin çıkarılması. | Obfuscation (kod karmaşası) kullanılmaması veya yetersiz olması. Hardcoded JWT secret'lar. |
| **D**enial of Service (Servis Reddi) | **Düşük:** Uygulamayı çökertecek bellek taşması (Buffer Overflow) saldırıları yapmak veya kamera API'sini sürekli crash etmek. | Exception Handling eksikliği. |
| **E**levation of Privilege (Yetki Yükseltme) | **Kritik:** Bypass sonrası root yetkilerinin kullanılarak hedef uygulamanın Sandbox'ının delinmesi. Sızılan Token ile Admin işleri yapılması. | Cihaz üzerindeki ayrıcalık modelinin zayıflığı. |

## 4. Savunma İçin Risk İyileştirmeleri (Mitigation)
Bir geliştiricinin Sentinel Hook aracından (yani bizden) korunması için yapması gerekenler:
1. Sadece `LocalAuthentication` veya True/False mantığına güvenmemek. Bunun yerine **CryptoObject / Enclave Bound Key** (Biyometrik okuyucunun doğrudan şifreleme/imzalama işlemine katılması) yapısını zorunlu tutmak.
2. Yazılım içerisine ciddi **Jailbreak/Root/Hooking (Frida) Tespiti** entegre etmek. 
3. Network iletişimlerini SSL Pinning ile korumaya almak.
