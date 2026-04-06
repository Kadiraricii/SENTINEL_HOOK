import SwiftUI
import LocalAuthentication
import Combine

class MFAAuthManager: ObservableObject {
    @Published var isBiometricPassed = false
    @Published var isFullyAuthenticated = false
    @Published var errorMessage: String?
    @Published var awaitingOTP = false
    
    private var currentExpectedOTP = "000000"
    
    // == AŞAMA 1: Biometric ==
    // Frida bu metodu hook'lar ve LAContext'i bypass eder.
    // Simülatörde donanım yoksa 0.5 sn sonra OTP ekranına yine de geçer
    // (gerçek cihazda Frida hook olmadan bu geçiş OLMAZ).
    @objc dynamic func initiateMFAChain() {
        errorMessage = nil
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Gerçek cihaz — Frida hook'u bu çağrıyı devralır
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "MFA Vault: Biometric signature required.") { [weak self] success, _ in
                DispatchQueue.main.async {
                    if success {
                        print("[MFA] STEP 1: Biometric ACCEPTED.")
                        self?.isBiometricPassed = true
                        self?.triggerOTPDelivery()
                    } else {
                        print("[MFA] STEP 1: Biometric REJECTED.")
                        self?.errorMessage = "Biometric failed. Chain aborted."
                    }
                }
            }
        } else {
            // Simülatör: donanım yok.
            // Gerçek senaryoda burada akış durur.
            // Demo için: Frida MFA hook aktifken canEvaluatePolicy'yi
            // YES olarak döndüreceğinden yukarıdaki branch çalışır.
            // Ama Frida yokken sana OTP ekranını yine de gösteriyoruz
            // ki "yanlış kodu reddet, enjeksiyonla geç" demosunu yapabilesin.
            print("[MFA] STEP 1 SKIPPED: No biometric HW (Simulator). Jumping to OTP gate...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.isBiometricPassed = false // Frida bunu true yapar
                self?.triggerOTPDelivery()
            }
        }
    }
    
    // == AŞAMA 2: OTP Tetikle ==
    private func triggerOTPDelivery() {
        // Rastgele 6 haneli OTP — doğrusu Xcode konsolunda görünür
        let otp = String(format: "%06d", Int.random(in: 100000...999999))
        self.currentExpectedOTP = otp
        self.awaitingOTP = true
        print("[MFA] OTP DISPATCHED → \(otp)")
        print("[MFA] Hint: Enter this exact code without injection, OR any code with Sentinel active.")
    }
    
    // == AŞAMA 3: OTP Doğrula ==
    // Frida bu metodun args[2]'sini "SENTINEL_OVERRIDE" ile değiştirir,
    // bu da aşağıdaki ikinci koşulu tetikler.
    @objc dynamic func verifyOTP(code: String) -> Bool {
        print("[MFA] STEP 2: Verifying code — '\(code)'")
        
        if code == currentExpectedOTP {
            // Doğru OTP girildi (enjeksiyon olmadan)
            DispatchQueue.main.async {
                self.isFullyAuthenticated = true
                self.awaitingOTP = false
                print("[MFA] STEP 2: Correct OTP. Access granted (no injection).")
            }
            return true
        } else if code == "SENTINEL_OVERRIDE" {
            // Frida'nın enjekte ettiği god-key
            DispatchQueue.main.async {
                self.isFullyAuthenticated = true
                self.awaitingOTP = false
                print("[MFA] STEP 2: SENTINEL_OVERRIDE detected. Frida bypass successful!")
            }
            return true
        } else {
            // Yanlış kod — REDDEDİLDİ
            DispatchQueue.main.async {
                self.errorMessage = "❌ Wrong code. (\(code)) — Inject MFA CHAIN to bypass."
                print("[MFA] STEP 2: REJECTED. Code '\(code)' is incorrect.")
            }
            return false
        }
    }
    
    func reset() {
        isBiometricPassed = false
        isFullyAuthenticated = false
        awaitingOTP = false
        errorMessage = nil
        currentExpectedOTP = "000000"
    }
}
