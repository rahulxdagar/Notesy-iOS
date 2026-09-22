//
//  AppIntent.swift
//  NotesyWidget
//
//  Created by Rahul Dagar on 2026-09-22.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Choose a Note" }
    static var description: IntentDescription { "Choose which Notesy note appears in this widget." }

    @Parameter(title: "Note")
    var note: NoteEntity?
}

struct NoteEntity: AppEntity, Identifiable {
    let id: UUID
    let title: String
    let snippet: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Notesy Note"
    static var defaultQuery = NoteEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(snippet)",
            subtitle: "\(title)"
        )
    }
}

struct NoteEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [NoteEntity] {
        loadNotes().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [NoteEntity] {
        loadNotes()
    }

    func defaultResult() async -> NoteEntity? {
        loadNotes().first
    }

    private func loadNotes() -> [NoteEntity] {
        let defaults = UserDefaults(suiteName: "group.com.rahuldagar.Notesy")
        guard let data = defaults?.data(forKey: "notes"),
              let notes = try? JSONDecoder().decode([WidgetNoteOption].self, from: data) else {
            return []
        }

        return notes.map {
            NoteEntity(
                id: $0.id,
                title: $0.title.isEmpty ? "Untitled note" : $0.title,
                snippet: $0.text.isEmpty ? "Empty note" : $0.text.wordsPrefix
            )
        }
    }
}

private struct WidgetNoteOption: Codable {
    let id: UUID
    let title: String
    let text: String
}

private extension String {
    var wordsPrefix: String {
        let words = split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        let prefix = words.prefix(8).joined(separator: " ")
        return words.count > 8 ? "\(prefix)..." : prefix
    }
}
