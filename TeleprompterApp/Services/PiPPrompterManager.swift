import Foundation
import UIKit
import AVKit
import AVFoundation

/// Pengelola Picture-in-Picture (PiP) Floating Teleprompter
/// Memanfaatkan AVSampleBufferDisplayLayer untuk mengalirkan teks naskah secara dinamis
/// sehingga dapat mengambang di atas aplikasi Kamera bawaan iPhone 15, Instagram, TikTok, dll.
class PiPPrompterManager: NSObject, ObservableObject {
    @Published var isPiPActive: Bool = false
    @Published var isPlaying: Bool = false
    @Published var scrollOffset: CGFloat = 0.0
    @Published var isSupported: Bool = AVPictureInPictureController.isPictureInPictureSupported()
    
    private var pipController: AVPictureInPictureController?
    private var sampleBufferLayer = AVSampleBufferDisplayLayer()
    private var displayLink: CADisplayLink?
    
    // Konfigurasi Naskah
    var script: Script = Script.sample
    private var lines: [String] = []
    private var totalContentHeight: CGFloat = 1000.0
    private var renderSize: CGSize = CGSize(width: 480, height: 270) // Rasio 16:9 ideal untuk jendela PiP iPhone
    
    private var pixelBufferPool: CVPixelBufferPool?
    private var formatDescription: CMVideoFormatDescription?
    private var frameTime: CMTime = .zero
    
