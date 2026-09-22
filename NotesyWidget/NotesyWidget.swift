//
//  NotesyWidget.swift
//  NotesyWidget
//
//  Created by Rahul Dagar on 2026-09-22.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            noteTitle: "Untitled note",
            noteText: "Tap to write a note in Notesy.",
            fontSize: 18,
            isBold: false,
            isItalic: false,
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let (title, text, fontSize, isBold, isItalic) = sharedNote(for: configuration.note?.id.uuidString)
        return SimpleEntry(
            date: Date(),
            noteTitle: title,
            noteText: text,
            fontSize: fontSize,
            isBold: isBold,
            isItalic: isItalic,
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date()
        let (title, text, fontSize, isBold, isItalic) = sharedNote(for: configuration.note?.id.uuidString)
        let entry = SimpleEntry(
            date: currentDate,
            noteTitle: title,
            noteText: text,
            fontSize: fontSize,
            isBold: isBold,
            isItalic: isItalic,
            configuration: configuration
        )

        return Timeline(entries: [entry], policy: .never)
    }

    private func sharedNote(for configuredNoteID: String?) -> (String, String, Double, Bool, Bool) {
        let defaults = UserDefaults(suiteName: "group.com.rahuldagar.Notesy")
        if let data = defaults?.data(forKey: "notes"),
           let notes = try? JSONDecoder().decode([WidgetNote].self, from: data),
           !notes.isEmpty {
            let selectedID = configuredNoteID ?? defaults?.string(forKey: "selectedWidgetNoteID")
            let selectedNote = selectedID.flatMap { id in
                notes.first(where: { $0.id.uuidString == id })
            } ?? notes[0]
            
            let displayTitle = selectedNote.title.isEmpty ? "Untitled note" : selectedNote.title
            let displayText = selectedNote.text.isEmpty ? "Tap to write a note in Notesy." : selectedNote.text
            return (displayTitle, displayText, selectedNote.fontSize, selectedNote.isBold, selectedNote.isItalic)
        }

        let legacyNote = defaults?.string(forKey: "sharedNote") ?? ""
        return ("Untitled note", legacyNote.isEmpty ? "Tap to write a note in Notesy." : legacyNote, 18, false, false)
    }
}

private struct WidgetNote: Codable {
    let id: UUID
    let title: String
    let text: String
    let fontSize: Double
    let isBold: Bool
    let isItalic: Bool

    init(id: UUID, title: String, text: String, fontSize: Double = 18, isBold: Bool = false, isItalic: Bool = false) {
        self.id = id
        self.title = title
        self.text = text
        self.fontSize = fontSize
        self.isBold = isBold
        self.isItalic = isItalic
    }

    enum CodingKeys: String, CodingKey { case id, title, text, fontSize, isBold, isItalic }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        text = try values.decode(String.self, forKey: .text)
        fontSize = try values.decodeIfPresent(Double.self, forKey: .fontSize) ?? 18
        isBold = try values.decodeIfPresent(Bool.self, forKey: .isBold) ?? false
        isItalic = try values.decodeIfPresent(Bool.self, forKey: .isItalic) ?? false
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let noteTitle: String
    let noteText: String
    let fontSize: Double
    let isBold: Bool
    let isItalic: Bool
    let configuration: ConfigurationAppIntent
}

struct NotesyWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.noteTitle)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(entry.noteText)
                .font(.system(size: entry.fontSize, weight: entry.isBold ? .bold : .medium))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .italic(entry.isItalic)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
    }
}

struct NotesyWidget: Widget {
    let kind: String = "NotesyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            NotesyWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    AngularGradient(
                        colors: themeColors(),
                        center: .center,
                        angle: .degrees(45)
                    )
                    .ignoresSafeArea()
                }
        }
        .supportedFamilies([.systemLarge, .systemSmall, .systemMedium])
    }

    private func themeColors() -> [Color] {
        let theme = UserDefaults(suiteName: "group.com.rahuldagar.Notesy")?.string(forKey: "theme") ?? "midnight"
        switch theme {
        case "aurora":
            return [Color(red: 0.01, green: 0.08, blue: 0.12), Color(red: 0.05, green: 0.75, blue: 0.68)]
        case "ember":
            return [Color(red: 0.10, green: 0.02, blue: 0.10), Color(red: 0.95, green: 0.28, blue: 0.24)]
        default:
            return [Color(red: 0.01, green: 0.02, blue: 0.06), Color(red: 0.12, green: 0.34, blue: 0.85)]
        }
    }
}

private struct WidgetLiquidGlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.3), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    .allowsHitTesting(false)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

private extension View {
    func liquidGlass() -> some View {
        modifier(WidgetLiquidGlassEffect())
    }
}

#Preview(as: .systemLarge) {
    NotesyWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        noteTitle: "My Note",
        noteText: "A note preview",
        fontSize: 18,
        isBold: false,
        isItalic: false,
        configuration: ConfigurationAppIntent()
    )
}
