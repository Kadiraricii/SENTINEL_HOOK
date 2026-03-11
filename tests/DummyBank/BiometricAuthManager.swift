import SwiftUI
import LocalAuthentication

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    // Uygulamanın entry point auth kontrol fonksiyonu (Frida ile hedef alacağımız fonksiyon bu!)
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        // Cihazda Face ID / Touch ID donanımı var mı ve ayarlı mı diye kontrol et
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            let reason = "Güvenli bölgeye girmek için yüzünüzü okutun."
            
            // İşte hooklanacak ana API! evaluatePolicy
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Eğer Frida bunu tetiklerse, parolasız giriş sağlanır!
                        print("[LOCAL_AUTH] Biyometrik doğrulama BAŞARILI.")
                        self?.isAuthenticated = true
                    } else {
                        print("[LOCAL_AUTH] Biyometrik doğrulama BAŞARISIZ.")
                        self?.errorMessage = "Doğrulama başarısız oldu."
                    }
                }
            }
        } else {
            // Emülatörde donanım yoksa fallback
            DispatchQueue.main.async {
                self.errorMessage = "Cihazda biyometrik güvenlik bulunamadı."
            }
        }
    }
}