    override init() {
        super.init()
        setupAudioSession()
        setupPixelBufferPool()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Gagal setting audio session untuk PiP: \(error.localizedDescription)")
        }
    }
    
    /// Menyiapkan layer PiP pada view kontainer di layar aplikasi
    func attachToView(_ view: UIView) {
        sampleBufferLayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        sampleBufferLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(sampleBufferLayer)
        
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            isSupported = false
            return
        }
        
        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: sampleBufferLayer,
            playbackDelegate: self
        )
        
        pipController = AVPictureInPictureController(contentSource: contentSource)
        pipController?.delegate = self
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
    }
    
    func configure(with script: Script) {
        self.script = script
        self.lines = script.content.components(separatedBy: "\n")
        self.scrollOffset = 0.0
        calculateContentHeight()
    }
    
    private func calculateContentHeight() {
        let font = UIFont.systemFont(ofSize: CGFloat(script.fontSize), weight: .semibold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let width = renderSize.width - 32
        let text = script.content as NSString
        let rect = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        )
        self.totalContentHeight = rect.height + renderSize.height
    }
    
    func startPiP() {
        guard let pipController = pipController, pipController.isPictureInPicturePossible else {
            print("PiP belum memungkinkan untuk dimulai")
            return
        }
        
        // Render minimal satu frame sebelum start agar layer memiliki video buffer
        renderNextFrame()
        pipController.startPictureInPicture()
    }
    
    func stopPiP() {
        pipController?.stopPictureInPicture()
        stopScrolling()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pauseScrolling()
        } else {
            startScrolling()
        }
    }
    
    func startScrolling() {
        isPlaying = true
        startDisplayLink()
    }
    
    func pauseScrolling() {
        isPlaying = false
        stopDisplayLink()
    }
    
    func stopScrolling() {
        isPlaying = false
        stopDisplayLink()
    }
    
    func resetScroll() {
        scrollOffset = 0.0
        renderNextFrame()
    }
    
    func updateProgressFromVoice(_ progress: Double) {
        scrollOffset = CGFloat(progress) * (totalContentHeight - renderSize.height)
        renderNextFrame()
    }
    
    // MARK: - Display Link Rendering Loop
    
    private func startDisplayLink() {
        stopDisplayLink()
        let dl = CADisplayLink(target: self, selector: #selector(onDisplayLinkStep))
        dl.preferredFrameRateRange = CAFrameRateRange(minimum: 24, maximum: 30, preferred: 30)
        dl.add(to: .main, forMode: .common)
        self.displayLink = dl
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func onDisplayLinkStep(link: CADisplayLink) {
        guard isPlaying else { return }
        let pointsPerSecond = CGFloat(script.scrollSpeed)
        let step = pointsPerSecond * CGFloat(link.targetTimestamp - link.timestamp)
        
        scrollOffset += step
        if scrollOffset > totalContentHeight {
            scrollOffset = 0 // Loop kembali ke atas atau pause
            pauseScrolling()
        }
        renderNextFrame()
    }
    
    // MARK: - Pixel Buffer & Video Generation
    
    private func setupPixelBufferPool() {
        let poolAttrs: [CFString: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey: 3
        ]
        let bufferAttrs: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: Int(renderSize.width),
            kCVPixelBufferHeightKey: Int(renderSize.height),
            kCVPixelFormatOpenGLESCompatibility: true
        ]
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttrs as CFDictionary, bufferAttrs as CFDictionary, &pixelBufferPool)
    }
    
    private func renderNextFrame() {
        guard let pool = pixelBufferPool else { return }
        var optionalBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &optionalBuffer)
        
        guard let pixelBuffer = optionalBuffer else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(renderSize.width),
            height: Int(renderSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return }
        
        UIGraphicsPushContext(context)
        
        // 1. Gambar background semi-transparan hitam
        context.setFillColor(UIColor.black.withAlphaComponent(0.78).cgColor)
        context.fill(CGRect(origin: .zero, size: renderSize))
        
        // 2. Garis Penanda Area Fokus (Highlight Bar di tengah PiP)
        if script.highlightCurrentLine {
            let highlightHeight: CGFloat = CGFloat(script.fontSize) * 1.5
            let highlightY = (renderSize.height - highlightHeight) / 2.0
            let highlightRect = CGRect(x: 10, y: highlightY, width: renderSize.width - 20, height: highlightHeight)
            
            context.setFillColor(UIColor.systemYellow.withAlphaComponent(0.20).cgColor)
            let path = UIBezierPath(roundedRect: highlightRect, cornerRadius: 8)
            context.addPath(path.cgPath)
            context.fillPath()
            
            // Indikator panah fokus
            let indicatorRect = CGRect(x: 12, y: highlightY + 4, width: 4, height: highlightHeight - 8)
            context.setFillColor(UIColor.systemYellow.cgColor)
            context.fill(indicatorRect)
        }
        
        // 3. Render Teks Berjalan
        let font = UIFont.systemFont(ofSize: CGFloat(script.fontSize), weight: .bold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 6
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        let textRect = CGRect(
            x: 24,
            y: (renderSize.height / 2.0) - scrollOffset,
            width: renderSize.width - 48,
            height: totalContentHeight
        )
        
        let attributedString = NSAttributedString(string: script.content, attributes: attributes)
        attributedString.draw(in: textRect)
        
        // 4. Header mini info kecepatan
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.lightGray
        ]
        let speedText = "Kec: \(Int(script.scrollSpeed)) pt/s • \(Int(script.fontSize)) pt"
        (speedText as NSString).draw(at: CGPoint(x: 16, y: 8), withAttributes: infoAttrs)
        
        UIGraphicsPopContext()
        
        // Enqueue ke SampleBufferDisplayLayer
        enqueueSampleBuffer(from: pixelBuffer)
    }
    
    private func enqueueSampleBuffer(from pixelBuffer: CVPixelBuffer) {
        if formatDescription == nil {
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &formatDescription
            )
        }
        
        guard let format = formatDescription else { return }
        
        frameTime = CMTimeAdd(frameTime, CMTime(value: 1, timescale: 30))
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: frameTime,
            decodeTimeStamp: .invalid
        )
        
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        if let sb = sampleBuffer {
            if sampleBufferLayer.status == .failed {
                sampleBufferLayer.flush()
            }
            sampleBufferLayer.enqueue(sb)
        }
    }
}

// MARK: - AVPictureInPictureControllerDelegate
extension PiPPrompterManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPiPActive = true
        startScrolling()
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPiPActive = false
        stopScrolling()
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        isPiPActive = false
        print("PiP Gagal Dimulai: \(error.localizedDescription)")
    }
}

// MARK: - AVPictureInPictureSampleBufferPlaybackDelegate
extension PiPPrompterManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        if playing {
            startScrolling()
        } else {
            pauseScrolling()
        }
    }
    
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        let duration = max(Double(totalContentHeight / CGFloat(script.scrollSpeed)), 1.0)
        return CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))
    }
    
    func pictureInPictureControllerIsPlaybackLikelyToKeepUp(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return true
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
        self.renderSize = CGSize(width: CGFloat(newRenderSize.width), height: CGFloat(newRenderSize.height))
        calculateContentHeight()
        renderNextFrame()
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion: @escaping () -> Void) {
        let seconds = CMTimeGetSeconds(skipInterval)
        let deltaOffset = CGFloat(seconds) * CGFloat(script.scrollSpeed)
        scrollOffset = max(0, scrollOffset + deltaOffset)
        renderNextFrame()
        completion()
    }
}

