# 🗺️ Sentinel Hook — Development Roadmap

> This document outlines the development phases of Sentinel Hook and its goals in security research.
> 🟢 Completed · 🟡 In Progress · ⚪️ Planned

---

## 🟢 PHASE 0: Architecture & Foundation
- **Goal:** Establish the Frida + Python infrastructure and define the directory hierarchy.
- **Status:** Complete.
- **Actions:** Repository initialized, `src/recon` modules scaffolded, C/Swift compatibility layer tested.

## 🟢 PHASE 1: Target Reconnaissance
- **Goal:** Identify biometric call surfaces in banking applications.
- **Status:** Complete.
- **Actions:** `Info.plist` (iOS) and `Manifest.xml` (Android) permissions audited. ObjC Runtime dump scripts (`class_dumper.js`) written.

## 🟢 PHASE 2: Logical Biometric Bypass
- **Goal:** Force a `true` boolean response for face or fingerprint authentication callbacks.
- **Status:** Complete.
- **Actions:** `LocalAuthentication` (Apple) and `BiometricPrompt` (Google) callback hooks implemented. Hardware-bound `CryptoObject` key lock broken.

## 🟢 PHASE 3: Camera & Sensor Spoofing
- **Goal:** Intercept live camera frames and inject a static image or pre-recorded video.
- **Status:** Complete.
- **Actions:** `AVCaptureSession` (iOS) and `CameraX` (Android) in-memory `CVPixelBuffer` / `ImageReader` swaps implemented. Fake face images and 60 FPS video sequences (`video_replayer.js`) successfully injected.

## 🟢 PHASE 4: AI & Machine Learning Muting
- **Goal:** Receive a "Live Human Face" approval even with a completely dark / empty camera frame.
- **Status:** Complete.
- **Actions:** Apple CoreML (`Vision`) and Google `MLKit` C++ layers deceived. Zero probability outputs overridden to `0.99 (Success)`. OpenCV `cv::dnn` modules also patched.

## 🟢 PHASE 5: Stealth & Anti-Tamper Evasion
- **Goal:** Conceal the Sentinel Hook agent and mask all device compromise indicators.
- **Status:** Complete.
- **Actions:**
  - Root/Jailbreak detection bypassed via `NSFileManager` and C-level `fopen/stat` hooks returning `ENOENT`.
  - SSL Pinning neutralized via `TrustManager` and `SecTrustEvaluate` patches.
  - Anti-Frida detection bypassed by suppressing `/proc/self/maps` anomaly reads.
  - Application integrity checks (APK signature / `SecStaticCodeCheckValidity`) defeated.

---

## 🟡 PHASE 6: Automation, CLI & Dashboard
- **Goal:** Build a command center to orchestrate the full bypass stack efficiently.
- **Status:** In Progress.
- **Planned Actions:**
  - ArgParse-based CLI via `launcher.py` with target selection and module flags.
  - `--bypass ALL` flag to inject every module in correct order in one command.
  - (Optional) Lightweight FastAPI / Flask web dashboard for session management.

---

## ⚪️ PHASE 7: Advanced Kernel Evasion *(Future Vision)*
- **Goal:** Kernel-level rootkit integration for next-generation mobile threat research.
- **Status:** Planned.
- **Planned Actions:**
  - ARM64e hardware-level PAC (Pointer Authentication Code) bypass.
  - eBPF-based Android network and filesystem detection evasion.
