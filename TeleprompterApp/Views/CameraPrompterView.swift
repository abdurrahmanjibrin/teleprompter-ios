import SwiftUI
import AVFoundation

/// View pembungkus preview layer kamera AVCaptureSession
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

/// Mode Rekam Kamera Langsung dengan Teks Teleprompter di Atasnya
struct CameraPrompterView: View {
    let script: Script
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var cameraManager = CameraRecorderManager()
    @State private var isScrolling = false
    @State private var scrollOffset: CGFloat = 0.0
    @State private var timer: Timer?
    @State private var alertMessage: String?
    @State private var showingAlert = false
    
    var body: some View {
        ZStack {
            // 1. Preview Kamera Fullscreen
            CameraPreviewView(session: cameraManager.captureSession)
                .ignoresSafeArea()
            
            // 2. Teleprompter Overlay Transparan (Ditempatkan di dekat kamera atas agar tatapan mata pas ke lensa)
            VStack {
                prompterOverlayView
                    .frame(maxHeight: 280)
                    .padding(.top, 40)
                
                Spacer()
                
                // 3. Tombol Rekam & Kontrol Kamera Bawah
                cameraControlsBar
            }
        }
        .onDisappear {
            stopScrolling()
            cameraManager.captureSession.stopRunning()
        }
        .onChange(of: cameraManager.savedAlertMessage) { newMessage in
            if let msg = newMessage {
                alertMessage = msg
                showingAlert = true
            }
        }
        .alert("Informasi Video", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }
    
    // Overlay Naskah Transparan di dekat kamera depan iPhone 15
    private var prompterOverlayView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.withAlphaComponent(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            
            VStack {
                ScrollView(showsIndicators: false) {
                    Text(script.content)
                        .font(.system(size: CGFloat(script.fontSize - 4), weight: .semibold))
                        .foregroundColor(.white)
                        .lineSpacing(6)
                        .padding(16)
                        .offset(y: -scrollOffset)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal, 16)
    }
    
    // Bar Kontrol Rekam & Durasi
    private var cameraControlsBar: some View {
        VStack(spacing: 16) {
            if cameraManager.isRecording {
                // Indikator Durasi Rekam
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text(formatSeconds(cameraManager.recordedSeconds))
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
            }
            
            HStack(spacing: 40) {
                // Tutup
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                
                // Tombol Rekam Utama (Record / Stop)
                Button {
                    if cameraManager.isRecording {
                        cameraManager.stopRecording()
                        stopScrolling()
                    } else {
                        cameraManager.startRecording()
                        startScrolling()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                        
                        if cameraManager.isRecording {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 30, height: 30)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 60, height: 60)
                        }
                    }
                }
                
                // Flip Kamera Depan / Belakang
                Button {
                    cameraManager.flipCamera()
                } label: {
                    Image(systemName: "camera.rotate.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 36)
        }
        .background(
            LinearGradient(colors: [Color.clear, Color.black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
    
    private func startScrolling() {
        isScrolling = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            scrollOffset += CGFloat(script.scrollSpeed) * 0.05
        }
    }
    
    private func stopScrolling() {
        isScrolling = false
        timer?.invalidate()
        timer = nil
    }
    
    private func formatSeconds(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

