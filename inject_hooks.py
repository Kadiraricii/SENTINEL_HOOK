#!/usr/bin/env python3
import os
import glob
import sys

# Sentinel Bundler - Power Loader Edition (Phase 7.0)
# Bu versiyon, JS hatalarını minimize etmek için "Safe-Execution" sarmalayıcısı ekler.

PROJECT_ROOT = "/Users/kadirarici/Desktop/Biometric Logic Bypass/Sentinel_Hook"
BUNDLE_PATH = os.path.join(PROJECT_ROOT, "_sentinel_bundle.js")

MODULES = {
    "biometrics": ["src/hooks/01_biometrics"],
    "camera": ["src/hooks/02_camera"],
    "vision": ["src/hooks/03_ml_vision"],
    "security": ["src/hooks/04_anti_tamper"],
    "mfachain": ["src/hooks/05_mfa"],
    "deepfake": ["src/hooks/advanced"],
    "kernelcam": ["src/hooks/advanced"],
    "all": [
        "src/hooks/01_biometrics",
        "src/hooks/02_camera",
        "src/hooks/03_ml_vision",
        "src/hooks/04_anti_tamper",
        "src/hooks/05_mfa",
        "src/hooks/advanced"
    ]
}

def bundle():
    requested_module = sys.argv[1] if len(sys.argv) > 1 else "all"
    target_dirs = MODULES.get(requested_module, MODULES["all"])
    
    count = 0
    with open(BUNDLE_PATH, "w") as out:
        out.write(f"// SENTINEL POWER-BUNDLE: {requested_module.upper()}\n\n")
        
        # Global Safe Loader
        out.write("""
var SentinelLoader = {
    safeRun: function(name, func) {
        try {
            console.log('[*] ' + name + ' yüklendi.');
            func();
        } catch(e) {
            console.log('[!] ' + name + ' HATA: ' + e.message);
        }
    }
};

// SENTINEL HEARTBEAT - Stay Alive Anchor
setInterval(function() {
    // This empty interval keeps the Frida event loop from closing
    // while we wait for tactical triggers.
}, 1000);
\n""")

        for d in target_dirs:
            path = os.path.join(PROJECT_ROOT, d)
            if not os.path.exists(path): continue
            
            for js in sorted(glob.glob(os.path.join(path, "*.js"))):
                with open(js, "r") as f:
                    content = f.read()
                
                if "Java.perform" in content or "Java.use" in content:
                    continue
                
                count += 1
                name = os.path.basename(js)
                out.write(f"SentinelLoader.safeRun('{name}', function() {{\n")
                out.write(content)
                out.write(f"\n}});\n\n")
                
    return BUNDLE_PATH

if __name__ == "__main__":
    bundle()
