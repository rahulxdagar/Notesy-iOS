import SwiftUI
import Combine
import WidgetKit

struct NotesyNote: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var text: String
    var updatedAt: Date
    var fontSize: Double
    var isBold: Bool
    var isItalic: Bool
    var headingLevel: Int

    init(id: UUID = UUID(), title: String = "Untitled note", text: String = "", fontSize: Double = 18, isBold: Bool = false, isItalic: Bool = false, headingLevel: Int = 0) {
        self.id = id
        self.title = title
        self.text = text
        updatedAt = Date()
        self.fontSize = fontSize
        self.isBold = isBold
        self.isItalic = isItalic
        self.headingLevel = headingLevel
    }

    enum CodingKeys: String, CodingKey {
        case id, title, text, updatedAt, fontSize, isBold, isItalic, headingLevel
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        text = try values.decode(String.self, forKey: .text)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
        fontSize = try values.decodeIfPresent(Double.self, forKey: .fontSize) ?? 18
        isBold = try values.decodeIfPresent(Bool.self, forKey: .isBold) ?? false
        isItalic = try values.decodeIfPresent(Bool.self, forKey: .isItalic) ?? false
        headingLevel = try values.decodeIfPresent(Int.self, forKey: .headingLevel) ?? 0
    }
}

enum NotesyTheme: String, CaseIterable, Codable, Identifiable {
    case midnight
    case aurora
    case ember

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midnight: "Midnight"
        case .aurora: "Aurora"
        case .ember: "Ember"
        }
    }

    var subtitle: String {
        switch self {
        case .midnight: "Ink and electric blue"
        case .aurora: "Deep teal and cool cyan"
        case .ember: "Plum and warm coral"
        }
    }

    var colors: [Color] {
        switch self {
        case .midnight: [Color(red: 0.01, green: 0.02, blue: 0.06), Color(red: 0.12, green: 0.34, blue: 0.85)]
        case .aurora: [Color(red: 0.01, green: 0.08, blue: 0.12), Color(red: 0.05, green: 0.75, blue: 0.68)]
        case .ember: [Color(red: 0.10, green: 0.02, blue: 0.10), Color(red: 0.95, green: 0.28, blue: 0.24)]
        }
    }
}

final class NotesyDataManager: ObservableObject {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.rahuldagar.Notesy")!
    private let notesKey = "notes"
    private let selectedNoteKey = "selectedWidgetNoteID"
    private let themeKey = "theme"

    @Published var notes: [NotesyNote]
    @Published var selectedWidgetNoteID: UUID
    @Published var theme: NotesyTheme

    init() {
        var loadedNotes = Self.loadNotes(from: sharedDefaults)
        if loadedNotes.isEmpty {
            let legacyText = sharedDefaults.string(forKey: "sharedNote") ?? ""
            loadedNotes = [NotesyNote(title: "First note", text: legacyText)]
        }

        if let savedID = sharedDefaults.string(forKey: selectedNoteKey),
           let id = UUID(uuidString: savedID),
           loadedNotes.contains(where: { $0.id == id }) {
            selectedWidgetNoteID = id
        } else {
            selectedWidgetNoteID = loadedNotes[0].id
        }

        notes = loadedNotes
        theme = NotesyTheme(rawValue: sharedDefaults.string(forKey: themeKey) ?? "") ?? .midnight
        persistNotes()
    }

    func addNote() -> UUID {
        let note = NotesyNote(title: "New note")
        notes.insert(note, at: 0)
        persistNotes()
        return note.id
    }

    func deleteNotes(at offsets: IndexSet) {
        let deletedIDs = offsets.map { notes[$0].id }
        notes.remove(atOffsets: offsets)
        if notes.isEmpty {
            notes = [NotesyNote(title: "First note")]
        }
        if deletedIDs.contains(selectedWidgetNoteID) {
            selectedWidgetNoteID = notes[0].id
        }
        persistNotes()
    }

    func deleteNote(id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes.remove(at: index)
        if notes.isEmpty {
            notes = [NotesyNote(title: "First note")]
        }
        if id == selectedWidgetNoteID {
            selectedWidgetNoteID = notes[0].id
        }
        persistNotes()
    }

    func updateNote(id: UUID, title: String? = nil, text: String? = nil) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        if let title { notes[index].title = title }
        if let text { notes[index].text = text }
        notes[index].updatedAt = Date()
        persistNotes()
    }

    func updateFormatting(id: UUID, fontSize: Double? = nil, isBold: Bool? = nil, isItalic: Bool? = nil, headingLevel: Int? = nil) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        if let fontSize { notes[index].fontSize = fontSize }
        if let isBold { notes[index].isBold = isBold }
        if let isItalic { notes[index].isItalic = isItalic }
        if let headingLevel { notes[index].headingLevel = headingLevel }
        notes[index].updatedAt = Date()
        persistNotes()
    }

    func selectWidgetNote(_ id: UUID) {
        guard notes.contains(where: { $0.id == id }) else { return }
        selectedWidgetNoteID = id
        sharedDefaults.set(id.uuidString, forKey: selectedNoteKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func setTheme(_ theme: NotesyTheme) {
        self.theme = theme
        sharedDefaults.set(theme.rawValue, forKey: themeKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func note(for id: UUID) -> NotesyNote? {
        notes.first(where: { $0.id == id })
    }

    private func persistNotes() {
        if let data = try? JSONEncoder().encode(notes) {
            sharedDefaults.set(data, forKey: notesKey)
        }
        sharedDefaults.set(selectedWidgetNoteID.uuidString, forKey: selectedNoteKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func loadNotes(from defaults: UserDefaults) -> [NotesyNote] {
        guard let data = defaults.data(forKey: "notes"),
              let notes = try? JSONDecoder().decode([NotesyNote].self, from: data) else {
            return []
        }
        return notes
    }
}
