import SwiftUI
import AVFoundation

@main
struct TeleprompterApp: App {
    init() {
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ScriptListView()
                .preferredColorScheme(.dark) // Tampilan studio profesional gelap
        }
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Gagal inisialisasi AVAudioSession di App: \(error.localizedDescription)")
        }
    }
}

