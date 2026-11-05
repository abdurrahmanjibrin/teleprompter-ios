import Foundation
import AVFoundation
import Photos
import UIKit

/// Pengelola Perekaman Kamera 4K / 1080p di dalam Aplikasi
class CameraRecorderManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var isRecording = false
    @Published var recordedSeconds: Int = 0
    @Published var currentPosition: AVCaptureDevice.Position = .front
    @Published var flashMode: AVCaptureDevice.TorchMode = .off
    @Published var savedAlertMessage: String?
    
    let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let movieOutput = AVCaptureMovieFileOutput()
    private var timer: Timer?
    
    override init() {
        super.init()
        checkPermissionsAndSetup()
    }
    
    func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupSession()
                    }
                }
            }
        default:
            break
        }
    }
    
    func setupSession() {
        captureSession.beginConfiguration()
        
        // Atur resolusi tertinggi yang didukung iPhone 15 (4K atau High 1080p)
        if captureSession.canSetSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = .hd4K3840x2160
        } else if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // 1. Setup Video Input (Kamera Depan default)
        setupCameraInput(position: .front)
        
        // 2. Setup Audio Input (Mikrofon)
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // 3. Setup Movie File Output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            if let connection = movieOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .cinematicExtended
                }
            }
        }
        
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = self?.captureSession.isRunning ?? false
            }
        }
    }
    
    private func setupCameraInput(position: AVCaptureDevice.Position) {
        if let currentInput = videoDeviceInput {
            captureSession.removeInput(currentInput)
        }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            return
        }
        
        captureSession.addInput(input)
        videoDeviceInput = input
        currentPosition = position
    }
    
    func flipCamera() {
        let newPosition: AVCaptureDevice.Position = (currentPosition == .front) ? .back : .front
        captureSession.beginConfiguration()
        setupCameraInput(position: newPosition)
        captureSession.commitConfiguration()
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let outputDirectory = FileManager.default.temporaryDirectory
        let outputURL = outputDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
        recordedSeconds = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.recordedSeconds += 1
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        movieOutput.stopRecording()
        isRecording = false
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraRecorderManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print("Gagal merekam video: \(error!.localizedDescription)")
            return
        }
        
        // Simpan otomatis ke Galeri Foto (Photos) iPhone
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                }) { [weak self] success, err in
                    DispatchQueue.main.async {
                        if success {
                            self?.savedAlertMessage = "Video berhasil disimpan ke Galeri Foto!"
                        } else {
                            self?.savedAlertMessage = "Gagal menyimpan ke galeri: \(err?.localizedDescription ?? "")"
                        }
                    }
                }
            }
        }
    }
}

