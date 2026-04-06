/**
 * Sentinel Hook - Enterprise AI Vision Bypass
 * FIXED: Calls sentinelVisionBypass() to update Swift state and trigger UI.
 */

if (ObjC.available) {
    console.log("[🌟] SENTINEL SUBSYSTEM: Initiating ML Vision Override");

    var VNDetectFaceRectanglesRequest = ObjC.classes.VNDetectFaceRectanglesRequest;
    var VNFaceObservation = ObjC.classes.VNFaceObservation;
    var NSArray = ObjC.classes.NSArray;
    var targetClassName = "_TtC9DummyBank13CameraManager";
    
    if (VNDetectFaceRectanglesRequest && VNFaceObservation) {
        console.log("[+] TARGET LOCKED: Vision Engine mapped. Patching arrays...");
        
        var cachedFakeResults = null;
        var lastLogTime = 0;

        try {
            Interceptor.attach(VNDetectFaceRectanglesRequest["- results"].implementation, {
                onLeave: function(retval) {
                    try {
                        if (!cachedFakeResults) {
                            var face = VNFaceObservation.alloc().init();
                            var array = NSArray.arrayWithObject_(face);
                            cachedFakeResults = array.retain();
                            face.retain();
                            console.log("[+] MEMORY PATCH: Allocated persistent synthetic observation.");
                        }
                        retval.replace(cachedFakeResults);

                        var now = Date.now();
                        if (now - lastLogTime > 4000) {
                            console.log("[💥] SENTINEL INTEL: ML Vision Engine successfully spoofed. (Trust established)");
                            lastLogTime = now;
                        }
                    } catch(e) {}
                }
            });
        } catch(err) {
            console.log("[-] FATAL: Vision hook failed - " + err.message);
        }
    }

    // KEY FIX: Call sentinelVisionBypass() to set isCameraAuthenticated → triggers COMPROMISED screen
    try {
        var AppCameraManager = ObjC.classes[targetClassName];
        if (AppCameraManager) {
            var instances = ObjC.chooseSync(AppCameraManager);
            if (instances.length > 0) {
                console.log("[💥] SENTINEL VISION: Calling sentinelVisionBypass() on live instance...");
                instances[0]["- sentinelVisionBypass"]();
                console.log("[✅] VISION GATE: aiFaceDetected + isCameraAuthenticated → TRUE. UI notified.");
            } else {
                // Hook startup to fire bypass when session starts
                Interceptor.attach(AppCameraManager["- startDummySessionForSimulator"].implementation, {
                    onEnter: function(args) {
                        new ObjC.Object(args[0])["- sentinelVisionBypass"]();
                        console.log("[✅] VISION GATE: bypass injected at session start.");
                    }
                });
            }
        }
    } catch(e) {
        console.log("[-] Vision bypass call failed: " + e.message);
    }
}
