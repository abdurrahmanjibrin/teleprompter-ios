import Foundation
import Speech
import AVFoundation

/// Layanan Voice Tracking: mengenali suara pembicara dan menggerakkan prompter secara otomatis
class SpeechRecognitionService: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var currentMatchedWordIndex: Int = 0
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID")) // Dukungan Bahasa Indonesia
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var scriptWords: [String] = []
    
    init() {
        requestAuthorization()
    }
    
    func setLocale(identifier: String) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }
    
    func prepareForScript(content: String) {
        // Normalisasi kata-kata dalam naskah untuk pencocokan cepat
        let clean = content.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        self.scriptWords = clean
        self.currentMatchedWordIndex = 0
    }
    
    func startListening(onProgress: @escaping (Double) -> Void) {
        guard !isListening else { return }
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer tidak tersedia")
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Gagal konfigurasi audio session: \(error.localizedDescription)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            print("AudioEngine tidak bisa mulai: \(error.localizedDescription)")
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let spokenWords = result.bestTranscription.formattedString.lowercased()
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { !$0.isEmpty }
                
                if let lastSpoken = spokenWords.last {
                    self.matchSpokenWord(lastSpoken, onProgress: onProgress)
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopListening()
            }
        }
    }
    
    private func matchSpokenWord(_ word: String, onProgress: @escaping (Double) -> Void) {
        guard !scriptWords.isEmpty else { return }
        
        // Cari kecocokan kata mulai dari posisi indeks saat ini ke depan (window 15 kata)
        let searchRangeStart = currentMatchedWordIndex
        let searchRangeEnd = min(currentMatchedWordIndex + 15, scriptWords.count)
        
        for i in searchRangeStart..<searchRangeEnd {
            if scriptWords[i] == word || scriptWords[i].contains(word) || word.contains(scriptWords[i]) {
                currentMatchedWordIndex = i
                let progress = Double(i) / Double(scriptWords.count)
                DispatchQueue.main.async {
                    onProgress(progress)
                }
                break
            }
        }
    }
    
    func stopListening() {
        guard isListening else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
}

