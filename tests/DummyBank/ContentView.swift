import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = BiometricAuthManager()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if authManager.isAuthenticated {
                // BYPASS BAŞARILI EKRANI (Sentinel Hook'un Ulaşmak İstediği Hedef)
                VStack(spacing: 20) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Hoş Geldiniz!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Gizli Kasaya başarıyla giriş yaptınız.")
                        .foregroundColor(.gray)
                    
                    Text("GİZLİ VERİ: HESAP_BAKİYESİ_$1.000.000")
                        .font(.caption)
                        .padding()
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.green)
                }
            } else {
                // NORMAL GİRİŞ EKRANI
                VStack(spacing: 30) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("DummyBank Pro")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let error = authManager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        authManager.authenticateUser()
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                                .font(.title2)
                            Text("Face ID ile Giriş Yap")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                        .padding(.horizontal, 40)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
