import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = NotesyDataManager()
    @State private var selectedTab = 0
    @State private var selectedNoteID: UUID?
    @State private var gradientRotation = 0.0
    @Namespace private var containerNamespace

    var body: some View {
        ZStack {
            AngularGradient(colors: dataManager.theme.colors, center: .center, angle: .degrees(gradientRotation))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 1: WidgetPickerView(dataManager: dataManager)
                    case 2: SettingsView(dataManager: dataManager)
                    default: NotesView(dataManager: dataManager, selectedNoteID: $selectedNoteID, namespace: containerNamespace)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                GlassTabBar(selection: $selectedTab)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
            }
        }
        .onAppear {
            selectedNoteID = selectedNoteID ?? dataManager.notes.first?.id
            withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
    }
}

private struct NotesView: View {
    @ObservedObject var dataManager: NotesyDataManager
    @Binding var selectedNoteID: UUID?
    var namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes").font(.largeTitle.bold())
                    Text("A quiet place for the things worth keeping.")
                        .foregroundStyle(.white.opacity(0.68))
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedNoteID = dataManager.addNote()
                    }
                } label: {
                    Image(systemName: "plus").font(.headline.bold()).frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.16), in: Circle())
            }

            ScrollView {
                GlassEffectContainer(spacing: 24) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(dataManager.notes) { note in
                            NoteCard(note: note, isSelected: selectedNoteID == note.id, isWidgetNote: dataManager.selectedWidgetNoteID == note.id) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    selectedNoteID = note.id
                                }
                            } delete: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    dataManager.deleteNote(id: note.id)
                                    if selectedNoteID == note.id { selectedNoteID = dataManager.notes.first?.id }
                                }
                            }
                            .glassEffectID(note.id, in: namespace)
                            .transition(.blurReplace.combined(with: .scale))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: dataManager.notes)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .sheet(item: Binding<NotesyNote?>(get: {
            selectedNoteID.flatMap { dataManager.note(for: $0) }
        }, set: { value in
            if value == nil { selectedNoteID = nil }
        })) { note in
            NoteEditor(note: note, dataManager: dataManager)
        }
    }
}

private struct NoteCard: View {
    let note: NotesyNote
    let isSelected: Bool
    let isWidgetNote: Bool
    let select: () -> Void
    let delete: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(note.title.isEmpty ? "Untitled note" : note.title).font(.headline).lineLimit(2)
                    Spacer(minLength: 4)
                    if isWidgetNote { Image(systemName: "pin.fill").font(.caption).foregroundStyle(.yellow) }
                }
                Text(note.text.isEmpty ? "Empty note" : note.text)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .liquidGlass() // Now maps to .glassEffect
        .aspectRatio(1, contentMode: .fit)
        .opacity(isSelected ? 1 : 0.8)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .contextMenu {
            Button(role: .destructive, action: delete) { Label("Delete Note", systemImage: "trash") }
        }
    }
}

struct NoteEditor: View {
    let note: NotesyNote
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: NotesyDataManager

