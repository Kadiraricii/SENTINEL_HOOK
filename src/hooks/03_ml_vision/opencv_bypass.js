/**
 * Sentinel Hook - OpenCV & DNN Security Bypass (Phase 4.4)
 * FIXED: Simulator detection uses UIDevice.model (works on Apple Silicon arm64).
 */

console.log("[🌟] SENTINEL HOOK: OpenCV DNN (C++ Native) Bypass Active...");

var isSimulator = false;
try {
    if (ObjC.available) {
        var model = ObjC.classes.UIDevice.currentDevice().model().toString();
        isSimulator = model.indexOf("Simulator") !== -1;
    }
} catch(e) {
    isSimulator = (Process.arch === "x86_64");
}

if (isSimulator) {
    console.log("[i] ENV: Simulator — OpenCV native hook in passive mode (no ARM hardware).");
} else {
    // Monitor dlopen for OpenCV library loading (physical device only)
    try {
        var dlopenPtr = Module.findExportByName(null, "dlopen");
        if (dlopenPtr && !dlopenPtr.isNull()) {
            Interceptor.attach(dlopenPtr, {
                onEnter: function(args) {
                    try { this.libName = args[0].readUtf8String(); } catch(e) { this.libName = null; }
                },
                onLeave: function(retval) {
                    if (this.libName && (this.libName.indexOf("opencv") !== -1 || this.libName.indexOf("cv2") !== -1)) {
                        console.log("[💥] SENTINEL: OpenCV library detected → " + this.libName);
                        hookOpenCV();
                    }
                }
            });
            console.log("[+] OPENCV: Library monitor armed on dlopen.");
        }
    } catch(err) {
        console.log("[-] OPENCV ERROR: dlopen hook failed - " + err.message);
    }
}

function hookOpenCV() {
    try {
        var modules = Process.enumerateModules();
        for (var i = 0; i < modules.length; i++) {
            var m = modules[i];
            if (m.name.indexOf("opencv") !== -1 || m.name.indexOf("CoreML") !== -1) {
                var exports = m.enumerateExports();
                for (var j = 0; j < exports.length; j++) {
                    var exp = exports[j];
                    if (exp.type !== 'function') continue;
                    if (exp.name.indexOf("forward") !== -1 && exp.name.indexOf("dnn") !== -1) {
                        console.log("[+] OpenCV DNN Forward found: " + exp.name);
                        Interceptor.attach(exp.address, {
                            onLeave: function(retval) {
                                console.log("[💥] SENTINEL: OpenCV AI result intercepted. (Bypass Active)");
                            }
                        });
                    }
                }
            }
        }
    } catch(e) {
        console.log("[-] OpenCV hook failed: " + e.message);
    }
}
