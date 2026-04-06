import AVFoundation
import SwiftUI
import Combine
import CoreImage
import UIKit
import Vision

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var permissionGranted = false
    @Published var currentFrame: CGImage?
    @Published var isCameraAuthenticated = false
    @Published var aiFaceDetected = false
    @Published var aiBlinkDetected = false
    @Published var errorMessage: String?
    
    let captureSession = AVCaptureSession()
    private let context = CIContext()
    private let sequenceHandler = VNSequenceRequestHandler()
    
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
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            self.errorMessage = "[SYSTEM] Camera sensor unresponsive. Switching to virtual liveness loop."
            startDummySessionForSimulator()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
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
    
    func startDummySessionForSimulator() {
        DispatchQueue.main.async {
            self.errorMessage = "AWAITING SENSOR INPUT... (Frida Injection Point Active)"
        }
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.simulateFrameTrigger()
        }
    }
    
    @objc dynamic func simulateFrameTrigger() {
        let emptyImage = CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 400, height: 400))
        guard let dummyCG = context.createCGImage(emptyImage, from: emptyImage.extent) else { return }
        
        let request = VNDetectFaceRectanglesRequest { [weak self] req, err in
            if let results = req.results as? [VNFaceObservation], !results.isEmpty {
                DispatchQueue.main.async {
                    self?.aiFaceDetected = true
                    self?.aiBlinkDetected = true 
                    self?.errorMessage = "🚨 SENSOR OVERRIDDEN: Synthetic face mapped by AI Engine!"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.isCameraAuthenticated = true
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.aiFaceDetected = false
                    self?.aiBlinkDetected = false
                    self?.errorMessage = "[LIVENESS] Scan failed. Sensor input is null."
                }
            }
        }
        
        do {
            try sequenceHandler.perform([request], on: dummyCG)
        } catch {
            // [UI Optimization]: Sessizce yakala, simülatör ML desteklemediği için oluşan konsol spaminı durdur
        }
    }
    
    @objc(receiveHackerImage:) dynamic func receiveHackerImage(imagePath: String) {
        guard let img = UIImage(contentsOfFile: imagePath)?.cgImage else {
            return
        }
        DispatchQueue.main.async {
            self.currentFrame = img
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        DispatchQueue.main.async {
            self.currentFrame = cgImage
        }
    }
}
