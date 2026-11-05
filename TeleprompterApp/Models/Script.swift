import Foundation

/// Model data untuk Naskah Teleprompter
struct Script: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var fontSize: Double = 32.0
    var scrollSpeed: Double = 40.0 // Kecepatan scroll (poin per detik)
    var marginHorizontal: Double = 24.0
    var useVoiceTracking: Bool = false
    var highlightCurrentLine: Bool = true
    var countdownDuration: Int = 3 // Detik hitung mundur (3s, 5s, dll)
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Perhitungan statistik naskah
    var wordCount: Int {
        let components = content.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
    }
    
    // Estimasi waktu baca (rata-rata 130 - 150 kata per menit)
    var estimatedReadingTimeFormatted: String {
        let words = wordCount
        guard words > 0 else { return "0 dtk" }
        let totalSeconds = Int((Double(words) / 140.0) * 60.0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes) mnt \(seconds) dtk"
        } else {
            return "\(seconds) dtk"
        }
    }
    
    static var sample: Script {
        Script(
            title: "Contoh Script Video",
            content: """
            Halo semuanya! Selamat datang kembali di video terbaru saya.

            Hari ini saya akan membahas 3 tips utama membuat konten video berkualitas tinggi hanya dengan iPhone 15 Anda.

            Tips pertama: Selalu pastikan pencahayaan Anda cukup. Anda bisa menggunakan cahaya alami dari jendela atau ring light.

            Tips kedua: Tatap langsung ke lensa kamera, bukan ke layar. Dengan teleprompter floating ini, mata Anda akan tampak selalu fokus ke penonton!

            Tips ketiga: Bicaralah dengan intonasi yang santai dan jelas.

            Jangan lupa klik tombol like, subscribe, dan nyalakan lonceng notifikasi untuk video bermanfaat berikutnya!
            """
        )
    }
}

