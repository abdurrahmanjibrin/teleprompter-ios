import Foundation
import Combine
import PDFKit

/// Layanan untuk penyimpanan dan impor naskah lokal
class ScriptStorageService: ObservableObject {
    @Published var scripts: [Script] = []
    
    private let fileName = "saved_scripts.json"
    
    init() {
        loadScripts()
        if scripts.isEmpty {
            scripts = [Script.sample]
            saveScripts()
        }
    }
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    func loadScripts() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Script].self, from: data)
            self.scripts = decoded.sorted(by: { $0.updatedAt > $1.updatedAt })
        } catch {
            print("Belum ada data tersimpan atau gagal decode: \(error.localizedDescription)")
        }
    }
    
    func saveScripts() {
        do {
            let data = try JSONEncoder().encode(scripts)
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Gagal menyimpan naskah: \(error.localizedDescription)")
        }
    }
    
    func addScript(_ script: Script) {
        scripts.insert(script, at: 0)
        saveScripts()
    }
    
    func updateScript(_ script: Script) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            var updated = script
            updated.updatedAt = Date()
            scripts[index] = updated
            scripts.sort(by: { $0.updatedAt > $1.updatedAt })
            saveScripts()
        }
    }
    
    func deleteScript(at offsets: IndexSet) {
        scripts.remove(atOffsets: offsets)
        saveScripts()
    }
    
    func deleteScript(id: UUID) {
        scripts.removeAll(where: { $0.id == id })
        saveScripts()
    }
    
    // Impor berkas naskah dari URL (misal dari File Picker TXT atau PDF)
    func importFile(from url: URL) -> Script? {
        let isAccessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileExtension = url.pathExtension.lowercased()
        let fileName = url.deletingPathExtension().lastPathComponent
        
        if fileExtension == "txt" {
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                let newScript = Script(title: fileName, content: content)
                addScript(newScript)
                return newScript
            }
        } else if fileExtension == "pdf" {
            if let pdf = PDFDocument(url: url) {
                var extractedText = ""
                for pageIndex in 0..<pdf.pageCount {
                    if let page = pdf.page(at: pageIndex), let pageText = page.string {
                        extractedText += pageText + "\n"
                    }
                }
                let cleanText = extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanText.isEmpty {
                    let newScript = Script(title: fileName, content: cleanText)
                    addScript(newScript)
                    return newScript
                }
            }
        }
        return nil
    }
}

