import SwiftUI
import Combine

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var folders: [Folder] = []
    @Published var selectedFolderId: UUID?
    @Published var selectedNoteId: UUID?
    @Published var searchText: String = ""

    private let savePath: URL
    private var saveCancellable: AnyCancellable?
    private let saveSubject = PassthroughSubject<Void, Never>()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let oldAppDir = appSupport.appendingPathComponent("SideNotesClone")
        let appDir = appSupport.appendingPathComponent("VibeNotes")
        
        // Migrate old data if it exists and the new directory doesn't
        if FileManager.default.fileExists(atPath: oldAppDir.path) && !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.moveItem(at: oldAppDir, to: appDir)
        }
        
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.savePath = appDir.appendingPathComponent("data.json")
        
        load()
        
        if folders.isEmpty {
            let defaultFolder = Folder(name: "All Notes")
            folders.append(defaultFolder)
            selectedFolderId = defaultFolder.id
        }
        
        setupDebouncedSave()
    }
    
    private func setupDebouncedSave() {
        saveCancellable = saveSubject
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.save()
            }
    }
    
    func noteCount(for folderId: UUID) -> Int {
        notes.filter { $0.folderId == folderId }.count
    }

    func addFolder(name: String) {
        let folder = Folder(name: name)
        folders.append(folder)
        selectedFolderId = folder.id
        save()
    }

    func renameFolder(id: UUID, newName: String) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].name = newName
            save()
        }
    }

    func removeFolder(id: UUID) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            // Remove notes in this folder first or disassociate them?
            // SideNotes behavior: Deleting a folder deletes its notes.
            notes.removeAll(where: { $0.folderId == id })
            folders.remove(at: index)
            if selectedFolderId == id {
                selectedFolderId = folders.first?.id
            }
            save()
        }
    }

    func addNote(title: String = "New Note", content: String = "") {
        let note = Note(title: title, content: content, folderId: selectedFolderId)
        notes.append(note)
        selectedNoteId = note.id
        save()
    }
    
    func selectFolder(_ id: UUID?) {
        selectedFolderId = id
        selectedNoteId = nil // Clear selected note when switching folders
        save()
    }
    
    func selectNote(_ id: UUID?) {
        selectedNoteId = id
        save()
    }

    func removeNote(at indexSet: IndexSet) {
        notes.remove(atOffsets: indexSet)
        save()
    }
    
    func removeNote(id: UUID) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes.remove(at: index)
            if selectedNoteId == id {
                selectedNoteId = nil
            }
            save()
        }
    }

    func scheduleSave() {
        saveSubject.send()
    }

    func save() {
        // Prepare data on main thread (to access @Published properties safely)
        let dataToSave = DataContent(
            notes: notes,
            folders: folders,
            selectedFolderId: selectedFolderId,
            selectedNoteId: selectedNoteId
        )
        
        // Write to disk on background thread
        DispatchQueue.global(qos: .background).async { [savePath] in
            do {
                let data = try JSONEncoder().encode(dataToSave)
                try data.write(to: savePath)
            } catch {
                print("Failed to save data: \(error)")
            }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: savePath) else { return }
        do {
            let decoded = try JSONDecoder().decode(DataContent.self, from: data)
            self.notes = decoded.notes
            self.folders = decoded.folders
            self.selectedFolderId = decoded.selectedFolderId
            self.selectedNoteId = decoded.selectedNoteId
        } catch {
            print("Failed to load data: \(error)")
        }
    }
}

struct DataContent: Codable {
    let notes: [Note]
    let folders: [Folder]
    let selectedFolderId: UUID?
    let selectedNoteId: UUID?
}
