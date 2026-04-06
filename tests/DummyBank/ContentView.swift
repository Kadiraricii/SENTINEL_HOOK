import SwiftUI
import LocalAuthentication
import MachO
import Combine

// MARK: - Security Check Manager (Target D)
class SecurityCheckManager: ObservableObject {
    struct Finding: Identifiable {
        let id = UUID()
        let label: String
        let detected: Bool
        let detail: String
    }
    
    @Published var findings: [Finding] = []
    @Published var isChecking = false
    @Published var sentinelMaskActive = false
    
    // Frida hook target — called by frida_detection_bypass.js to mark findings as masked
    @objc dynamic func sentinelSecurityBypass() {
        DispatchQueue.main.async { [weak self] in
            self?.sentinelMaskActive = true
            print("[SENTINEL] Security bypass activated — Frida presence masked.")
            // Re-run checks to show updated (masked) results
            // Replace any Frida finding with MASKED
            self?.findings = self?.findings.map { f in
                if f.label.contains("frida") {
                    return Finding(label: f.label, detected: false, detail: "✅ MASKED by Sentinel stealth layer")
                }
                return f
            } ?? []
        }
    }
    
    @objc dynamic func runChecks() {
        isChecking = true
        sentinelMaskActive = false
        findings = []
        DispatchQueue.global().async { [weak self] in
            var results: [Finding] = []
            
            // 1. Jailbreak FS Probe
            let jbPaths = ["/Applications/Cydia.app", "/usr/bin/ssh", "/private/var/lib/apt"]
            for path in jbPaths {
                let found = FileManager.default.fileExists(atPath: path)
                results.append(Finding(label: "FS: \(path.split(separator: "/").last ?? "??")", detected: found, detail: found ? "⚠ DETECTED" : "CLEAN"))
            }
            
            // 2. Frida Agent Detection — frida_detection_bypass.js hooks open() to mask this
            var fridaFound = false
            let count = _dyld_image_count()
            for i in 0..<count {
                if let raw = _dyld_get_image_name(i) {
                    let name = String(cString: raw).lowercased()
                    if name.contains("frida") {
                        fridaFound = true
                        break
                    }
                }
            }
            results.append(Finding(
                label: "DYLD: frida-agent.dylib",
                detected: fridaFound,
                detail: fridaFound ? "⚠ INJECTED — Enable DETECTION SHIELD to mask" : "✅ MASKED or NOT PRESENT"
            ))
            
            // 3. /private write test
            let canWrite = FileManager.default.isWritableFile(atPath: "/private")
            results.append(Finding(label: "WRITE: /private", detected: canWrite, detail: canWrite ? "⚠ WRITABLE" : "PROTECTED"))
            
            DispatchQueue.main.async {
                self?.findings = results
                self?.isChecking = false
            }
        }
    }
}

