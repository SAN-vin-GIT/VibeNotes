import SwiftUI
import Combine
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: NoteStore
    @State private var isShowingSearch = false
    
    // Deletion Alert State
    @State private var itemToDelete: DeletableItem? = nil
    @State private var showDeleteConfirmation = false
    @State private var showQuitConfirmation = false
    
    enum DeletableItem: Identifiable {
        case note(UUID)
        case folder(UUID)
        var id: UUID {
            switch self {
            case .note(let id): return id
            case .folder(let id): return id
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Folder Sidebar
            VStack {
                FolderListView(itemToDelete: $itemToDelete, showDeleteConfirmation: $showDeleteConfirmation)
                
                Spacer()
                
                // Quit Button
                Button(action: { showQuitConfirmation = true }) {
                    Image(systemName: "power")
                        .font(.title3)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.bottom, 20)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 56)
            .background(.regularMaterial)
            .background(Color.white.opacity(0.15))
            
            // Note List and Editor
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    if let _ = store.selectedNoteId {
                        Button(action: { store.selectNote(nil) }) {
                            Image(systemName: "chevron.left")
                                .padding(.trailing, 8)
                        }
                    }
                    
                    if isShowingSearch {
                        TextField("Search...", text: $store.searchText)
                            .textFieldStyle(.roundedBorder)
                    } else if let folderId = store.selectedFolderId,
                              let folderIndex = store.folders.firstIndex(where: { $0.id == folderId }) {
                        TextField("Folder Name", text: Binding(
                            get: { store.folders[folderIndex].name },
                            set: { store.renameFolder(id: folderId, newName: $0) }
                        ))
                        .textFieldStyle(.plain)
                        .font(.headline)
                        .frame(maxWidth: 150)
                    } else {
                        Text("Notes")
                            .font(.headline)
                    }
                    Spacer()
                    Button(action: { isShowingSearch.toggle() }) {
                        Image(systemName: "magnifyingglass")
                    }
                    Button(action: { (NSApplication.shared.delegate as? AppDelegate)?.toggleHeight() }) {
                        Image(systemName: "arrow.up.and.down")
                    }
                    Button(action: { store.addNote() }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                    }
                    Button(action: { (NSApplication.shared.delegate as? AppDelegate)?.togglePanel(expand: false) }) {
                        Image(systemName: "chevron.right.double")
                    }
                }
                .buttonStyle(.plain)
                .padding()
                
                Divider()
                
                // Content Area
                NoteListView(itemToDelete: $itemToDelete, showDeleteConfirmation: $showDeleteConfirmation)
                
                Spacer(minLength: 0)
                
                // Branding Pill
                HStack {
                    Spacer()
                    Text("Made by Sangeet")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                        .padding(.bottom, 20)
                    Spacer()
                }
            }
            .background(.ultraThinMaterial) // Thin blurred glass
        }
        .clipShape(RoundedRectangle(cornerRadius: 20)) // Smooth, rounded drawer corners
        .onTapGesture {
            // Force focus dismissal when clicking on empty areas
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .environmentObject(store)
        .confirmationDialog("Are you sure?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    switch item {
                    case .note(let id):
                        store.removeNote(id: id)
                    case .folder(let id):
                        store.removeFolder(id: id)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .confirmationDialog("Quit Application?", isPresented: $showQuitConfirmation, titleVisibility: .visible) {
            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to exit Vibe Notes?")
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}

struct FolderListView: View {
    @EnvironmentObject var store: NoteStore
    @Binding var itemToDelete: ContentView.DeletableItem?
    @Binding var showDeleteConfirmation: Bool
    
    @State private var draggedFolder: Folder?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) { // Stealth Scroll
            VStack(alignment: .center, spacing: 14) { // Slightly more spacing for initials
                ForEach(store.folders) { folder in
                    @State var isTargeted = false
                    
                    Button(action: { 
                        withAnimation(.easeOut(duration: 0.15)) {
                            store.selectFolder(folder.id) 
                        }
                    }) {
                        FolderIconView(name: folder.name, isSelected: store.selectedFolderId == folder.id)
                            .overlay(alignment: .bottomTrailing) {
                                Text("\(store.noteCount(for: folder.id))")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .offset(x: 4, y: 4)
                            }
                            .scaleEffect(isTargeted ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            itemToDelete = .folder(folder.id)
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .onDrag {
                        self.draggedFolder = folder
                        return NSItemProvider(object: folder.id.uuidString as NSString)
                    }
                    .onDrop(of: [.plainText], delegate: FolderDropDelegate(folder: folder, store: store, draggedFolder: $draggedFolder, isTargeted: $isTargeted))
                }
                
                Button(action: { store.addFolder(name: "New Folder") }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .frame(width: 60)
    }
}

struct FolderIconView: View {
    let name: String
    let isSelected: Bool
    
    var initials: String {
        let words = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(1)).uppercased()
        }
        return "?"
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                .frame(width: 42, height: 42)
            
            Text(initials)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct NoteListView: View {
    @EnvironmentObject var store: NoteStore
    @Binding var itemToDelete: ContentView.DeletableItem?
    @Binding var showDeleteConfirmation: Bool
    
    @State private var draggedNote: Note?
    
    var filteredNoteList: [Note] {
        let searchText = store.searchText
        let selectedFolderId = store.selectedFolderId
        
        var result: [Note] = []
        for note in store.notes {
            if note.folderId == selectedFolderId {
                if searchText.isEmpty {
                    result.append(note)
                } else if note.title.localizedCaseInsensitiveContains(searchText) ||
                            note.content.localizedCaseInsensitiveContains(searchText) {
                    result.append(note)
                }
            }
        }
        return result
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredNoteList) { note in
                    @State var isTargeted = false
                    
                    NoteRowView(note: note, itemToDelete: $itemToDelete, showDeleteConfirmation: $showDeleteConfirmation)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .padding(.horizontal, 8)
                        .onDrag {
                            self.draggedNote = note
                            return NSItemProvider(object: note.id.uuidString as NSString)
                        } preview: {
                            Text(note.title.isEmpty ? "Untitled Note" : note.title)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .onDrop(of: [.plainText], delegate: NoteDropDelegate(note: note, store: store, draggedNote: $draggedNote, isTargeted: $isTargeted))
                }
            }
        }
    }
}

struct NoteRowView: View {
    @EnvironmentObject var store: NoteStore
    let note: Note
    @Binding var itemToDelete: ContentView.DeletableItem?
    @Binding var showDeleteConfirmation: Bool
    
    @State private var isEditingTitle = false // New state for renaming
    @FocusState private var isTitleFocused: Bool
    
    var isExpanded: Bool {
        store.selectedNoteId == note.id
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Note Title (Clickable Header)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .foregroundColor(.secondary)
                    
                    if isEditingTitle, let index = store.notes.firstIndex(where: { $0.id == note.id }) {
                        TextField("Note Title", text: $store.notes[index].title, onCommit: {
                            isEditingTitle = false
                        })
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .bold))
                        .focused($isTitleFocused)
                        .onAppear { isTitleFocused = true }
                        .onChange(of: isTitleFocused) { focused in
                            if !focused {
                                isEditingTitle = false
                            }
                        }
                    } else {
                        Text(note.title.isEmpty ? "Untitled Note" : note.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                isEditingTitle = true
            }
            .onTapGesture(count: 1) {
                withAnimation(.easeOut(duration: 0.15)) {
                    if isExpanded {
                        store.selectNote(nil)
                    } else {
                        store.selectNote(note.id)
                    }
                }
            }
            
            if isExpanded, let index = store.notes.firstIndex(where: { $0.id == note.id }) {
                VStack(spacing: 0) {
                    NoteEditorView(note: $store.notes[index])
                        .padding(.horizontal)
                    
                    // Toolbar & Timestamp Footer
                    HStack {
                        HStack(spacing: 12) {
                            Button(action: {
                                NotificationCenter.default.post(name: Notification.Name("BoldSelectedText"), object: note.id)
                            }) {
                                Image(systemName: "textformat")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                itemToDelete = .note(note.id)
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                        
                        Spacer()
                        
                        let formatter: DateFormatter = {
                            let f = DateFormatter()
                            f.dateStyle = .short
                            f.timeStyle = .short
                            return f
                        }()
                        
                        Text(formatter.string(from: note.updatedAt))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .transition(.opacity.animation(.easeOut(duration: 0.15)))
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                itemToDelete = .note(note.id)
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct NoteEditorView: View {
    @EnvironmentObject var store: NoteStore
    @Binding var note: Note
    @State private var dynamicHeight: CGFloat = 40
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Native Editor Layer - Now handles its own height reporting
            AutoExpandingTextView(text: $note.content, dynamicHeight: $dynamicHeight, noteId: note.id)
                .frame(height: dynamicHeight)
            
            // Placeholder Layer
            if note.content.isEmpty {
                Text("Write here...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.top, 9) // Use 9 for baseline alignment
                    .padding(.leading, 2)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: note.content) { _ in
            store.scheduleSave()
        }
    }
}

struct AutoExpandingTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var dynamicHeight: CGFloat
    let noteId: UUID
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.delegate = context.coordinator
        
        // Setup bolding listener
        context.coordinator.setupNotifications(for: textView)
        
        // Zero out ALL insets for absolute pixel control
        textView.font = .systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 0, height: 8)
        textView.textContainer?.lineFragmentPadding = 0 // Remove the default 5px indent
        
        // Remove focus ring
        textView.focusRingType = .none
        
        // Disable internal scrolling
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.string != text {
            nsView.string = text
        }
        
        // Apply styles
        context.coordinator.applyStyles(to: nsView)
        
        // Update height based on content
        if let layoutManager = nsView.layoutManager, let container = nsView.textContainer {
            layoutManager.ensureLayout(for: container)
            let usedRect = layoutManager.usedRect(for: container)
            let newHeight = max(40, usedRect.height + nsView.textContainerInset.height * 2)
            if dynamicHeight != newHeight {
                DispatchQueue.main.async {
                    self.dynamicHeight = newHeight
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AutoExpandingTextView
        private var notificationCancellable: AnyCancellable?
        
        init(_ parent: AutoExpandingTextView) {
            self.parent = parent
        }
        
        func setupNotifications(for textView: NSTextView) {
            notificationCancellable = NotificationCenter.default
                .publisher(for: Notification.Name("BoldSelectedText"))
                .sink { [weak self, weak textView] notification in
                    guard let self = self, let textView = textView else { return }
                    guard let noteId = notification.object as? UUID, noteId == self.parent.noteId else { return }
                    self.applyBold(to: textView)
                }
        }
        
        private func applyBold(to textView: NSTextView) {
            let range = textView.selectedRange()
            let fullText = textView.string
            let nsString = (fullText as NSString)
            
            // Check if already bolded (simplistic check for selection wrapped in **)
            let isBolded: Bool
            if range.location >= 2 && range.location + range.length <= nsString.length - 2 {
                let startPrefix = nsString.substring(with: NSRange(location: range.location - 2, length: 2))
                let endSuffix = nsString.substring(with: NSRange(location: range.location + range.length, length: 2))
                isBolded = (startPrefix == "**" && endSuffix == "**")
            } else {
                isBolded = false
            }
            
            if isBolded {
                // Remove stars
                let unboldedRange = NSRange(location: range.location - 2, length: range.length + 4)
                let selectedText = nsString.substring(with: range)
                if textView.shouldChangeText(in: unboldedRange, replacementString: selectedText) {
                    textView.replaceCharacters(in: unboldedRange, with: selectedText)
                    textView.didChangeText()
                    textView.setSelectedRange(NSRange(location: range.location - 2, length: range.length))
                }
            } else {
                // Add stars
                let selectedText = nsString.substring(with: range)
                let newText = "**\(selectedText)**"
                if textView.shouldChangeText(in: range, replacementString: newText) {
                    textView.replaceCharacters(in: range, with: newText)
                    textView.didChangeText()
                    textView.setSelectedRange(NSRange(location: range.location + 2, length: range.length))
                }
            }
            
            applyStyles(to: textView)
        }
        
        func applyStyles(to textView: NSTextView) {
            guard let storage = textView.textStorage else { return }
            let fullRange = NSRange(location: 0, length: storage.length)
            
            // 1. Reset everything to standard font
            let normalFont = NSFont.systemFont(ofSize: 14)
            storage.addAttribute(.font, value: normalFont, range: fullRange)
            storage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
            storage.addAttribute(.kern, value: 0.0, range: fullRange) // Reset kerning

            // 2. Bold the **text**
            let pattern = "\\*\\*(.*?)\\*\\*"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: textView.string, options: [], range: fullRange)
                
                for match in matches {
                    let groupRange = match.range(at: 1)
                    let startStarRange = NSRange(location: match.range.location, length: 2)
                    let endStarRange = NSRange(location: match.range.location + match.range.length - 2, length: 2)
                    
                    // Make interior text bold
                    storage.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 14), range: groupRange)
                    
                    // Always Hide stars: transparent, tiny font, and negative kerning to collapse space
                    storage.addAttribute(.foregroundColor, value: NSColor.clear, range: startStarRange)
                    storage.addAttribute(.foregroundColor, value: NSColor.clear, range: endStarRange)
                    storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 0.01), range: startStarRange)
                    storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 0.01), range: endStarRange)
                    
                    // Attempt to collapse the space occupied by the hidden characters
                    // Note: Kern value is points of spacing after the character.
                    storage.addAttribute(.kern, value: -8.0, range: startStarRange)
                    storage.addAttribute(.kern, value: -8.0, range: endStarRange)
                }
            }
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            // Note: We don't need to re-apply styles on selection change anymore 
            // if we are hiding them permanently.
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
            applyStyles(to: textView)
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Drag and Drop Delegates

struct FolderDropDelegate: DropDelegate {
    let folder: Folder
    let store: NoteStore
    @Binding var draggedFolder: Folder?
    @Binding var isTargeted: Bool
    
    func dropEntered(info: DropInfo) {
        if draggedFolder?.id != folder.id {
            isTargeted = true
        }
        guard let dragged = draggedFolder, dragged.id != folder.id else { return }
        guard let from = store.folders.firstIndex(where: { $0.id == dragged.id }),
              let to = store.folders.firstIndex(where: { $0.id == folder.id }) else { return }
              
        if from != to {
            store.moveFolder(draggedId: dragged.id, targetId: folder.id)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    func dropExited(info: DropInfo) {
        isTargeted = false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedFolder = nil
        isTargeted = false
        return true
    }
}

struct NoteDropDelegate: DropDelegate {
    let note: Note
    let store: NoteStore
    @Binding var draggedNote: Note?
    @Binding var isTargeted: Bool

    func dropEntered(info: DropInfo) {
        if draggedNote?.id != note.id {
            isTargeted = true
        }
        guard let dragged = draggedNote, dragged.id != note.id else { return }
        let folderNotes = store.notes.filter { $0.folderId == store.selectedFolderId }
        guard let from = folderNotes.firstIndex(where: { $0.id == dragged.id }),
              let to = folderNotes.firstIndex(where: { $0.id == note.id }) else { return }
              
        if from != to {
            store.moveNote(draggedId: dragged.id, targetId: note.id)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    func dropExited(info: DropInfo) {
        isTargeted = false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedNote = nil
        isTargeted = false
        return true
    }
}
