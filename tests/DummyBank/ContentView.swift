import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @StateObject private var cameraManager = CameraManager()
    @State private var showingCamera = false
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()
            
            if authManager.isAuthenticated || cameraManager.isCameraAuthenticated {
                // BYPASS BAŞARILI EKRANI (HACKED)
                VStack(spacing: 20) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .shadow(color: .green, radius: 10, x: 0, y: 0)
                    
                    Text("SYSTEM COMPROMISED")
                        .font(.custom("Courier", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("Welcome, Unauthorized User.")
                        .foregroundColor(.gray)
                    
                    Text("GİZLİ VERİ: HESAP_BAKİYESİ_$1.000.000")
                        .font(.caption)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green, lineWidth: 1))
                        .foregroundColor(.green)
                    
                    Button("PULL THE PLUG (Reset)") {
                        authManager.isAuthenticated = false
                        cameraManager.isCameraAuthenticated = false
                        showingCamera = false
                        authManager.errorMessage = nil
                        cameraManager.errorMessage = nil
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                }
            } else if showingCamera {
                // KAMERA LIVENESS (CANLILIK) EKRANI
                VStack {
                    HStack {
                         Text("Live Sensor Feed")
                             .font(.custom("Courier", size: 18))
                             .foregroundColor(.green)
                         Spacer()
                         Circle().fill(Color.red).frame(width: 10, height: 10)
                    }
                    .padding()
                    
                    ZStack {
                        if let frame = cameraManager.currentFrame {
                            Image(decorative: frame, scale: 1.0, orientation: .up)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 350)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.5), lineWidth: 2))
                                .padding()
                        } else {
                            Rectangle()
                                .fill(Color.black)
                                .frame(height: 350)
                                .border(Color.green.opacity(0.3), width: 2)
                                .overlay(
                                     VStack {
                                         Image(systemName: "viewfinder")
                                             .font(.system(size: 50))
                                             .foregroundColor(.green.opacity(0.5))
                                         Text("AWAITING INJECTION...")
                                             .font(.custom("Courier", size: 14))
                                             .foregroundColor(.green.opacity(0.8))
                                             .padding(.top)
                                     }
                                )
                                .padding()
                        }
                        
                        // Tarama Efekti
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.clear, .green.opacity(0.3), .clear]), startPoint: .top, endPoint: .bottom))
                            .frame(height: 20)
                            .offset(y: -150) // Animasyon eklenebilir
                    }
                    
                    if let err = cameraManager.errorMessage {
                        Text(err).foregroundColor(.orange).font(.custom("Courier", size: 12)).padding().multilineTextAlignment(.center)
                    }
                    
                    Button("ABORT SENSOR LINK") {
                        showingCamera = false
                        cameraManager.errorMessage = nil
                    }
                    .font(.custom("Courier", size: 14))
                    .padding()
                    .foregroundColor(.red)
                }
                
            } else {
                // ANA GİRİŞ EKRANI - 5 TARGET PANELİ
                ScrollView {
                    VStack(spacing: 25) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 40)
                        
                        Text("DummyBank Enterprise SECURE")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let error = authManager.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.custom("Courier", size: 14))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(5)
                        }
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("TARGET: LocalAuthentication (LAContext)")
                                .font(.caption).foregroundColor(.gray)
                            
                            // TARGET 1: Biometric
                            Button(action: {
                                authManager.authenticateUser()
                            }) {
                                HStack {
                                    Image(systemName: "faceid")
                                    Text("Test Target A: Face ID Gate")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .border(Color.blue.opacity(0.3), width: 1)
                            }
                            
                            Text("TARGET: AVFoundation (Camera)")
                                .font(.caption).foregroundColor(.gray).padding(.top, 10)
                            
                            // TARGET 2: Camera Overide
                            Button(action: {
                                showingCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Test Target B: Raw Camera Feed")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .border(Color.teal.opacity(0.3), width: 1)
                            }
                            
                            Text("TARGET: CoreML/Vision (AI Verification)")
                                .font(.caption).foregroundColor(.gray).padding(.top, 10)
                            
                            // TARGET 3: Vision Overide (Simülatörde Camera içinde test edilir, ancak ayrı bir buton mantığı koyabiliriz)
                            Button(action: {
                                showingCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text("Test Target C: Liveness Scan")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .border(Color.pink.opacity(0.3), width: 1)
                            }
                            
                            
                            Text("ENVIRONMENT SHIELD")
                                .font(.caption).foregroundColor(.gray).padding(.top, 10)
                            
                            // TARGET 4: Jailbreak Detection (Auth ile birleşiktir, tetiklemek için Auth'a basılır)
                            Button(action: {
                                authManager.authenticateUser()
                            }) {
                                HStack {
                                    Image(systemName: "lock.shield")
                                    Text("Test Target D: Anti-Tamper Core")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .border(Color.yellow.opacity(0.3), width: 1)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