// MARK: - Screen Enum
enum AppScreen: Equatable {
    case main
    case camera(label: String)
    case mfaOTP
    case jailbreakCheck
    case compromised(message: String)
    
    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main), (.mfaOTP, .mfaOTP), (.jailbreakCheck, .jailbreakCheck): return true
        case (.camera(let a), .camera(let b)): return a == b
        case (.compromised(let a), .compromised(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var mfaManager = MFAAuthManager()
    @StateObject private var secManager = SecurityCheckManager()
    
    @State private var screen: AppScreen = .main
    @State private var otpInput = ""
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()
            
            switch screen {
            case .main:
                mainView
            case .camera(let label):
                cameraView(label: label)
            case .mfaOTP:
                mfaOTPView
            case .jailbreakCheck:
                jailbreakView
            case .compromised(let msg):
                successView(message: msg)
            }
        }
        // Auto-route on bypass success
        .onChange(of: authManager.isAuthenticated) { val in
            if val { screen = .compromised(message: "TARGET A: LAContext.evaluatePolicy → FORCED (success)") }
        }
        .onChange(of: cameraManager.isCameraAuthenticated) { val in
            if val {
                // Determine which target was being tested from current screen
                var msg = "CAMERA/VISION GATE: isCameraAuthenticated → TRUE"
                if case .camera(let label) = screen {
                    if label.contains("LIVENESS") || label.contains("Vision") {
                        msg = "TARGET C: VNFaceObservation spoofed → AI LIVENESS DEFEATED"
                    } else if label.contains("Deepfake") || label.contains("CVPixelBuffer") {
                        msg = "TARGET F: CVPixelBuffer synthetic injection → DEEPFAKE ACTIVE"
                    } else if label.contains("Kernel") || label.contains("IOSurface") {
                        msg = "TARGET G: IOSurface/CMSampleBuffer kernel boundary → BREACHED"
                    } else {
                        msg = "TARGET B: AVCaptureSession feed override → CAMERA HIJACKED"
                    }
                }
                screen = .compromised(message: msg)
            }
        }
        .onChange(of: mfaManager.isFullyAuthenticated) { val in
            if val { screen = .compromised(message: "TARGET E: Biometric + OTP chain → BOTH GATES FORCED") }
        }
        .onChange(of: mfaManager.awaitingOTP) { val in
            if val { screen = .mfaOTP }
        }
    }
    
    // MARK: - Main View (A–G)
    var mainView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    Text("DummyBank Enterprise")
                        .font(.custom("Courier", size: 16))
                        .foregroundColor(.white)
                    Text("Security Test Platform")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 24)
                
                if let err = authManager.errorMessage {
                    Text(err)
                        .font(.custom("Courier", size: 12))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
                
                VStack(spacing: 10) {
                    sectionHeader("AUTHENTICATION LAYER")
                    
                    // A: Biometric
                    targetBtn(id: "A", module: "BIO-LOGIC BYPASS", label: "Face ID Gate",
                              sub: "LAContext.evaluatePolicy", color: Color(hex: "#bb86fc"),
                              icon: "faceid") {
                        authManager.authenticateUser()
                    }
                    
                    // B: Camera
                    targetBtn(id: "B", module: "CAMERA INJECTOR", label: "Raw Camera Feed",
                              sub: "AVCaptureSession override", color: Color(hex: "#03dac6"),
                              icon: "camera.fill") {
                        cameraManager.startDummySessionForSimulator()
                        screen = .camera(label: "TARGET B — AVCaptureSession Override")
                    }
                    
                    sectionHeader("AI / VISION LAYER")
                    
                    // C: Vision
                    targetBtn(id: "C", module: "AI VISION SPOOF", label: "Liveness Scan",
                              sub: "VNDetectFaceRectanglesRequest", color: Color(hex: "#cf6679"),
                              icon: "eye.fill") {
                        cameraManager.startDummySessionForSimulator()
                        screen = .camera(label: "TARGET C — Liveness Vision Intercept")
                    }
                    
                    // F: Deepfake
                    targetBtn(id: "F", module: "DEEPFAKE PIPELINE", label: "Deepfake Neural-Link",
                              sub: "CVPixelBuffer synthetic injection", color: Color(hex: "#ff5555"),
                              icon: "theatermasks.fill") {
                        cameraManager.startDummySessionForSimulator()
                        screen = .camera(label: "TARGET F — CVPixelBuffer Deepfake Feed")
                    }
                    
                    // G: Kernel
                    targetBtn(id: "G", module: "KERNEL CAM HOOK", label: "Kernel Camera Hook",
                              sub: "IOSurface / CMSampleBuffer layer", color: Color(hex: "#00ff88"),
                              icon: "gyroscope") {
                        cameraManager.startDummySessionForSimulator()
                        screen = .camera(label: "TARGET G — IOSurface Kernel Boundary")
                    }
                    
                    sectionHeader("MULTI-FACTOR LAYER")
                    
                    // E: MFA
                    targetBtn(id: "E", module: "MFA CHAIN BYPASS", label: "MFA Vault",
                              sub: "Biometric → OTP chain", color: Color(hex: "#ff2299"),
                              icon: "link.circle.fill") {
                        mfaManager.initiateMFAChain()
                    }
                    
                    sectionHeader("ENVIRONMENT LAYER")
                    
                    // D: Anti-Tamper
                    targetBtn(id: "D", module: "DETECTION SHIELD", label: "Anti-Tamper Core",
                              sub: "Jailbreak / Frida detection scan", color: Color(hex: "#ffd700"),
                              icon: "lock.shield") {
                        secManager.runChecks()
                        screen = .jailbreakCheck
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Camera View (B / C / F / G)
    func cameraView(label: String) -> some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Button(action: {
                    cameraManager.stopSession()
                    screen = .main
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("ABORT").font(.custom("Courier", size: 12))
                    }
                    .foregroundColor(.red)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("INTERCEPTING").font(.custom("Courier", size: 10)).foregroundColor(.green)
                }
            }
            .padding()
            
            Text(label)
                .font(.custom("Courier", size: 11))
                .foregroundColor(.green.opacity(0.8))
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Feed viewport
            ZStack {
                Rectangle().fill(Color.black).frame(height: 320).overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                
                if cameraManager.currentFrame != nil {
                    Text("[FRAME CAPTURED]").font(.custom("Courier", size: 14)).foregroundColor(.green)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 40))
                            .foregroundColor(.green.opacity(0.4))
                        Text("AWAITING INJECTION SIGNAL")
                            .font(.custom("Courier", size: 12))
                            .foregroundColor(.green.opacity(0.6))
                        Text("Enable matching Sentinel module")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Corner markers
                VStack {
                    HStack {
                        cornerMark(tl: true)
                        Spacer()
                        cornerMark(tl: false)
                    }
                    Spacer()
                    HStack {
                        cornerMarkBottom(left: true)
                        Spacer()
                        cornerMarkBottom(left: false)
                    }
                }
                .padding(16)
                .frame(height: 320)
            }
            .padding(.horizontal)
            
            if let msg = cameraManager.errorMessage {
                Text(msg)
                    .font(.custom("Courier", size: 11))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
        }
    }
    
    // MARK: - MFA OTP View (E)
    var mfaOTPView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.badge.filled.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .padding(.top, 60)
            
            Text("SMS OTP VERIFICATION")
                .font(.custom("Courier", size: 16))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Status badge
            HStack(spacing: 6) {
                Circle().fill(Color.purple).frame(width: 8, height: 8)
                Text("MFA CHAIN ACTIVE → ANY CODE ACCEPTED")
                    .font(.custom("Courier", size: 10))
                    .foregroundColor(.purple)
            }
            .padding(8)
            .background(Color.purple.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.purple.opacity(0.3), lineWidth: 1))
            
            Text("Without Sentinel: enter exact OTP.\nWith Sentinel active: any 6-digit code works.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            TextField("000000", text: $otpInput)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.black.opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.5), lineWidth: 1))
                .cornerRadius(10)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .font(.custom("Courier", size: 30))
                .frame(width: 220)
                .onChange(of: otpInput) { val in
                    if val.count == 6 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            _ = mfaManager.verifyOTP(code: val)
                            otpInput = ""
                        }
                    }
                }
            
            if let err = mfaManager.errorMessage {
                Text(err).foregroundColor(.red).font(.custom("Courier", size: 12))
            }
            
            Button("SUBMIT CODE") {
                _ = mfaManager.verifyOTP(code: otpInput)
                otpInput = ""
            }
            .font(.custom("Courier", size: 14))
            .fontWeight(.bold)
            .padding(.horizontal, 30).padding(.vertical, 12)
            .background(Color.orange.opacity(0.8))
            .foregroundColor(.white).cornerRadius(8)
            
            Button("ABORT") {
                mfaManager.reset()
                otpInput = ""
                screen = .main
            }
            .font(.custom("Courier", size: 12)).foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    // MARK: - Jailbreak Check View (D)
    var jailbreakView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { screen = .main }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("BACK").font(.custom("Courier", size: 12))
                    }.foregroundColor(.red)
                }
                Spacer()
                Text("ANTI-TAMPER SCAN").font(.custom("Courier", size: 12)).foregroundColor(.yellow)
            }
            .padding()
            
            Text("TARGET D — Detection Shield Surface")
                .font(.caption).foregroundColor(.gray).padding(.bottom, 16)
            
            if secManager.isChecking {
                VStack(spacing: 12) {
                    ProgressView().tint(.yellow)
                    Text("SCANNING ENVIRONMENT...").font(.custom("Courier", size: 12)).foregroundColor(.yellow)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(secManager.findings) { f in
                            HStack {
                                Image(systemName: f.detected ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(f.detected ? .red : .green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(f.label).font(.custom("Courier", size: 12)).foregroundColor(.white)
                                    Text(f.detail).font(.custom("Courier", size: 10)).foregroundColor(f.detected ? .red : .green)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.03))
                            .border(f.detected ? Color.red.opacity(0.3) : Color.green.opacity(0.3), width: 1)
                        }
                        
                        if !secManager.findings.isEmpty {
                            Text("⚡ Enable DETECTION SHIELD in Sentinel to mask these findings.")
                                .font(.custom("Courier", size: 10))
                                .foregroundColor(.yellow.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
    }
    
    // MARK: - Success / Compromised View
    func successView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.open.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .shadow(color: .green, radius: 20)
            
            Text("SYSTEM COMPROMISED")
                .font(.custom("Courier", size: 22))
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text(message)
                .font(.custom("Courier", size: 12))
                .foregroundColor(.green)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(12)
                .background(Color.green.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.2), lineWidth: 1))
            
            Text("GİZLİ VERİ: HESAP_BAKİYESİ_$1.000.000")
                .font(.custom("Courier", size: 11))
                .foregroundColor(.green)
                .padding(8)
                .background(Color.green.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.green, lineWidth: 1))
            
            Spacer()
            
            Button("RESET ALL SYSTEMS") {
                authManager.isAuthenticated = false
                authManager.errorMessage = nil
                cameraManager.isCameraAuthenticated = false
                cameraManager.stopSession()
                mfaManager.reset()
                screen = .main
            }
            .font(.custom("Courier", size: 14))
            .padding(.horizontal, 30).padding(.vertical, 12)
            .background(Color.red.opacity(0.2))
            .foregroundColor(.red)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.3), lineWidth: 1))
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Reusable Components
    func targetBtn(id: String, module: String, label: String, sub: String, color: Color, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Target ID badge
                Text(id)
                    .font(.custom("Courier", size: 16))
                    .fontWeight(.bold)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.5), lineWidth: 1))
                    .foregroundColor(color)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Module: \(module)")
                        .font(.custom("Courier", size: 9))
                        .foregroundColor(color.opacity(0.7))
                    Text(sub)
                        .font(.custom("Courier", size: 9))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
            }
            .padding(14)
            .background(Color.white.opacity(0.03))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 1))
        }
    }
    
    func sectionHeader(_ title: String) -> some View {
        HStack {
            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
            Text(title)
                .font(.custom("Courier", size: 9))
                .foregroundColor(.gray)
                .fixedSize()
                .padding(.horizontal, 8)
            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
        }
        .padding(.vertical, 8)
    }
    
    // Corner marker helpers
    func cornerMark(tl: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if tl {
                    Rectangle().fill(Color.green.opacity(0.6)).frame(width: 12, height: 2)
                    Spacer()
                } else {
                    Spacer()
                    Rectangle().fill(Color.green.opacity(0.6)).frame(width: 12, height: 2)
                }
            }
            HStack {
                if tl {
                    Rectangle().fill(Color.green.opacity(0.6)).frame(width: 2, height: 12)
                    Spacer()
                } else {
                    Spacer()
                    Rectangle().fill(Color.green.opacity(0.6)).frame(width: 2, height: 12)
                }
            }
        }
    }
    
    func cornerMarkBottom(left: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                if left {
                    Rectangle().fill(Color.green.opacity(0.6)).frame(width: 2, height: 12)
                    Spacer()
                } else {
                    Spacer()
                    Rectangle().fill(Color.green.opacity(0.6)).frame(width: 2, height: 12)
                }
            }
            HStack(spacing: 0) {
                if left {
                    Rectangle().fill(Color.green.opacity(0.6)).frame(width: 12, height: 2)
                    Spacer()
                } else {
                    Spacer()
                    Rectangle().fill(Color.green.opacity(0.6)).frame(width: 12, height: 2)
                }
            }
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 08) & 0xFF) / 255
        let b = Double((int >> 00) & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
