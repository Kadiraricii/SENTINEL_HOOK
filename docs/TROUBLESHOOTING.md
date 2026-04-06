# 🔧 Sentinel Hook — Troubleshooting Guide

> **Scope:** Frida connection issues, hook errors, platform-specific problems  
> **Frida Version:** 16.2.x  
> **Format:** Error → Root Cause → Solution

---

## Quick Diagnostic Command

```bash
# Check the environment status with a single command
source .venv/bin/activate && frida --version && frida-ls-devices
```

---

## Category 1: Connection & Session Errors

### ❌ `RPCException: unable to handle message`

**Symptom:** After a Python call to `script.exports.init()`, an `RPCException` is thrown.

**Root Causes:**

1. Python attempts to make a call before the `rpc.exports` object on the JS side is fully loaded.
2. Syntax error inside `sentinel_loader.js`, script failed to load.
3. Frida version is incompatible with the `frida-compile` output.

**Solution:**

```python
# ❌ Incorrect: making a call immediately while loading the script
script = session.create_script(source)
script.load()
result = script.exports.init(config)  # Not ready yet!

# ✅ Correct: wait for the ready signal with an on_message callback
def on_message(message, data):
    if message['type'] == 'send' and message['payload'] == 'ready':
        script.exports.init(config)

script.on('message', on_message)
script.load()
```

---

### ❌ `PermissionDenied: unable to attach`

**Symptom:** Permission error during `frida.attach(pid)`.

**Root Causes:**

| Condition | Explanation |
|:------|:---------|
| `frida-server` is not running | `frida-server` was not started on the device |
| Wrong architecture | `arm64` binary is used on an `arm64e` device |
| SIP active (Mac host) | macOS System Integrity Protection blocks Frida |
| No USB connection | `frida-ls-devices` does not list the device |

**Solution:**

```bash
# 1. Start frida-server correctly on the device (requires jailbroken device)
ssh root@<device-ip>
/usr/sbin/frida-server &

# 2. Verify architecture
frida-ls-devices
# Output should display: iPhone (id: ...)

# 3. Test connection
frida -U -n SpringBoard
# If successful, a REPL opens
```

---

### ❌ `Failed to spawn: unable to find process with name`

**Symptom:** `frida.spawn()` or `frida.attach()` cannot find the application.

**Solution:**

```bash
# Fetch the running process list
frida-ps -Ua   # USB connected device, installed applications

# Find the correct Bundle ID
frida-ps -Uai | grep -i "banking"

# Spawn via Bundle ID
frida -U -f com.example.bankapp --no-pause
```

---

## Category 2: Hook Execution Errors

### ❌ `TypeError: not a function` (ObjC method hook)

**Symptom:** `ObjC.classes.SomeClass['- methodName']` returns undefined or cannot be called.

**Root Causes:**

1. The method name is incorrect — the class does not implement this method.
2. The method is lazy-loaded; the class is not in memory yet.
3. Swift obfuscation — the method is exported with a mangled name like `_$S...`.

**Solution:**

```js
// 1. Verify if the class actually contains that method
const cls = ObjC.classes.LAContext;
console.log(cls.$ownMethods.join('\n'));  // List all methods

// 2. Use ObjC.schedule for a lazy class
ObjC.schedule(ObjC.mainQueue, function() {
  const target = ObjC.classes.LAContext['- evaluatePolicy:localizedReason:reply:'];
  if (target) Interceptor.attach(target.implementation, { ... });
});

// 3. Scan exports for the Swift mangled name
const mod = Process.getModuleByName('TargetApp');
mod.enumerateExports().filter(e => e.name.includes('evaluatePolicy'));
```

---

### ❌ `Error: access violation reading 0x...` (Native hook crash)

**Symptom:** Native hooks like `stat64` or `access` crash the application.

**Root Cause:** Inside `onEnter`, attempting a null pointer read via `args[0].readUtf8String()`.

**Solution — Safe Boot wrapper:**

```js
// ❌ Incorrect: direct read
onEnter(args) {
  this.path = args[0].readUtf8String();  // Crash if NULL!
}

// ✅ Correct: null guard
onEnter(args) {
  try {
    this.path = args[0].isNull() ? '' : args[0].readUtf8String();
  } catch (e) {
    this.path = '';
    send({ type: 'warning', msg: 'stat64 null path', error: e.message });
  }
}
```

---

### ❌ `Error: Module 'Security' not found`

**Symptom:** `Module.findExportByName('Security', 'SecItemCopyMatching')` returns null.

**Solution:**

