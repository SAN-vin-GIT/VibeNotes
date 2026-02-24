import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var folderId: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String = "New Note", content: String = "", folderId: UUID? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.folderId = folderId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct Folder: Identifiable, Codable {
    let id: UUID
    var name: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()
    }
}
