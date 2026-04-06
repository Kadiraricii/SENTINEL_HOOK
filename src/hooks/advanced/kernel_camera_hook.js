/**
 * Sentinel Hook - Phase 10.3: Kernel-Level Camera Interception
 * FIXED: Calls sentinelKernelBypass() to update Swift state → triggers COMPROMISED screen.
 */

if (ObjC.available) {
    console.log("[🌟] SENTINEL PHASE 10.3: Kernel-Level Camera Hook Initiating...");
    
    var isSimulator = false;
    try {
        var model = ObjC.classes.UIDevice.currentDevice().model().toString();
        isSimulator = model.indexOf("Simulator") !== -1;
    } catch(e) { isSimulator = (Process.arch === "x86_64"); }
    
    var frameCount = 0;
    var targetClassName = "_TtC9DummyBank13CameraManager";

    // == LAYER 1: IOSurface ==
    try {
        var IOSurface = ObjC.classes.IOSurface;
        if (IOSurface && IOSurface["+ surfaceWithProperties:"]) {
            Interceptor.attach(IOSurface["+ surfaceWithProperties:"].implementation, {
                onLeave: function(retval) {
                    if (!retval.isNull()) {
                        frameCount++;
                        if (frameCount % 5 === 0) {
                            console.log("[💥] KERNEL L1: IOSurface @ 0x" + retval.toString(16));
                            console.log("[FRAME:IOSURFACE:" + Date.now() + ":INTERCEPTED]");
                        }
                    }
                }
            });
            console.log("[+] KERNEL LAYER 1: IOSurface hooked.");
        }
    } catch(err) {
        console.log("[i] KERNEL L1: IOSurface skipped - " + err.message);
    }

    // == LAYER 2: CMSampleBuffer (C) / AVCaptureSession (ObjC fallback) ==
    var l2Hooked = false;
    var cmSymbols = ["CMSampleBufferCreateReadyWithImageBuffer", "CMSampleBufferCreate", "CMSampleBufferGetImageBuffer"];
    for (var s = 0; s < cmSymbols.length; s++) {
        try {
            var ptr = Module.findExportByName("CoreMedia", cmSymbols[s]);
            if (ptr && !ptr.isNull()) {
                (function(sym) {
                    Interceptor.attach(ptr, {
                        onEnter: function() {
                            frameCount++;
                            if (frameCount % 10 === 0) {
                                console.log("[💥] KERNEL L2: " + sym + " — frame #" + frameCount);
                                console.log("[FRAME:SAMPLEBUFFER:" + Date.now() + ":TAGGED]");
                            }
                        }
                    });
                })(cmSymbols[s]);
                console.log("[+] KERNEL LAYER 2: " + cmSymbols[s] + " hooked.");
                l2Hooked = true;
                break;
            }
        } catch(e) {}
    }
    if (!l2Hooked) {
        try {
            var AVCapture = ObjC.classes.AVCaptureSession;
            if (AVCapture && AVCapture["- startRunning"]) {
                Interceptor.attach(AVCapture["- startRunning"].implementation, {
                    onEnter: function() {
                        console.log("[💥] KERNEL L2 (SIM): AVCaptureSession boundary intercepted.");
                        console.log("[FRAME:AVCAPTURE:" + Date.now() + ":ACTIVE]");
                    }
                });
                console.log("[+] KERNEL LAYER 2 (Sim): AVCaptureSession hooked.");
                l2Hooked = true;
            }
        } catch(e) {}
    }

    // == LAYER 3: VTCompressionSession / CVPixelBuffer fallback ==
    var l3Hooked = false;
    try {
        var vtPtr = Module.findExportByName("VideoToolbox", "VTCompressionSessionEncodeFrame");
        if (vtPtr && !vtPtr.isNull()) {
            Interceptor.attach(vtPtr, {
                onEnter: function() {
                    console.log("[🔥] KERNEL L3: VTCompressionSession encode intercepted.");
                    console.log("[FRAME:VTCOMPRESSION:" + Date.now() + ":ENCODED]");
                }
            });
            console.log("[+] KERNEL LAYER 3: VTCompressionSession hooked.");
            l3Hooked = true;
        }
    } catch(e) {}
    
    if (!l3Hooked) {
        try {
            var cvPtr = Module.findExportByName("CoreVideo", "CVPixelBufferLockBaseAddress");
            if (cvPtr && !cvPtr.isNull()) {
                var cvThrottle = 0;
                Interceptor.attach(cvPtr, {
                    onEnter: function() {
                        cvThrottle++;
                        if (cvThrottle % 15 === 0) {
                            console.log("[🔥] KERNEL L3 (SIM): CVPixelBuffer lock — frame #" + cvThrottle);
                            console.log("[FRAME:CVPIXELBUFFER:" + Date.now() + ":LOCKED]");
                        }
                    }
                });
                console.log("[+] KERNEL LAYER 3 (Sim): CVPixelBufferLockBaseAddress hooked.");
                l3Hooked = true;
            }
        } catch(e) {}
    }

    // KEY FIX: Call sentinelKernelBypass() to update Swift state → triggers COMPROMISED screen
    try {
        var AppCameraManager = ObjC.classes[targetClassName];
        if (AppCameraManager) {
            var instances = ObjC.chooseSync(AppCameraManager);
            if (instances.length > 0) {
                console.log("[💥] KERNEL BYPASS: Calling sentinelKernelBypass() on live instance...");
                instances[0]["- sentinelKernelBypass"]();
                console.log("[✅] KERNEL GATE: isCameraAuthenticated → TRUE. UI notified.");
            } else {
                Interceptor.attach(AppCameraManager["- startDummySessionForSimulator"].implementation, {
                    onEnter: function(args) {
                        new ObjC.Object(args[0])["- sentinelKernelBypass"]();
                        console.log("[✅] KERNEL GATE: bypass injected at session start.");
                    }
                });
            }
        }
    } catch(e) {
        console.log("[-] Kernel bypass call failed: " + e.message);
    }

    // Heartbeat for Live Feed panel
    setInterval(function() {
        console.log("[FRAME:KERNEL_HEARTBEAT:" + Date.now() + ":ACTIVE]");
    }, 1500);

    console.log("[✅] PHASE 10.3: Kernel pipeline instrumented.");
    console.log("    -> L1: IOSurface | L2: " + (l2Hooked ? "ACTIVE" : "PASSIVE") + " | L3: " + (l3Hooked ? "ACTIVE" : "PASSIVE"));

} else {
    console.log("[-] FATAL: ObjC Runtime unavailable.");
}