    private var currentNote: NotesyNote {
        dataManager.note(for: note.id) ?? note
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AngularGradient(colors: dataManager.theme.colors, center: .center, angle: .degrees(45)).ignoresSafeArea()
                VStack(spacing: 0) {
                    TextField("Note title", text: Binding(
                        get: { currentNote.title },
                        set: { value in dataManager.updateNote(id: note.id, title: value) }
                    ))
                    .font(.title3.bold())
                    .textFieldStyle(.plain)
                    .padding(20)

                    TextEditor(text: Binding(
                        get: { currentNote.text },
                        set: { value in dataManager.updateNote(id: note.id, text: value) }
                    ))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .tint(.white)
                    .font(.system(size: currentNote.fontSize, weight: currentNote.isBold ? .bold : .regular))
                    .italic(currentNote.isItalic)
                    .padding(14)
                }
                .foregroundStyle(.white)
                .liquidGlass()
                .padding(20)
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Menu {
                        Button("Body") { dataManager.updateFormatting(id: note.id, headingLevel: 0) }
                        Button("Heading 1") { dataManager.updateFormatting(id: note.id, fontSize: 28, headingLevel: 1) }
                        Button("Heading 2") { dataManager.updateFormatting(id: note.id, fontSize: 23, headingLevel: 2) }
                        Button("Heading 3") { dataManager.updateFormatting(id: note.id, fontSize: 20, headingLevel: 3) }
                    } label: { Label("Style", systemImage: "textformat.size") }
                    Menu {
                        Button("14 pt") { dataManager.updateFormatting(id: note.id, fontSize: 14) }
                        Button("18 pt") { dataManager.updateFormatting(id: note.id, fontSize: 18) }
                        Button("24 pt") { dataManager.updateFormatting(id: note.id, fontSize: 24) }
                        Button("32 pt") { dataManager.updateFormatting(id: note.id, fontSize: 32) }
                    } label: { Label("Size", systemImage: "textformat") }
                    Button { dataManager.updateFormatting(id: note.id, isBold: !currentNote.isBold) } label: { // fixed typo in below lines?
                        Image(systemName: "bold").foregroundStyle(currentNote.isBold ? .yellow : .white)
                    }
                    Button { dataManager.updateFormatting(id: note.id, isItalic: !currentNote.isItalic) } label: {
                        Image(systemName: "italic").foregroundStyle(currentNote.isItalic ? .yellow : .white)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct WidgetPickerView: View {
    @ObservedObject var dataManager: NotesyDataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Widget").font(.largeTitle.bold())
            Text("Choose the note shown on your Home Screen.")
                .foregroundStyle(.white.opacity(0.68))

            VStack(alignment: .leading, spacing: 8) {
                Text("Displayed note").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.62))
                Picker("Displayed note", selection: Binding(get: { dataManager.selectedWidgetNoteID }, set: { value in dataManager.selectWidgetNote(value) })) {
                    ForEach(dataManager.notes) { note in
                        Text(note.title.isEmpty ? "Untitled note" : note.title).tag(note.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)
            }
            .padding(16)
            .liquidGlass()

            if let note = dataManager.note(for: dataManager.selectedWidgetNoteID) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Live preview", systemImage: "pin.fill").font(.headline)
                    Text(note.text.isEmpty ? "Tap to write a note in Notesy." : note.text)
                        .font(.title3.weight(.medium)).lineLimit(8).minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                }
                .padding(18)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                .id(note.id) // trigger animation on change
                .liquidGlass()
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: dataManager.selectedWidgetNoteID)
    }
}

private struct SettingsView: View {
    @ObservedObject var dataManager: NotesyDataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Settings").font(.largeTitle.bold())
            Text("Make Notesy feel like yours.").foregroundStyle(.white.opacity(0.68))
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme").font(.headline)
                Picker("Theme", selection: Binding(get: { dataManager.theme }, set: { value in
                    withAnimation(.easeInOut(duration: 0.4)) { dataManager.setTheme(value) }
                })) {
                    ForEach(NotesyTheme.allCases) { theme in Text(theme.title).tag(theme) }
                }
                .pickerStyle(.segmented)
                .tint(.white)
                .padding(8)
                .liquidGlass()

                HStack(spacing: 14) {
                    LinearGradient(colors: dataManager.theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dataManager.theme.title).font(.headline)
                        Text(dataManager.theme.subtitle).font(.caption).foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(16)
                .liquidGlass()
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.top, 20)
    }
}

private struct GlassTabBar: View {
    @Binding var selection: Int
    private let tabs = [("note.text", "Notes"), ("widget.small", "Widget"), ("slider.horizontal.3", "Settings")]
    private let selectedColors: [Color] = [.cyan, .mint, .orange]
    @Namespace private var namespace

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(tabs.indices, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selection = index
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tabs[index].0)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(selection == index ? selectedColors[index] : .white.opacity(0.78))
                                .shadow(color: selection == index ? selectedColors[index].opacity(0.45) : .clear, radius: 8)
                            Text(tabs[index].1).font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(selection == index ? 1 : 0.78))
                        }
                        .scaleEffect(selection == index ? 1.08 : 1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selection == index {
                                Color.clear
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .glassEffect(.regular.tint(.white.opacity(0.08)).interactive(), in: Capsule())
                                    .glassEffectID("selectedTab", in: namespace)
                                    .glassEffectTransition(.matchedGeometry)
                                    .matchedGeometryEffect(id: "selectedTabPosition", in: namespace)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: selection)
        .padding(4)
        .background(.ultraThinMaterial.opacity(0.28), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .frame(maxWidth: 520)
    }
}

#Preview {
    ContentView()
}
