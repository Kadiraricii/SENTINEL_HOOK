import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @StateObject private var cameraManager = CameraManager()
    @State private var showingCamera = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if authManager.isAuthenticated || cameraManager.isCameraAuthenticated {
                // BYPASS BAŞARILI EKRANI
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
                    
                    Button("Çıkış Yap") {
                        authManager.isAuthenticated = false
                        cameraManager.isCameraAuthenticated = false
                        showingCamera = false
                    }
                    .foregroundColor(.white)
                    .padding()
                }
            } else if showingCamera {
                // KAMERA LIVENESS (CANLILIK) EKRANI
                VStack {
                    Text("Liveness Yüz Taraması")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                    
                    if let frame = cameraManager.currentFrame {
                        Image(decorative: frame, scale: 1.0, orientation: .up)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 400)
                            .cornerRadius(20)
                            .padding()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 400)
                            .cornerRadius(20)
                            .overlay(Text("Kamera Başlatılıyor... / Simülatör").foregroundColor(.white))
                            .padding()
                    }
                    
                    if let err = cameraManager.errorMessage {
                        Text(err).foregroundColor(.red).font(.caption).padding()
                    }
                    
                    Button("Geri Dön") {
                        showingCamera = false
                    }
                    .padding()
                    .foregroundColor(.red)
                }
                
            } else {
                // ANA GİRİŞ EKRANI
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
                    
                    // 1. Standart Face ID Butonu
                    Button(action: {
                        authManager.authenticateUser()
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                                .font(.title2)
                            Text("Face ID (Logic) ile Giriş")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                        .padding(.horizontal, 40)
                    }
                    
                    // 2. Kamera Tabanlı Liveness Butonu (PHASE 3 HEDEFİ)
                    Button(action: {
                        showingCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .font(.title2)
                            Text("Canlı Kamera (Liveness) ile Giriş")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
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
