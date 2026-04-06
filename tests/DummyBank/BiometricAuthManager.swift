import SwiftUI
import LocalAuthentication
import Combine

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    // Guard flag — prevents the retry loop from firing after success
    private var bypassAttemptInProgress = false
    
    func authenticateUser() {
        guard !bypassAttemptInProgress else { return }
        
        // Jailbreak simulation check (visible hook target for Frida)
        let jailbreakFilePath = "/Applications/Safari.app"
        if FileManager.default.fileExists(atPath: jailbreakFilePath) {
            self.errorMessage = "🚨 SECURITY: Jailbreak artifact detected."
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Real device or Frida has already hooked canEvaluatePolicy → YES
            let reason = "Secure Vault Access requires Biometric signature."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, _ in
                DispatchQueue.main.async {
                    self?.bypassAttemptInProgress = false
                    if success {
                        print("[LOCAL_AUTH] Biometric signature ACCEPTED.")
                        self?.isAuthenticated = true
                    } else {
                        print("[LOCAL_AUTH] Biometric signature REJECTED.")
                        self?.errorMessage = "Authentication sequence failed."
                    }
                }
            }
        } else {
            // SIMULATOR PATH: Frida hooks canEvaluatePolicy in the background.
            // We retry ONCE after a short delay to give the hook time to register.
            bypassAttemptInProgress = true
            print("[LOCAL_AUTH] Biometric HW unavailable — invoking evaluatePolicy as Frida target.")
            DispatchQueue.main.async {
                self.errorMessage = "⚡ AWAITING FRIDA SIGNAL: Inject 'BIO-LOGIC' to bypass."
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self else { return }
                let ctx2 = LAContext()
                var err2: NSError?
                if ctx2.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err2) {
                    let reason2 = "Secure Vault Access requires Biometric signature."
                    ctx2.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason2) { [weak self] success, _ in
                        DispatchQueue.main.async {
                            self?.bypassAttemptInProgress = false
                            if success {
                                print("[LOCAL_AUTH] FRIDA BYPASS: Authenticated!")
                                self?.isAuthenticated = true
                            } else {
                                self?.errorMessage = "Injection failed. Ensure BIO-LOGIC module is active."
                            }
                        }
                    }
                } else {
                    self.bypassAttemptInProgress = false
                    self.errorMessage = "No Frida signal received. Module not active."
                }
            }
        }
    }
}
