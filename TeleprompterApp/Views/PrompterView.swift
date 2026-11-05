import SwiftUI

struct PrompterView: View {
    @State var script: Script
    @ObservedObject var storageService: ScriptStorageService
    
    @StateObject private var pipManager = PiPPrompterManager()
    @StateObject private var speechService = SpeechRecognitionService()
    
    @State private var isControlsVisible = true
    @State private var showingCountdown = false
    @State private var countdownValue = 3
    @State private var countdownTimer: Timer?
    @State private var showingCameraPrompter = false
    
    var body: some View {
        ZStack {
            // Background teleprompter hitam pekat khas studio rekaman
            Color.black.ignoresSafeArea()
            
            // PiP Container Layer (Tersembunyi tapi aktif di view hierarchy)
            PiPContainerView(prompterManager: pipManager)
                .frame(width: 1, height: 1)
                .opacity(0.01)
            
            // Tampilan Teks Teleprompter Utama
            mainPrompterTextDisplay
            
            // Indikator Area Fokus Membaca (Highlight Bar)
            if script.highlightCurrentLine {
                focusHighlightBar
            }
            
            // Overlay Hitung Mundur (Countdown Timer)
            if showingCountdown {
                countdownOverlay
            }
            
            // Kontrol Melayang di Bawah (Kecepatan, Font, Play, PiP)
            if isControlsVisible && !showingCountdown {
                VStack {
                    topFloatingBar
                    Spacer()
                    bottomControlPanel
                }
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            pipManager.configure(with: script)
            speechService.prepareForScript(content: script.content)
        }
        .onDisappear {
            pipManager.stopScrolling()
            speechService.stopListening()
            countdownTimer?.invalidate()
            storageService.updateScript(script)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isControlsVisible.toggle()
            }
        }
        .fullScreenCover(isPresented: $showingCameraPrompter) {
            CameraPrompterView(script: script)
        }
    }
    
    // MARK: - Komponen Teks Prompter
    private var mainPrompterTextDisplay: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        // Spacer atas agar teks awal mulai dari tengah layar fokus
                        Spacer().frame(height: geo.size.height * 0.4)
                        
                        Text(script.content)
                            .font(.system(size: CGFloat(script.fontSize), weight: .bold))
                            .foregroundColor(.white)
                            .lineSpacing(10)
                            .padding(.horizontal, CGFloat(script.marginHorizontal))
                            .multilineTextAlignment(.leading)
                            .id("SCRIPT_TEXT")
                        
                        // Spacer bawah agar teks akhir bisa mencapai tengah layar
                        Spacer().frame(height: geo.size.height * 0.6)
                    }
                }
            }
        }
    }
    
    // MARK: - Indikator Baris Fokus (Highlight Bar)
    private var focusHighlightBar: some View {
        VStack {
            Spacer()
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.18))
                    .frame(height: CGFloat(script.fontSize) * 1.6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                    )
                
                // Garis penunjuk fokus
                Capsule()
                    .fill(Color.yellow)
                    .frame(width: 5, height: CGFloat(script.fontSize) * 1.2)
                    .padding(.leading, 6)
            }
            .padding(.horizontal, 12)
            .allowsHitTesting(false)
            Spacer()
        }
    }
    
    // MARK: - Bar Atas
    private var topFloatingBar: some View {
        HStack {
            Button {
                dismissPrompter()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(script.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(script.wordCount) kata • Est. \(script.estimatedReadingTimeFormatted)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Tombol Buka Mode Kamera Dalam Aplikasi
            Button {
                showingCameraPrompter = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                    Text("Mode Kamera")
                }
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.8), Color.clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Panel Kontrol Bawah
    private var bottomControlPanel: some View {
        VStack(spacing: 16) {
            // Pengaturan Font & Margin
            HStack(spacing: 20) {
                // Stepper Ukuran Font
                HStack(spacing: 12) {
                    Text("A")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Button {
                        if script.fontSize > 20 {
                            script.fontSize -= 2
                            pipManager.configure(with: script)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("\(Int(script.fontSize))")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(width: 28)
                    
                    Button {
                        if script.fontSize < 64 {
                            script.fontSize += 2
                            pipManager.configure(with: script)
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("A")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                
                Spacer()
                
                // Toggle Voice Tracking
                Button {
                    script.useVoiceTracking.toggle()
                    if script.useVoiceTracking {
                        startVoiceTracking()
                    } else {
                        speechService.stopListening()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: script.useVoiceTracking ? "mic.fill" : "mic.slash")
                            .foregroundColor(script.useVoiceTracking ? .green : .gray)
                        Text("Voice")
                            .font(.caption.bold())
                            .foregroundColor(script.useVoiceTracking ? .white : .gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(script.useVoiceTracking ? Color.green.opacity(0.3) : Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            
            // Slider Kecepatan Prompter
            VStack(spacing: 4) {
                HStack {
                    Label("Kecepatan: \(Int(script.scrollSpeed)) pt/s", systemImage: "speedometer")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "tortoise.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Slider(value: $script.scrollSpeed, in: 10...120, step: 2) { _ in
                        pipManager.configure(with: script)
                    }
                    .accentColor(.yellow)
                    
                    Image(systemName: "hare.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            
            // Tombol Utama: Floating PiP & Play/Pause/Rewind
            HStack(spacing: 24) {
                // Rewind ke awal
                Button {
                    pipManager.resetScroll()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                
                // Play / Pause Utama dengan Countdown
                Button {
                    if pipManager.isPlaying {
                        pipManager.pauseScrolling()
                    } else {
                        startWithCountdown()
                    }
                } label: {
                    Image(systemName: pipManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                        .frame(width: 68, height: 68)
                        .background(Color.yellow)
                        .clipShape(Circle())
                        .shadow(color: Color.yellow.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                
                // TOMBOL UTAMA: Mulai Melayang (Picture-in-Picture)
                Button {
                    startFloatingPiP()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "pip.enter")
                            .font(.title2)
                        Text("Floating PiP")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(colors: [Color.clear, Color.black.opacity(0.95), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Countdown Overlay
    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 12) {
                Text("\(countdownValue)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
                    .scaleEffect(showingCountdown ? 1.0 : 0.4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: countdownValue)
                
                Text("Bersiap rekaman...")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Helper Logika
    private func startWithCountdown() {
        countdownValue = script.countdownDuration
        showingCountdown = true
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                timer.invalidate()
                showingCountdown = false
                pipManager.startScrolling()
                if script.useVoiceTracking {
                    startVoiceTracking()
                }
            }
        }
    }
    
    private func startFloatingPiP() {
        pipManager.configure(with: script)
        pipManager.startPiP()
    }
    
    private func startVoiceTracking() {
        speechService.startListening { progress in
            pipManager.updateProgressFromVoice(progress)
        }
    }
    
    @Environment(\.dismiss) private var dismissAction
    private func dismissPrompter() {
        dismissAction()
    }
}

