//  SettingsRootView.swift
//  Reading Tracker
//
//  ROADMAP 1.2a/1.2b (RA-002 / NA-2): the app previously had NO reachable way
//  to create goals or deadlines — DataStore.updateGoalSet/addDeadline had zero
//  callers and GoalsDashboard's empty state pointed at nonexistent "app settings."
//  This window is that missing creation surface.
//
//  DESIGN CONTRACT
//  • The shell is generic (tabs) so future settings panes (e.g. LT-9 symbol color)
//    drop in without restructuring.
//  • The goal editor binds ONLY to DataStore's existing, already-persisted API:
//      updateGoalSet(_:)      → library-state.json (immediate, non-debounced save)
//      addDeadline(_:)        → same file, replaces any deadline for the same book
//      removeDeadline(bookID:)
//    No new persistence path is introduced anywhere in this file.
//  • GoalProgressViewModel refreshes itself by observing $libraryState (see its
//    bind(to:) — roadmap 1.2b companion change), so the dashboard updates live
//    after saving here.

import SwiftUI

// MARK: - Settings Root

struct SettingsRootView: View {
    @EnvironmentObject private var dataStore: DataStore

    var body: some View {
        TabView {
            GoalEditorPane()
                .tabItem {
                    Label("Reading Goals", systemImage: "target")
                }

            DeadlineEditorPane()
                .tabItem {
                    Label("Deadlines", systemImage: "calendar.badge.clock")
                }

            RSVPSettingsPane()
                .tabItem {
                    Label("Speed Reading", systemImage: "hare")
                }

            SentinelSettingsPane()
                .tabItem {
                    Label("Sentinel", systemImage: "shield.lefthalf.filled")
                }
        }
        .padding(20)
        .frame(minWidth: 560, minHeight: 430)
        .navigationTitle("Settings")
    }
}

// MARK: - Goal Editor Pane (roadmap 1.2b)

struct GoalEditorPane: View {
    @EnvironmentObject private var dataStore: DataStore

    // Local editing state — seeded from the persisted set, committed on Save.
    @State private var dailyPagesEnabled = false
    @State private var dailyPages = 20

    @State private var dailyMinutesEnabled = false
    @State private var dailyMinutes = 30

    @State private var annualBooksEnabled = false
    @State private var annualBooks = 12

    @State private var weeklyDaysEnabled = false
    @State private var weeklyDays = 5

    @State private var savedFlash = false

    var body: some View {
        Form {
            Section("Daily Targets") {
                Toggle("Daily page target", isOn: $dailyPagesEnabled)
                if dailyPagesEnabled {
                    Stepper("\(dailyPages) pages", value: $dailyPages, in: 1 ... 1000)
                }

                Toggle("Daily time target", isOn: $dailyMinutesEnabled)
                if dailyMinutesEnabled {
                    Stepper("\(dailyMinutes) minutes", value: $dailyMinutes, in: 5 ... 480)
                        .onChange(of: dailyMinutes) { _, newValue in
                            // Snap to friendly 5-minute increments while stepping.
                            dailyMinutes = max(5, newValue - (newValue % 5))
                        }
                }
            }

            Section("Longer Horizon") {
                Toggle("Annual book target", isOn: $annualBooksEnabled)
                if annualBooksEnabled {
                    Stepper("\(annualBooks) books this year", value: $annualBooks, in: 1 ... 365)
                }

                Toggle("Weekly reading days", isOn: $weeklyDaysEnabled)
                if weeklyDaysEnabled {
                    Stepper("\(weeklyDays) days per week", value: $weeklyDays, in: 1 ... 7)
                }
            }

            Section {
                HStack {
                    Button("Save Goals") { commit() }
                        .keyboardShortcut(.defaultAction)
                    if savedFlash {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                            .transition(.opacity)
                    }
                    Spacer()
                    Button("Clear All Goals", role: .destructive) {
                        clearAll()
                    }
                }
            } footer: {
                Text("Changes take effect immediately across Goals, Insights, and Achievements.")
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: seedFromStore)
        // Re-seed when goals change underneath us (e.g. demo-profile reset wipes
        // LibraryState). ReadingGoalSet is Hashable, satisfying onChange's
        // Equatable requirement without widening LibraryState's conformance set.
        .onChange(of: dataStore.libraryState.goalSet) { _, _ in
            seedFromStore()
        }
    }

    private func seedFromStore() {
        let set = dataStore.libraryState.goalSet
        dailyPagesEnabled = set.dailyPageTarget != nil
        dailyPages = set.dailyPageTarget ?? 20
        dailyMinutesEnabled = set.dailyTimeTarget != nil
        dailyMinutes = Int((set.dailyTimeTarget ?? 1800) / 60)
        annualBooksEnabled = set.annualBookTarget != nil
        annualBooks = set.annualBookTarget ?? 12
        weeklyDaysEnabled = set.weeklyReadingDays != nil
        weeklyDays = set.weeklyReadingDays ?? 5
    }

    private func commit() {
        var set = ReadingGoalSet.empty
        set.dailyPageTarget = dailyPagesEnabled ? dailyPages : nil
        set.dailyTimeTarget = dailyMinutesEnabled ? TimeInterval(dailyMinutes * 60) : nil
        set.annualBookTarget = annualBooksEnabled ? annualBooks : nil
        set.weeklyReadingDays = weeklyDaysEnabled ? weeklyDays : nil
        dataStore.updateGoalSet(set)

        withAnimation(.easeOut(duration: 0.4)) { savedFlash = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation { savedFlash = false }
        }
    }

    private func clearAll() {
        dataStore.updateGoalSet(.empty)
        seedFromStore()
    }
}

// MARK: - Deadline Editor Pane (roadmap 1.2b — per-book finish-by dates)

struct DeadlineEditorPane: View {
    @EnvironmentObject private var dataStore: DataStore

