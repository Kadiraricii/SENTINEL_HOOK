/**
 * Sentinel Hook - Enterprise Biometric Bypass
 * Phase 2.1: Stealth LocalAuthentication Patch
 * FIXED: Simulator-safe. canEvaluatePolicy returns false on sim, so we hook
 *        the implementation directly and fire the reply block ourselves.
 */

if (ObjC.available) {
    console.log("[🌟] SENTINEL SUBSYSTEM: Initiating Biometric Hook (LAContext)");

    var LAContext = ObjC.classes.LAContext;

    // 1. canEvaluatePolicy hook — make it always return YES
    try {
        Interceptor.attach(LAContext["- canEvaluatePolicy:error:"].implementation, {
            onLeave: function (retval) {
                retval.replace(1);
                console.log("[+] AUTH_PRE_CHECK: Hardware validation spoofed → YES");
            }
        });
    } catch(err) {
        console.log("[-] WARNING: canEvaluatePolicy hook failed - " + err.message);
    }

    // 2. evaluatePolicy hook — fire success block immediately on enter
    try {
        Interceptor.attach(LAContext["- evaluatePolicy:localizedReason:reply:"].implementation, {
            onEnter: function (args) {
                console.log("[💥] SENTINEL TRIGGER: LAContext.evaluatePolicy intercepted");
                this.replyBlock = new ObjC.Block(args[4]);
                try {
                    this.replyBlock.implementation(1, null);
                    console.log("[✅] ACCESS GRANTED: Biometric fortress breached.");
                } catch (e) {
                    console.log("[-] EXEC ERROR: " + e.message);
                }
            }
        });
    } catch(err) {
        console.log("[-] WARNING: evaluatePolicy hook failed - " + err.message);
    }
} else {
    console.log("[-] FATAL: Objective-C Runtime unavailable.");
}
