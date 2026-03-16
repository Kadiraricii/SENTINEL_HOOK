import SwiftUI
import LocalAuthentication
import Combine

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    // Uygulamanın entry point auth kontrol fonksiyonu (Frida ile hedef alacağımız fonksiyon bu!)
    func authenticateUser() {
        
        // --- PHASE 5: GÜVENLİK TESTİ (JAILBREAK TESPİT SİMÜLASYONU) ---
        // Uygulama açılırken cihazda Cydia var mı diye dosyaları kontrol eder.
        // Simülatörde Cydia yerine Mac'in '/Applications/Safari.app' klasörüne bakacağız.
        let jailbreakFilePath = "/Applications/Safari.app"
        var isJailbroken = false
        
        // C-Level stat veya FileManager araması...
        if FileManager.default.fileExists(atPath: jailbreakFilePath) {
            isJailbroken = true
        }
        
        if isJailbroken {
            // Eğer Safari (Cydia varsayıyoruz) varsa, uygulama kendini kilitler!
            self.errorMessage = "🚨 GÜVENLİK İHLALİ: Cihazınız Jailbreak'li! Giriş Engellendi."
            return
        }
        // -------------------------------------------------------------
        
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
