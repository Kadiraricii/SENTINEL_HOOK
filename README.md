# 🛡️ Sentinel Hook - Biometric Logic Bypass Framework

**Sentinel Hook**, mobil uygulamaların (iOS ve Android) kamera kaynaklarına ve biyometrik (FaceID/TouchID/BiometricPrompt) doğrulama süreçlerine düşük seviyeli (API) müdahaleler (hooking) gerçekleştirmek amacıyla geliştirilen dinamik bir siber güvenlik araştırma kütüphanesidir.

## 📱 Öncelik: iOS-First
Proje mevcut haliyle **iOS Öncelikli (iOS-First)** olarak tasarlanmaktadır. 
Öncelikli test hedefleri:
- `LocalAuthentication` Framework (Face ID/Touch ID Modifikasyonu)
- `AVCaptureSession` / `CoreVideo` (Kamera CVPixelBuffer Enjeksiyonu)

## 🏗️ Altyapı ve Kurulum
Projenin tamamen izole ve iz bırakmayacak şekilde çalışması için yapılandırılmış adımları kullanın:

1. **Gereksinimler:**
   - Node.js (20+) (*frida-compile için*)
   - Python 3.10+
   - Jailbroken iOS cihaz (Palera1n, unc0ver, vb.) veya Corellium.

2. **Kurulum:**
   Projeyi klonladıktan sonra `install.sh` dosyasını analiz edin ve ortamı kurun.
   ```bash
   # Sanal ortamı başlat
   python3 -m venv .venv
   source .venv/bin/activate
   pip install frida-tools objection
   npm install
   ```

3. **İzolasyon:**
   Projeyle işiniz bittiğinde tüm kalıntıları temizlemek için gizli `cleanup.sh` dosyasını çalıştırın.

## 📝 TODO ve Takip
Proje aşamaları (Phase 0.0'dan 10'a kadar) `TODO.md` dosyasında belgelenmiş olup, her adım git commiti ile işlenmektedir.
