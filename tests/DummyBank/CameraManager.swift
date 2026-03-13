import AVFoundation
import SwiftUI
import Combine
import CoreImage
import UIKit

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var permissionGranted = false
    @Published var currentFrame: CGImage?
    @Published var isCameraAuthenticated = false
    @Published var errorMessage: String?
    
    let captureSession = AVCaptureSession()
    private let context = CIContext()
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            permissionGranted = false
            self.errorMessage = "Kamera erişimi reddedildi."
        }
    }
    
    func setupCamera() {
        captureSession.sessionPreset = .vga640x480
        
        // Simülatörlerde fiziksel kamera dönmeyebilir, crash'i engelliyoruz
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            self.errorMessage = "Ön kamera bulunamadı. (Simülatör ortamı olabilir)"
            
            // Simülatör içi Liveness Bypass testi için DummySession açabiliriz
            startDummySessionForSimulator()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            // HACKER HEDEFİ: setSampleBufferDelegate kısmı!
            // Frame'ler bizim captureOutput metodumuza düşecek.
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
            
        } catch {
            self.errorMessage = "Kamera hazırlanırken hata: \(error.localizedDescription)"
        }
    }
    
    // Uygulama kameraları desteklemeyen simülatördeyse diye Dummy Session
    func startDummySessionForSimulator() {
        DispatchQueue.main.async {
            self.errorMessage = "Simülatör Modu: Canlı akış yok. Liveness testleri için Frida kancası bekleniyor..."
        }
        
        // Simülatörde saniyede 1 yapay bir atış (Frame Trigger) yapacağız
        // Frida bu metoda kanca atıp boş atışı Hacker resmine çevirecek!
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.simulateFrameTrigger()
        }
    }
    
    // FRIDA'NIN YENİ HEDEFİ: @objc ve dynamic olması şart ki RAM'den kanca atılabilsin!
    @objc dynamic func simulateFrameTrigger() {
        // Normalde orijinal frame burada işlenir. 
        // Fakat biz Frida ile burayı ezip ekrana zorla kendi resmimizi basacağız.
    }
    
    // FRIDA İÇİN AÇILMIŞ ARKA KAPI: Frida bu metodu kullanarak dosya sistemindeki fotoyu RAM'e basar
    @objc(receiveHackerImage:) dynamic func receiveHackerImage(imagePath: String) {
        guard let img = UIImage(contentsOfFile: imagePath)?.cgImage else {
            print("Hacker resmi \(imagePath) bulunamadı!")
            return
        }
        DispatchQueue.main.async {
            self.currentFrame = img
        }
    }
    
    // MARK: - THE TARGET FUNCTION (Frida Tarafından Hooklanacak Yer!)
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Eğer Frida araya girip bu Frame'i (SampleBuffer'i) kendi sahte .jpg resmimizle değiştirirse
        // cihaz orijinal sensör yerine o sahte resmi ekrana/yapay zekaya gönderecektir.
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        // Biyometrik (Liveness) doğrulamaları normalde burada, cgImage kullanılarak yapılır.
        // Ama biz ekranı anlık o görüntüyle güncelleyeceğiz ki hacker resminin geldiğini görelim!
        DispatchQueue.main.async {
            self.currentFrame = cgImage
        }
    }
}
