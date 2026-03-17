<div align="center">

```
███████╗███████╗███╗   ██╗████████╗██╗███╗   ██╗███████╗██╗          
██╔════╝██╔════╝████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝██║          
███████╗█████╗  ██╔██╗ ██║   ██║   ██║██╔██╗ ██║█████╗  ██║          
╚════██║██╔══╝  ██║╚██╗██║   ██║   ██║██║╚██╗██║██╔══╝  ██║          
███████║███████╗██║ ╚████║   ██║   ██║██║ ╚████║███████╗███████╗     
╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝    
                       H O O K                                         
```

<h3>Advanced Dynamic Instrumentation Framework</h3>
<h4>Biometric · Liveness · AI/ML Security Research</h4>

---

[![Stars](https://img.shields.io/github/stars/Kadiraricii/Sentinel_Hook?style=for-the-badge&color=FFD700&logo=github&logoColor=white)](https://github.com/Kadiraricii/Sentinel_Hook/stargazers)
[![Forks](https://img.shields.io/github/forks/Kadiraricii/Sentinel_Hook?style=for-the-badge&color=00C9FF&logo=github&logoColor=white)](https://github.com/Kadiraricii/Sentinel_Hook/network/members)
[![Issues](https://img.shields.io/github/issues/Kadiraricii/Sentinel_Hook?style=for-the-badge&color=FF6B6B&logo=github&logoColor=white)](https://github.com/Kadiraricii/Sentinel_Hook/issues)
[![License](https://img.shields.io/badge/License-Educational%20Only-8A2BE2?style=for-the-badge&logo=bookstack&logoColor=white)](./DISCLAIMER.md)

[![Frida](https://img.shields.io/badge/Frida-17.9.1-00C9FF?style=for-the-badge&logo=python&logoColor=white)](https://frida.re)
[![iOS](https://img.shields.io/badge/iOS-16%2B-black?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com)
[![Android](https://img.shields.io/badge/Android-11%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)

[![Visitors](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FKadiraricii%2FSentinel_Hook&count_bg=%23FF6B6B&title_bg=%23282C34&icon=github.svg&icon_color=%23E7E7E7&title=Visitors&edge_flat=false)](https://github.com/Kadiraricii/Sentinel_Hook)

</div>

---

## 🎯 What is Sentinel Hook?

**Sentinel Hook** is an advanced **Dynamic Instrumentation Framework** built on top of [Frida](https://frida.re) for security research on iOS and Android.

It targets the security layers of high-assurance applications (Banking, Crypto Wallets, Enterprise Auth) and dismantles their protection across **4 distinct layers** simultaneously:

```
┌─────────────────────────────────────────────────────────────────┐
│                      SENTINEL HOOK                              │
│                                                                 │
│  [01]  BiometricPrompt / LocalAuthentication  →  TRUE inject   │
│  [02]  AVCaptureSession / CameraX             →  Frame spoof   │
│  [03]  CoreML / Vision / MLKit                →  AI blind      │
│  [04]  Jailbreak / SSL / Frida Detection      →  Stealth       │
└─────────────────────────────────────────────────────────────────┘
```

---

## ⚡ Feature Matrix

| Module | Platform | Approach | Status |
|:-------|:---------|:---------|:------:|
| **Biometric Logic Bypass** | iOS · Android | `evaluatePolicy` / `BiometricPrompt.AuthCallback` hook | ✅ |
| **Camera Frame Injection** | iOS · Android | `CVPixelBuffer` / `Image.Plane` in-memory swap | ✅ |
| **CoreML / Vision Bypass** | iOS | Fake `VNFaceObservation` object injection | ✅ |
| **Google MLKit Bypass** | Android | `FaceDetector` return value interception | ✅ |
| **OpenCV DNN Bypass** | iOS · Android | Native `cv::dnn::Net::forward` C++ hook | ✅ |
| **Root / Jailbreak Evasion** | iOS · Android | `NSFileManager` + `stat` / `fopen` → ENOENT response | ✅ |
| **SSL Pinning Bypass** | iOS · Android | `SecTrustEvaluate` + `TrustManagerImpl` patch | ✅ |
| **Frida Presence Hiding** | iOS · Android | `/proc/self/maps` + port scan anomaly suppression | ✅ |
| **Integrity Check Bypass** | iOS · Android | `SecStaticCodeCheckValidity` + APK signature spoof | ✅ |

---

## 📂 Project Structure

```
Sentinel_Hook/
│
├── 📁 src/hooks/
│   ├── 📁 01_biometrics/       ←  FaceID, TouchID, BiometricPrompt breakers
│   │   ├── local_auth_bypass.js
│   │   ├── biometric_callback_hook.js
│   │   └── crypto_object_bypass.js
│   │
│   ├── 📁 02_camera/           ←  Camera sensor manipulation
│   │   ├── camera_bypass.js
│   │   ├── camerax_hook.js
│   │   └── video_replayer.js
│   │
│   ├── 📁 03_ml_vision/        ←  AI / ML blindspot injection
│   │   ├── vision_bypass.js
│   │   ├── mlkit_face_bypass.js
│   │   └── face_embedding_bypass.js
│   │
│   └── 📁 04_anti_tamper/      ←  Stealth layer
│       ├── root_jailbreak_bypass.js
│       ├── ssl_pinning_bypass.js
│       ├── frida_detection_bypass.js
│       └── integrity_bypass.js
│
├── 📁 tests/DummyBank/          ←  SwiftUI test lab application
├── 📁 src/recon/                ←  Memory mapping & static analysis scripts
├── 📄 README.md
├── 📄 USAGE.md                  ←  Detailed usage guide
├── 📄 ROADMAP.md
├── 📄 CONTRIBUTING.md
├── 📄 CHANGELOG.md
├── 📄 SECURITY.md
├── 📄 DISCLAIMER.md
├── 📄 requirements.txt
└── ⚙️  install.sh               ←  One-command setup
```

---

## 🚀 Quick Start

### 1. Install (One Command)
```bash
git clone https://github.com/Kadiraricii/Sentinel_Hook.git
cd Sentinel_Hook
bash install.sh
```

### 2. Identify Your Target
```bash
source .venv/bin/activate
frida-ps -Uai        # List all apps on connected device
```

### 3. Fire a Bypass
```bash
# Single module
frida -U -n DummyBank -l src/hooks/01_biometrics/local_auth_bypass.js

# All-in-one (full bypass stack)
frida -U -n DummyBank \
    -l src/hooks/04_anti_tamper/root_jailbreak_bypass.js \
    -l src/hooks/02_camera/camera_bypass.js \
    -l src/hooks/03_ml_vision/vision_bypass.js
```

> 📖 For detailed test scenarios see **[USAGE.md](./USAGE.md)**

---

## 🗺️ Roadmap

| Phase | Scope | Status |
|:------|:------|:------:|
| Phase 2 | Biometric Logic Bypass | 🟢 Complete |
| Phase 3 | Camera & Sensor Spoofing | 🟢 Complete |
| Phase 4 | AI / ML Liveness Bypass | 🟢 Complete |
| Phase 5 | Anti-Tamper & Stealth | 🟢 Complete |
| Phase 6 | CLI Automation & Dashboard | 🟡 In Progress |
| Phase 7 | Kernel-Level Evasion (ARM64e) | ⚪️ Planned |

---

## ⚖️ Legal Notice

> This project is intended **solely for educational and security research** purposes (Red Teaming, Penetration Testing). Using it against unauthorized systems is illegal. See **[DISCLAIMER.md](./DISCLAIMER.md)** for full terms.

---

<div align="center">

**Understand security. Build something better.**

[![GitHub](https://img.shields.io/badge/github-Kadiraricii-181717?style=for-the-badge&logo=github)](https://github.com/Kadiraricii)

</div>
