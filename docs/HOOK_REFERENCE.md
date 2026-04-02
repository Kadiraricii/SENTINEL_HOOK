# 🪝 Sentinel Hook — Hook Referans Kılavuzu

> **Kapsam:** iOS hook modülleri (cloak, keychain, camera)  
> **Frida Sürümü:** 16.2.x  
> **Hedef Platform:** iOS 14–18

---

## Genel Bakış

Her hook modülü, `Interceptor.attach()` veya `ObjC.classes` API'si aracılığıyla hedef fonksiyonu ele geçirir. Modüllerin çalışma sırası kritiktir:

```
[1] cloak.js  ──►  [2] keychain.js  ──►  [3] camera.js
```

---

## Modül 1: `hooks/ios/cloak.js` — Jailbreak / Anti-Tamper Bypass

### Amaç
Hedef uygulamanın jailbreak tespiti yapan native C fonksiyonlarını noktalayarak cihazın "temiz" görünmesini sağlar. Bu modül çalışmadan diğer hook'lar tespit edilip engellenir.

### Hedeflenen Sistem Fonksiyonları

| Fonksiyon | Kütüphane | Neden Hedefleniyor |
|:----------|:----------|:-------------------|
| `stat64` | `libSystem.B.dylib` | `stat("/Applications/Cydia.app")` tespitini engeller |
| `access` | `libSystem.B.dylib` | `/bin/bash`, `/usr/sbin/sshd` path kontrollerini engeller |
| `fork` | `libSystem.B.dylib` | Fork anomali tespitini (sandbox kaçış kontrolü) engeller |
| `posix_spawn` | `libSystem.B.dylib` | Spawn tabanlı jailbreak tespitini engeller |
| `getenv` | `libSystem.B.dylib` | `DYLD_INSERT_LIBRARIES` env var tespitini engeller |
| `dlopen` | `libdyld.dylib` | Frida dylib yükleme tespitini gizler |

### Giriş / Çıkış Parametreleri

```js
// stat64 hook — örnek
Interceptor.attach(
  Module.findExportByName('libSystem.B.dylib', 'stat64'),
  {
    onEnter(args) {
      this.path = args[0].readUtf8String();  // IN: const char* path
      this.stat = args[1];                   // IN/OUT: struct stat* buf
    },
    onLeave(retval) {
      // OUT: int (0 = başarı, -1 = hata)
      const BLOCKED_PATHS = [
        '/Applications/Cydia.app',
        '/usr/bin/ssh',
        '/bin/bash',
        '/etc/apt'
      ];
      if (BLOCKED_PATHS.some(p => this.path.includes(p))) {
        retval.replace(-1);  // Dosya yokmuş gibi davran
      }
    }
  }
);
```

### Yan Etkiler & Dikkat Edilecekler
- `stat64` hooklama agresiftir; sistem dosyalarına erişen meşru app fonksiyonlarını etkileyebilir.
- `fork` blocklama bazı uygulamalarda çökmeye yol açar — `safe_boot.js` wrapper kullanın.

---

## Modül 2: `hooks/ios/keychain.js` — Keychain & SecItem Bypass

### Amaç
iOS Keychain'de saklanan token, sertifika ve şifre gibi gizli verileri okur; gerekirse bypass sonrası kullanılabilir hale getirir.

### Hedeflenen Sistem Fonksiyonları

| Fonksiyon | Framework | Neden Hedefleniyor |
|:----------|:----------|:-------------------|
| `SecItemCopyMatching` | `Security.framework` | Keychain'den veri okuma ana API'si |
| `SecItemAdd` | `Security.framework` | Yeni Keychain kaydı oluşturma |
| `SecItemUpdate` | `Security.framework` | Mevcut Keychain kaydını değiştirme |
| `SecKeyCreateSignature` | `Security.framework` | Private key ile imzalama (CryptoObject) |
| `SecAccessControlCreateWithFlags` | `Security.framework` | Biyometrik bağlı anahtar kontrolü |
| `_CC_SHA256` | `libcommonCrypto.dylib` | Hash doğrulama manipülasyonu |

### Giriş / Çıkış Parametreleri

```js
// SecItemCopyMatching hook
Interceptor.attach(
  Module.findExportByName('Security', 'SecItemCopyMatching'),
  {
    onEnter(args) {
      // IN: CFDictionaryRef query — aranacak item kriterleri
      this.query = new ObjC.Object(args[0]);
      // IN/OUT: CFTypeRef* result — sonucun yazılacağı pointer
      this.resultPtr = args[1];
    },
    onLeave(retval) {
      // OUT: OSStatus (0 = errSecSuccess)
      // retval.replace(ptr(0)) ile başarı simüle edilebilir
      send({
        type: 'keychain_access',
        query: this.query.toString(),
        status: retval.toInt32()
      });
    }
  }
);
```