```js
// Use the exact dylib path instead of the Framework name
const SEC = Module.findExportByName(
  '/System/Library/Frameworks/Security.framework/Security',
  'SecItemCopyMatching'
);

// Alternative: scan across all modules
const sym = Process.findExportByName('SecItemCopyMatching');
```

---

## Category 3: Camera / Frame Injection Errors

### ❌ `CVReturn error: -6680` (kCVReturnInvalidArgument)

**Symptom:** `CVPixelBufferCreate` returns an error code when creating a fake buffer.

**Root Cause:** The Pixel format or dimensions don't match the target application's expectations.

**Solution:**

```js
// Retrieve the format and dimensions of the original buffer, use them for the new buffer
const origBuf = CMSampleBufferGetImageBuffer(realSampleBuffer);
const width  = CVPixelBufferGetWidth(origBuf);
const height = CVPixelBufferGetHeight(origBuf);
const fmt    = CVPixelBufferGetPixelFormatType(origBuf);  // Usually 875704438 = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange

// Create fake buffer with matched parameters
CVPixelBufferCreate(kCFAllocatorDefault, width, height, fmt, null, fakeBufferRef);
```

---

### ❌ Camera Screen Freezes / Appears Black

**Symptom:** After frame injection, the app's camera preview gets stuck or blackened.

**Root Cause:** The `presentationTimeStamp` and `duration` values in `CMSampleBufferRef` are either missing or incorrect.

**Solution:**

```js
// Copy the original timestamp over to the fake buffer
const origTimestamp = CMSampleBufferGetPresentationTimeStamp(realSampleBuffer);
// Use this timestamp when creating the fake buffer
CMSampleBufferCreateForImageBuffer(
  allocator, fakePixelBuffer,
  true, null, null,
  formatDescription,
  origTimestamp,  // ← Use real timestamp here
  origTimestamp,
  fakeBufferRef
);
```

---

## Category 4: Environment & Setup Issues

### ❌ `frida-compile: command not found`

```bash
# Execute via npx
npx frida-compile src/hooks/ios/cloak.js -o dist/cloak.js

# Or reinstall if missing
npm install --save-dev frida-compile
```

---

### ❌ `ImportError: No module named 'frida'`

```bash
# Is the virtual environment active?
which python  # Should point to .venv/bin/python

# If not, activate it
source .venv/bin/activate
pip install frida==16.2.1 frida-tools==16.2.1
```

---

### ❌ Frida port 27042 is already in use

```bash
# Kill any lingering frida-server processes
pkill -9 frida-server
lsof -i :27042  # Verify port release
```

---

## General Diagnostic Tools

| Tool | Command | Purpose |
|:-----|:------|:-------------|
| Device List | `frida-ls-devices` | Shows all connected devices |
| Process List | `frida-ps -Ua` | Lists Application PIDs & Bundle IDs |
| Live REPL | `frida -U -n AppName` | Interactive JS execution shell |
| Trace Mode | `frida-trace -U -n AppName -m "LAContext"` | Automatically logs method calls |
| Objection | `objection -g AppName explore` | High-level interactive security bypass suite |

---

*See: [`ARCHITECTURE.md`](ARCHITECTURE.md) · [`HOOK_REFERENCE.md`](HOOK_REFERENCE.md) · [`QUICKSTART.md`](QUICKSTART.md)*

## Known Issues & Simulation Logs

### 1. Sysctl / Open Hook Error (Simulator Environments)
```
[-] Sysctl hook could not be installed: not a function
[-] Open hook could not be installed: not a function
```
**Explanation:** This error occurs when the Anti-Tamper/Jailbreak bypass modules (Anti-Detection Shield) are executed in a computer environment (iOS / Android Simulator). The related C++ memory directories (`/proc/sysctl` or `open()` syscalls) belong directly to ARM-architecture mobile device kernels. Because the test is not performed on a physical iPhone or Android device, Sentinel Hook throws these errors. However, it continues to bypass vulnerabilities (Biometric/Deepfake) in the simulator without completely interrupting the process.

### 2. Session Closed (Nuclear Purge)
```
[SYSTEM] Module 'deepfake' session closed. (Exit: Ok(ExitStatus(unix_wait_status(9))))
[SYSTEM] NUCLEAR PURGE: All hooks detached.
```
**Explanation:** When the "PURGE SESSIONS" button is clicked after Biometric, Liveness, or Injector operations are finished, the Rust backend service immediately destroys the RAM-based interventions made to the system (using SIGKILL 9). This is not an error; it is the state of Sentinel silently exiting memory (Stealth Mode) following a successful penetration operation.
