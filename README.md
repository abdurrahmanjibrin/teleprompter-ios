# Teleprompter Pro untuk iPhone 15 📱🎬

Aplikasi Teleprompter Native iOS (Swift & SwiftUI) yang dirancang khusus untuk iPhone 15 dengan fitur unggulan **Picture-in-Picture (PiP) Floating Overlay**, perekaman video resolusi tinggi 4K/1080p, dan **Voice Tracking**.

---

## ✨ Fitur Utama Sesuai Kebutuhan Anda

1. **Floating Window di Atas Kamera iPhone 15 (Picture-in-Picture)**
   - Menggunakan teknologi `AVSampleBufferDisplayLayer` & `AVPictureInPictureController`.
   - Naskah dapat melayang mengambang di atas **aplikasi Kamera bawaan iOS**, TikTok, Instagram Reels, Zoom, atau aplikasi lainnya.
   - Anda dapat menggeser jendela floating tepat di bawah lensa kamera depan / Dynamic Island iPhone 15 agar tatapan mata tampak 100% natural menatap penonton saat membaca.
   - Kontrol Play / Pause / Skip langsung dari jendela floating PiP.

2. **Pengaturan Fleksibel Teks & Kecepatan**
   - **Ukuran Font:** Dapat diatur dari ukuran kecil hingga sangat besar (20 pt – 64 pt).
   - **Kecepatan Scroll:** Slider pengatur kecepatan (10 – 120 pt/detik) dengan indikator visual.
   - **Highlight Bar (Area Fokus):** Menyorot baris naskah yang sedang dibaca agar Anda tidak kehilangan jejak kata.
   - **Hitung Mundur (Countdown Timer):** Timer 3 detik sebelum naskah mulai berjalan, memberi jeda persiapan sebelum Anda bicara.

3. **Voice Tracking (Scroll Otomatis Mengikuti Suara)**
   - Didukung `SFSpeechRecognizer` dengan dukungan bahasa Indonesia (`id-ID`).
   - Naskah bergeser otomatis sesuai kata yang Anda ucapkan, berhenti jika Anda berhenti bicara.

4. **Tulis, Tempel, & Manajemen Naskah Lengkap**
   - Tulis naskah baru langsung di aplikasi.
   - **One-tap Paste:** Tempel langsung skrip dari clipboard (WhatsApp, Notes, Chat).
   - **Impor Berkas:** Mendukung impor dokumen naskah format `.txt` dan `.pdf`.
   - Estimasi waktu baca otomatis dan penghitung jumlah kata.
   - Penyimpanan lokal otomatis (CRUD: buat, edit, cari, hapus).

5. **Mode Kamera Terintegrasi (In-App Camera)**
   - Merekam video resolusi tinggi (hingga 4K) langsung di aplikasi.
   - Pratinjau kamera depan & belakang dengan teks teleprompter transparan di atasnya.
   - Video hasil rekaman otomatis tersimpan ke Galeri Foto (Photos) iPhone Anda.

---

## 📁 Struktur Berkas Proyek

```
TeleprompterApp/
├── TeleprompterApp.swift              # Titik masuk aplikasi & konfigurasi Audio Session
├── Resources/
│   └── Info.plist                     # Izin Kamera, Mikrofon, Speech Recognition, & PiP
├── Models/
│   └── Script.swift                   # Model data naskah, statistik kata & waktu baca
├── Services/
│   ├── ScriptStorageService.swift     # Penyimpanan JSON lokal & parser dokumen PDF/TXT
│   ├── SpeechRecognitionService.swift # Engine Voice Tracking berbasis SFSpeechRecognizer
│   ├── PiPPrompterManager.swift       # Engine rendering PiP video stream & kontrol Play/Pause
│   └── CameraRecorderManager.swift    # Engine perekaman video 4K & integrasi galeri foto
└── Views/
    ├── ScriptListView.swift           # Tampilan utama daftar naskah & pencarian
    ├── ScriptEditorView.swift         # Editor penulisan, tempel cepat & pengaturan per-naskah
    ├── PrompterView.swift             # Layar prompter, kontrol live, countdown & tombol PiP
    ├── PiPContainerView.swift         # Bridge UIKit representable untuk layer video PiP
    └── CameraPrompterView.swift       # Layar rekam video 4K dengan overlay naskah transparan
```

---

## 🚀 Panduan Memasang di iPhone 15

### Langkah 1: Buka di Xcode
1. Pindahkan folder proyek ini ke Mac Anda.
2. Buka **Xcode** -> **Create New Project** -> Pilih template **iOS App (SwiftUI)** dengan nama `TeleprompterApp`.
3. Masukkan berkas-berkas dari folder `TeleprompterApp/` ke dalam proyek Xcode Anda.

### Langkah 2: Konfigurasi Signing & Capabilities
1. Pada menu target proyek di Xcode, buka tab **Signing & Capabilities**.
2. Masukkan Apple ID gratis Anda pada bagian **Team**.
3. Di bagian **Background Modes**, centang:
   - ✅ **Audio, AirPlay, and Picture in Picture** (Wajib agar naskah melayang saat membuka kamera).

### Langkah 3: Jalankan di iPhone 15
1. Hubungkan iPhone 15 Anda ke Mac menggunakan kabel USB-C.
2. Pilih iPhone 15 Anda sebagai target perangkat di bagian atas Xcode.
3. Klik tombol **Play / Run** (`Cmd + R`).
4. Di iPhone 15 Anda, buka **Settings** -> **General** -> **VPN & Device Management** -> klik profil developer Anda dan pilih **Trust** (hanya perlu sekali di awal).

---

## 💡 Cara Menggunakan Fitur Melayang (PiP) di Atas Kamera

1. Buka aplikasi **Teleprompter Pro** di iPhone 15 Anda.
2. Pilih naskah yang ingin dibaca (atau tempel naskah baru).
3. Sesuaikan ukuran font dan kecepatan yang diinginkan.
4. Tekan tombol biru bertuliskan **"Floating PiP"**.
5. Naskah akan masuk ke jendela kecil melayang (Picture-in-Picture).
6. **Swipe up layar iPhone Anda ke Home Screen, lalu buka aplikasi Kamera bawaan iPhone (atau Instagram/TikTok).**
7. Jendela naskah akan tetap mengambang di atas kamera!
8. Pindahkan jendela PiP ke posisi paling atas (tepat di bawah kamera depan/Dynamic Island iPhone 15) agar pandangan mata Anda menatap lurus ke arah penonton!
9. Tekan tombol Play/Pause langsung pada jendela floating tersebut saat mulai merekam.