### Bypass Senaryosu: Biyometrik Bağlı Anahtar

Bazı uygulamalar `kSecAccessControlBiometryCurrentSet` ile anahtarı biyometrik sensöre bağlar. Bu durumda:
1. `SecItemCopyMatching` doğrudan `errSecAuthFailed` döndürür.
2. Sentinel, `LAContext` ile önceden bir `evaluatePolicy` bypass yapmalı.
3. Ardından `SecItemCopyMatching` yeniden çağrıldığında başarıyla veri alınır.

---

## Modül 3: `hooks/ios/camera.js` — AVFoundation Frame Enjeksiyonu

### Amaç
`AVCaptureSession` üzerinden akan canlı kamera akışını keserek statik JPEG veya video buffer'ını "gerçek kamera frame'i" olarak uygulamaya sunar (replay-attack / liveness bypass).

### Hedeflenen Sistem Fonksiyonları / Metodlar

| Hedef | Tip | Neden Hedefleniyor |
|:------|:----|:-------------------|
| `AVCaptureSession -startRunning` | ObjC method | Gerçek kamera başlatmasını engeller / kontrol eder |
| `AVCaptureVideoDataOutput setSampleBufferDelegate:queue:` | ObjC method | Delegate pointer'ı yakalanır |
| `captureOutput:didOutputSampleBuffer:fromConnection:` | Delegate callback | Frame verisi bu method'a düşer — enjeksiyon noktası |
| `CMSampleBufferGetImageBuffer` | CoreMedia C func | `CVPixelBufferRef` alındığı nokta |
| `CVPixelBufferLockBaseAddress` | CoreVideo C func | Buffer bellek kilidi — manipülasyon öncesi gerekli |
| `VNDetectFaceRectanglesRequest` | Vision framework | ML tabanlı yüz tespiti — sahte frame gönderilir |

### Frame Enjeksiyonu Akışı

```
[1] setSampleBufferDelegate hook tetiklenir
      └── Delegate objesi & queue referansı saklanır

[2] didOutputSampleBuffer hook'u delegate üzerine eklenir
      └── Her gerçek kamera frame'i bu noktada yakalanır

[3] Gerçek CMSampleBuffer DROP edilir

[4] Python'dan RPC ile gönderilen JPEG yüklenir
      └── UIImage → CIImage → CVPixelBuffer dönüşümü

[5] Sahte CVPixelBuffer'dan yeni CMSampleBuffer oluşturulur

[6] Orijinal delegate callback'i SAHTE buffer ile çağrılır
      └── Uygulama "kameradan geldi" zannettiği sahte yüzü alır
```

### Giriş / Çıkış Parametreleri (Delegate Hook)

```js
// didOutputSampleBuffer enjeksiyonu
const delegateClass = ObjC.classes[capturedDelegateClassName];
const method = delegateClass['- captureOutput:didOutputSampleBuffer:fromConnection:'];

Interceptor.attach(method.implementation, {
  onEnter(args) {
    // args[0]: self (delegate objesi)
    // args[1]: SEL
    // args[2]: AVCaptureOutput* captureOutput
    // args[3]: CMSampleBufferRef sampleBuffer  ← enjeksiyon noktası
    // args[4]: AVCaptureConnection* connection
    
    const fakeSampleBuffer = buildFakeBuffer(injectPayloadPath);
    args[3] = fakeSampleBuffer;  // DROP & REPLACE
  }
});
```

### Platform Uyumluluk Notu (Compatibility Matrix'ten)

| iOS Sürümü | Frame Enjeksiyonu Başarı Oranı |
|:-----------|:-------------------------------|
| 14.x | %100 |
| 15.x | %98 |
| 16.x | %95 |
| 17.x | %90 |
| 18 (Beta) | %60 — `CVPixelBuffer` format değişikliği araştırılıyor |

---

## Ortak Yardımcılar

### `utils/safe_boot.js`
Tüm hook'larda kullanılan hata sarmalayıcı:

```js
function safeAttach(target, callbacks) {
  try {
    Interceptor.attach(target, callbacks);
  } catch (e) {
    send({ type: 'hook_error', target: target.toString(), error: e.message });
    // Process çökmez, hook atlanır
  }
}
```

### `utils/smart_mapper.py`
iOS sürümüne göre değişen method imzalarını ve offset'leri dinamik olarak çözer:

```python
def resolve_symbol(module: str, symbol: str, ios_version: tuple) -> int:
    """
    iOS 17+ bazı private API'lerin adı değişti.
    Smart Mapper, bilinen eşleme tablosundan doğru offset'i döndürür.
    """
```

---

*Bkz: [`ARCHITECTURE.md`](ARCHITECTURE.md) · [`API_SURFACE.md`](API_SURFACE.md) · [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md)*
