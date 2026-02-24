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
                    } preview: {
                        FolderIconView(name: folder.name, isSelected: true)
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
        ScrollView(showsIndicators: false) {
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
                            .lineLimit(1)
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
                                Image(systemName: "bold")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                NotificationCenter.default.post(name: Notification.Name("UnderlineSelectedText"), object: note.id)
                            }) {
                                Image(systemName: "underline")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                NotificationCenter.default.post(name: Notification.Name("StrikethroughSelectedText"), object: note.id)
                            }) {
                                Image(systemName: "strikethrough")
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
        
        context.coordinator.setupNotifications(for: textView)
        
        textView.font = .systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 0, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.focusRingType = .none
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if context.coordinator.isUpdating { return }
        
        let currentMarkdown = nsView.attributedString().toMarkdown()
        if currentMarkdown != text {
            context.coordinator.isUpdating = true
            let attrStr = text.toMarkdownAttributedString()
            
            // Clear undo history when switching to a different note to prevent
            // a crash where the undo manager tries to replay actions on a stale context
            nsView.undoManager?.removeAllActions()
            
            nsView.textStorage?.setAttributedString(attrStr)
            // Move cursor to start on note switch (selection no longer valid)
            nsView.setSelectedRange(NSRange(location: 0, length: 0))
            context.coordinator.isUpdating = false
        }
        
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
        private var cancellables = Set<AnyCancellable>()
        var isUpdating = false
        
        init(_ parent: AutoExpandingTextView) {
            self.parent = parent
        }
        
        func setupNotifications(for textView: NSTextView) {
            NotificationCenter.default.publisher(for: Notification.Name("BoldSelectedText"))
                .sink { [weak self, weak textView] notification in
                    guard let self = self, let textView = textView, let noteId = notification.object as? UUID, noteId == self.parent.noteId else { return }
                    self.toggleTrait(in: textView, trait: .bold)
                }
                .store(in: &cancellables)
                
            NotificationCenter.default.publisher(for: Notification.Name("UnderlineSelectedText"))
                .sink { [weak self, weak textView] notification in
                    guard let self = self, let textView = textView, let noteId = notification.object as? UUID, noteId == self.parent.noteId else { return }
                    self.toggleAttribute(in: textView, key: .underlineStyle, value: NSUnderlineStyle.single.rawValue)
                }
                .store(in: &cancellables)
                
            NotificationCenter.default.publisher(for: Notification.Name("StrikethroughSelectedText"))
                .sink { [weak self, weak textView] notification in
                    guard let self = self, let textView = textView, let noteId = notification.object as? UUID, noteId == self.parent.noteId else { return }
                    self.toggleAttribute(in: textView, key: .strikethroughStyle, value: NSUnderlineStyle.single.rawValue)
                }
                .store(in: &cancellables)
        }
        
        private func toggleTrait(in textView: NSTextView, trait: NSFontDescriptor.SymbolicTraits) {
            let range = textView.selectedRange()
            guard range.length > 0, let storage = textView.textStorage else { return }
            
            let currentFont = storage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
            let hasTrait = currentFont?.fontDescriptor.symbolicTraits.contains(trait) == true
            
            storage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                var newFont = NSFont.systemFont(ofSize: 14)
                if !hasTrait {
                    newFont = NSFont.boldSystemFont(ofSize: 14)
                }
                storage.addAttribute(.font, value: newFont, range: subrange)
            }
            textView.didChangeText()
        }
        
        private func toggleAttribute(in textView: NSTextView, key: NSAttributedString.Key, value: Any) {
            let range = textView.selectedRange()
            guard range.length > 0, let storage = textView.textStorage else { return }
            
            let hasAttr = storage.attribute(key, at: range.location, effectiveRange: nil) != nil
            
            if hasAttr {
                storage.removeAttribute(key, range: range)
            } else {
                storage.addAttribute(key, value: value, range: range)
            }
            textView.didChangeText()
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            self.parent.text = textView.attributedString().toMarkdown()
            isUpdating = false
        }
    }
}

extension NSAttributedString {
    func toMarkdown() -> String {
        var result = ""
        self.enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { attrs, range, _ in
            var textSegment = (self.string as NSString).substring(with: range)
            
            let isBold = (attrs[.font] as? NSFont)?.fontDescriptor.symbolicTraits.contains(.bold) == true
            let isUnderline = attrs[.underlineStyle] != nil
            let isStrikethrough = attrs[.strikethroughStyle] != nil
            
            if isStrikethrough { textSegment = "~~" + textSegment + "~~" }
            if isUnderline { textSegment = "__" + textSegment + "__" }
            if isBold { textSegment = "**" + textSegment + "**" }
            
            result += textSegment
        }
        
        return result
    }
}

extension String {
    func toMarkdownAttributedString() -> NSMutableAttributedString {
        let normalFont = NSFont.systemFont(ofSize: 14)
        let attrString = NSMutableAttributedString(string: self, attributes: [.font: normalFont, .foregroundColor: NSColor.labelColor])

        func applyMarkdown(pattern: String, key: NSAttributedString.Key, value: Any) {
            while let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
                  let match = regex.firstMatch(in: attrString.string, options: [], range: NSRange(location: 0, length: attrString.length)) {
                
                let innerRange = match.range(at: 1)
                let innerText = attrString.attributedSubstring(from: innerRange)
                
                let replacement = NSMutableAttributedString(attributedString: innerText)
                replacement.addAttribute(key, value: value, range: NSRange(location: 0, length: replacement.length))
                
                attrString.replaceCharacters(in: match.range, with: replacement)
            }
        }
        
        applyMarkdown(pattern: "\\*\\*(.*?)\\*\\*", key: .font, value: NSFont.boldSystemFont(ofSize: 14))
        applyMarkdown(pattern: "__(.*?)__", key: .underlineStyle, value: NSUnderlineStyle.single.rawValue)
        applyMarkdown(pattern: "~~(.*?)~~", key: .strikethroughStyle, value: NSUnderlineStyle.single.rawValue)
        
        return attrString
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