    @State private var selectedBookID: UUID?
    @State private var targetDate = Date().addingTimeInterval(30 * 86_400)
    @State private var reminderEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Finish-by dates per book")
                .font(.headline)

            if dataStore.books.isEmpty {
                ContentUnavailableView(
                    "No Books",
                    systemImage: "books.vertical",
                    description: Text("Import a book first — deadlines track individual titles.")
                )
            } else {
                addForm
                deadlineList
            }
        }
        .padding(4)
    }

    private var addForm: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Picker("Book", selection: $selectedBookID) {
                Text("Choose a book…").tag(UUID?.none)
                ForEach(dataStore.books.sorted { $0.title < $1.title }) { book in
                    Text(book.title).tag(UUID?.some(book.id))
                }
            }
            .frame(minWidth: 240)

            DatePicker("Finish by", selection: $targetDate, displayedComponents: .date)

            Toggle("Remind", isOn: $reminderEnabled)
                .toggleStyle(.checkbox)

            Button("Add Deadline") { addDeadline() }
                .disabled(selectedBookID == nil)
        }
    }

    private var deadlineList: some View {
        let deadlines = dataStore.libraryState.deadlines
            .sorted { $0.targetDate < $1.targetDate }

        return List {
            ForEach(deadlines) { deadline in
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(color(for: deadline))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(bookTitle(for: deadline.bookID))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(formatted(deadline.targetDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if deadline.reminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        dataStore.removeDeadline(bookID: deadline.bookID)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Remove deadline")
                }
                .padding(.vertical, 2)
            }
        }
        .frame(minHeight: 200)
        .overlay {
            if deadlines.isEmpty {
                Text("No deadlines yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func addDeadline() {
        guard let bookID = selectedBookID else { return }
        // Normalize to end-of-day so "finish by Jun 30" includes June 30 itself.
        let endOfDay = Calendar.current.startOfDay(for: targetDate).addingTimeInterval(86_399)
        dataStore.addDeadline(BookDeadline(
            bookID: bookID,
            targetDate: endOfDay,
            reminderEnabled: reminderEnabled
        ))
    }

    // MARK: Helpers

    private func bookTitle(for id: UUID) -> String {
        dataStore.book(id: id)?.title ?? "Unknown book"
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .long, time: .omitted)
    }

    private func color(for deadline: BookDeadline) -> Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline.targetDate).day ?? 0
        if days < 0 { return .red }
        if days <= 7 { return .orange }
        return .accentColor
    }
}


// MARK: - RSVP Settings (P5 Feature 3 — plan §4: single toggle + WPM)

struct RSVPSettingsPane: View {
    @AppStorage("rsvp.enabled") private var isEnabled = true
    @AppStorage("rsvp.wpm") private var wordsPerMinute: Double = 300

    var body: some View {
        Form {
            Section {
                Toggle("Show Speed Read controls in readers", isOn: $isEnabled)
            } footer: {
                Text("RSVP streams one word at a time at a fixed point, removing eye travel. Great for articles and re-reading; comprehension research suggests treating it as a complement to normal reading, not a replacement.")
            }

            if isEnabled {
                Section("Default Speed") {
                    Slider(value: $wordsPerMinute, in: 150 ... 800, step: 25) {
                        Text("Words per minute")
                    } minimumValueLabel: {
                        Text("150")
                    } maximumValueLabel: {
                        Text("800")
                    }
                    Text("\(Int(wordsPerMinute)) WPM")
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
        .formStyle(.grouped)
    }
}


// MARK: - Sentinel Settings (P6)

struct SentinelSettingsPane: View {
    @AppStorage(SentinelEngine.enabledKey) private var isEnabled = true
    @AppStorage(SentinelEngine.allowRepairKey) private var allowRepair = false
    @AppStorage(SentinelEngine.intervalKey) private var intervalMinutes = 15

    var body: some View {
        Form {
            Section(
                header: Text("Watchdog"),
                footer: Text("Sentinel quietly checks your library's health — corrupted timings, stuck sessions, failing saves, low disk — and journals what it finds.")
            ) {
                Toggle("Enable Sentinel monitoring", isOn: $isEnabled)
                if isEnabled {
                    Picker("Check every", selection: $intervalMinutes) {
                        Text("5 minutes").tag(5)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("60 minutes").tag(60)
                    }
                }
            }

            #if !DEBUG
            Section(
                header: Text("Automatic Repairs"),
                footer: Text("When on, provably-safe repairs run automatically (a backup is always taken first). When off, Sentinel only reports and waits for you. Developers: Debug builds always repair.")
            ) {
                Toggle("Allow automatic fixes", isOn: $allowRepair)
            }
            #endif

            Section("Privacy") {
                Label("No reading data ever leaves this Mac", systemImage: "lock.shield")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
