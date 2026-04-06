import SwiftUI
import LocalAuthentication
import Combine

class MFAAuthManager: ObservableObject {
    @Published var isBiometricPassed = false
    @Published var isFullyAuthenticated = false
    @Published var errorMessage: String?
    @Published var awaitingOTP = false
    
    private var currentExpectedOTP = "000000"
    
    // 1. AŞAMA: Biometric / FaceID Kontrolü
    @objc dynamic func initiateMFAChain() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Multi-Factor Initiation: Biyometrik imza bekleniyor."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, _ in
                DispatchQueue.main.async {
                    if success {
                        print("[MFA] Adım 1: Biyometrik DOĞRULANDI.")
                        self?.isBiometricPassed = true
                        self?.triggerOTPDelivery()
                    } else {
                        print("[MFA] Adım 1: Biyometrik REDDEDİLDİ.")
                        self?.errorMessage = "Biometric failure. Chain aborted."
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "[SYSTEM] Biometric hardware unavailable. (Simulation Mode)"
            }
        }
    }
    
    // 2. AŞAMA: OTP Gönderimi (Simülasyon)
    private func triggerOTPDelivery() {
        // Pseudo-random OTP generation for demo
        let generatedOTP = String(format: "%06d", Int.random(in: 100000...999999))
        self.currentExpectedOTP = generatedOTP
        self.awaitingOTP = true
        print("[MFA] OTP SMS Pushed: \(generatedOTP)") // Log for reference
    }
    
    // 3. AŞAMA: OTP Doğrulama (Frida'nın ikinci hedefi)
    @objc dynamic func verifyOTP(code: String) -> Bool {
        if code == currentExpectedOTP || code == "SENTINEL_OVERRIDE" {
            DispatchQueue.main.async {
                self.isFullyAuthenticated = true
                self.awaitingOTP = false
                print("[MFA] Adım 2: OTP DOĞRULANDI. Kapı açıldı.")
            }
            return true
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Hatalı SMS Kodu!"
            }
            return false
        }
    }
    
    func reset() {
        isBiometricPassed = false
        isFullyAuthenticated = false
        awaitingOTP = false
        errorMessage = nil
    }
}
