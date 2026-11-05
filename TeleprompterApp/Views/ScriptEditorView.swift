import SwiftUI

struct ScriptEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storageService: ScriptStorageService
    
    @State var script: Script
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informasi Naskah") {
                    TextField("Judul Naskah", text: $script.title)
                        .font(.headline)
                    
                    HStack {
                        Label("\(script.wordCount) kata", systemImage: "character.book.closed")
                        Spacer()
                        Label("Est. \(script.estimatedReadingTimeFormatted)", systemImage: "clock")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                
                Section {
                    ZStack(alignment: .topTrailing) {
                        TextEditor(text: $script.content)
                            .frame(minHeight: 220)
                            .focused($isContentFocused)
                            .font(.system(size: 16))
                        
                        // Tombol Cepat Paste / Clear
                        HStack(spacing: 8) {
                            if !script.content.isEmpty {
                                Button {
                                    script.content = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Button {
                                if let text = UIPasteboard.general.string {
                                    if script.content.isEmpty {
                                        script.content = text
                                    } else {
                                        script.content += "\n" + text
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.clipboard")
                                    Text("Tempel")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 4)
                        .padding(.trailing, 4)
                    }
                } header: {
                    Text("Isi Naskah")
                } footer: {
                    Text("Anda dapat mengetik langsung atau menempelkan skrip dari Notes, WhatsApp, dokumen, dll.")
                }
                
                Section("Preferensi Naskah Ini") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Ukuran Font Teks")
                            Spacer()
                            Text("\(Int(script.fontSize)) pt")
                                .bold()
                                .foregroundColor(.blue)
                        }
                        Slider(value: $script.fontSize, in: 20...60, step: 2)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Kecepatan Scroll")
                            Spacer()
                            Text("\(Int(script.scrollSpeed)) pt/s")
                                .bold()
                                .foregroundColor(.blue)
                        }
                        Slider(value: $script.scrollSpeed, in: 10...120, step: 5)
                    }
                    
                    Toggle("Sorot Baris Fokus (Highlight Bar)", isOn: $script.highlightCurrentLine)
                    Toggle("Voice Tracking (Scroll otomatis suara)", isOn: $script.useVoiceTracking)
                }
            }
            .navigationTitle(script.title.isEmpty ? "Editor Naskah" : script.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        saveScript()
                        dismiss()
                    }
                    .bold()
                    .disabled(script.title.trimmingCharacters(in: .whitespaces).isEmpty && script.content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveScript() {
        if script.title.trimmingCharacters(in: .whitespaces).isEmpty {
            let firstLine = script.content.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespaces) ?? ""
            script.title = firstLine.isEmpty ? "Naskah Tanpa Judul" : String(firstLine.prefix(25))
        }
        
        if storageService.scripts.contains(where: { $0.id == script.id }) {
            storageService.updateScript(script)
        } else {
            storageService.addScript(script)
        }
    }
}

