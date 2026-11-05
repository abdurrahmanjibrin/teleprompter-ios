import SwiftUI
import UniformTypeIdentifiers

struct ScriptListView: View {
    @StateObject private var storageService = ScriptStorageService()
    @State private var searchText: String = ""
    @State private var showingNewScriptSheet = false
    @State private var showingFileImporter = false
    @State private var selectedScriptForEditor: Script?
    
    var filteredScripts: [Script] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return storageService.scripts
        } else {
            return storageService.scripts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if filteredScripts.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredScripts) { script in
                            NavigationLink(destination: PrompterView(script: script, storageService: storageService)) {
                                scriptRow(script)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    storageService.deleteScript(id: script.id)
                                } label: {
                                    Label("Hapus", systemImage: "trash")
                                }
                                
                                Button {
                                    selectedScriptForEditor = script
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Teleprompter Pro")
            .searchable(text: $searchText, prompt: "Cari naskah...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            pasteFromClipboard()
                        } label: {
                            Label("Tempel dari Clipboard", systemImage: "doc.on.clipboard")
                        }
                        
                        Button {
                            showingFileImporter = true
                        } label: {
                            Label("Impor Berkas (TXT / PDF)", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewScriptSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingNewScriptSheet) {
                ScriptEditorView(storageService: storageService, script: Script(title: "Naskah Baru", content: ""))
            }
            .sheet(item: $selectedScriptForEditor) { script in
                ScriptEditorView(storageService: storageService, script: script)
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.plainText, .pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        _ = storageService.importFile(from: url)
                    }
                case .failure(let error):
                    print("Gagal impor berkas: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Tampilan Baris Naskah
    private func scriptRow(_ script: Script) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(script.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(script.estimatedReadingTimeFormatted)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            Text(script.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 12) {
                Label("\(script.wordCount) kata", systemImage: "text.word.spacing")
                Label("\(Int(script.scrollSpeed)) pt/s", systemImage: "speedometer")
                Label("\(Int(script.fontSize)) pt", systemImage: "textformat.size")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
    
    // Tampilan jika belum ada naskah
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 54))
                .foregroundColor(.secondary.opacity(0.7))
            Text("Belum ada naskah")
                .font(.title3)
                .fontWeight(.bold)
            Text("Tulis naskah baru, tempel langsung dari clipboard, atau impor berkas dokumen Anda.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            HStack(spacing: 16) {
                Button(action: { pasteFromClipboard() }) {
                    Label("Tempel Naskah", systemImage: "doc.on.clipboard")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: { showingNewScriptSheet = true }) {
                    Label("Tulis Baru", systemImage: "square.and.pencil")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func pasteFromClipboard() {
        if let clipboardString = UIPasteboard.general.string, !clipboardString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let firstLine = clipboardString.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespaces) ?? ""
            let autoTitle = firstLine.isEmpty ? "Naskah dari Clipboard" : String(firstLine.prefix(30))
            let newScript = Script(title: autoTitle, content: clipboardString)
            storageService.addScript(newScript)
            selectedScriptForEditor = newScript
        }
    }
}

