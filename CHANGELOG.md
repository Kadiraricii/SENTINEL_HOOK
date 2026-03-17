# 📦 Changelog

All notable changes to **Sentinel Hook** are documented here.
Format follows [Semantic Versioning](https://semver.org/) — `[Version] - YYYY-MM-DD`

---

## [1.0.0] - 2026-04-04

### 🎉 First Stable Release

**Added:**
- **Phase 2 — Biometric Logic Bypass:**
  - `01_biometrics/local_auth_bypass.js` → iOS `LocalAuthentication` framework hook
  - `01_biometrics/biometric_callback_hook.js` → Android `BiometricPrompt` callback breaker
  - `01_biometrics/crypto_object_bypass.js` → Android `CryptoObject` hardware key lock bypass

- **Phase 3 — Camera & Sensor Spoofing:**
  - `02_camera/camera_bypass.js` → iOS `AVCaptureSession` frame injection (hacker.jpg)
  - `02_camera/camerax_hook.js` → Android `CameraX/Camera2` ImageReader bypass
  - `02_camera/video_replayer.js` → 60 FPS fake video stream injection

- **Phase 4 — AI / ML Bypass:**
  - `03_ml_vision/vision_bypass.js` → Apple CoreML fake `VNFaceObservation` object injection
  - `03_ml_vision/mlkit_face_bypass.js` → Google MLKit face detection bypass
  - `03_ml_vision/face_embedding_bypass.js` → FaceNet embedding distance manipulation
  - `03_ml_vision/opencv_bypass.js` → Native C++ `cv::dnn::Net::forward` AI score manipulation

- **Phase 5 — Anti-Tamper / Stealth:**
  - `04_anti_tamper/root_jailbreak_bypass.js` → `NSFileManager` ObjC hook concealing Cydia/Sileo paths
  - `04_anti_tamper/ssl_pinning_bypass.js` → iOS `SecTrustEvaluate` + Android `TrustManagerImpl` bypass
  - `04_anti_tamper/frida_detection_bypass.js` → `/proc/self/maps` and ptrace anti-debug bypass
  - `04_anti_tamper/integrity_bypass.js` → APK signature + iOS `SecStaticCodeCheckValidity` bypass

- **DummyBank Test Lab:**
  - SwiftUI-based iOS simulator application added
  - Jailbreak detection simulation (Safari → Cydia proxy test) added
  - `CameraManager.swift` → Frida-hookable `simulateFrameTrigger` method added

- **Project Documentation:**
  - `README.md`, `ROADMAP.md`, `USAGE.md`, `DISCLAIMER.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `SECURITY.md` added
  - `requirements.txt` and `install.sh` one-command setup script added

- **Project Structure:**
  - `src/hooks/` reorganized into `01_biometrics` / `02_camera` / `03_ml_vision` / `04_anti_tamper`

**Fixed:**
- `camera_bypass.js` → `TypeError` resolved by switching from `ptr()` to `ObjC.classes` method access
- `root_jailbreak_bypass.js` → iOS Simulator `fopen/stat` nullptr resolved with `NSFileManager` ObjC hook
- `BiometricAuthManager.swift` → Missing `import Combine` added

---

## [0.3.0] - 2026-04-03
### Phase 4 (ML Bypass) complete
- Vision Framework and Google MLKit hooks written
- OpenCV native layer manipulation added

## [0.2.0] - 2026-04-03
### Phase 3 (Camera Spoofing) complete
- DummyBank app integrated with `AVCaptureSession`
- Static frame injection via Frida successfully tested

## [0.1.0] - 2026-04-03
### Phase 2 (Biometric Logic Bypass) complete
- iOS `LocalAuthentication` and Android `BiometricPrompt` hooks written
- Project skeleton and Frida infrastructure initialized
