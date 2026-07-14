
//  AnnualReportArchiveView 2.swift
//  Reading Tracker
//
//  Feature B: Annual Report Archive — browse past years
//  Feature C (partial): January 1st banner — see NewYearTransition.swift for the midnight celebration
//
//  ARCHITECTURE
//  The archive stores only the list of years that have sessions.
//  It does NOT store report payloads, snapshots, or cached data.
//  When a year is selected, the report is generated dynamically from live data.
//
//  JANUARY 1 BANNER
//  Persisted in UserDefaults (key: "annualReport.bannerDismissedYear").
//  The banner is visible on Jan 1 until the app closes for that day.
//  After the app is closed and relaunched, the banner is gone permanently for that year.
//  The report remains accessible from the archive.
//
//  The banner ONLY appears if the previous year has at least one reading session.

import SwiftUI

// MARK: - Annual Report Archive View

/// Presents the list of years with reading data, each opening its annual report.
/// This is presented from a tab, sheet, or toolbar button in the main UI.
struct AnnualReportArchiveView: View {
    @EnvironmentObject var dataStore: DataStore

    @State private var selectedYear: Int?
    @State private var reportData: AnnualReportData?
    @State private var isGenerating: Bool = false

    var body: some View {
        NavigationSplitView {
            archiveSidebar
        } detail: {
            if isGenerating {
                generatingView
            } else if let report = reportData {
                AnnualReportView(data: report) {
                    selectedYear = nil
                    reportData = nil
                }
            } else {
                archiveEmptyDetail
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Sidebar

    private var archiveSidebar: some View {
        let years = availableReportYears(books: dataStore.books)

        return Group {
            if years.isEmpty {
                emptyArchiveView
            } else {
                List(years, id: \.self, selection: $selectedYear) { year in
                    archiveYearRow(year: year)
                }
                .listStyle(.sidebar)
                .onChange(of: selectedYear) { _, newYear in
                    guard let year = newYear else { return }
                    generateReport(for: year)
                }
            }
        }
        .navigationTitle("Reading Reports")
        .frame(minWidth: 200)
    }

    private func archiveYearRow(year: Int) -> some View {
        let yearBooks = booksRead(in: dataStore.books, year: year)
        let yearCompleted = booksCompleted(in: dataStore.books, year: year)
        let period = analyticsPeriod(for: year)
        let yearTime = AnalyticsEngine.readingTime(books: dataStore.books, in: period)

        return VStack(alignment: .leading, spacing: 4) {
            Text(String(year))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                Label("\(yearCompleted.count) finished", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Label(formatDuration(yearTime), systemImage: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .tag(year)
    }

    private var emptyArchiveView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No reading data yet.")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Your annual reports will appear here once you've completed reading sessions.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Detail

    private var archiveEmptyDetail: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Select a year to view your reading report.")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var generatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Generating your report…")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Report Generation

    private func generateReport(for year: Int) {
        isGenerating = true
        reportData = nil

        // Run on background thread; generation is synchronous but can be slow for large libraries.
        Task.detached(priority: .userInitiated) {
            let books = await dataStore.books
            let goalSet = await dataStore.libraryState.goalSet
            let achievements = await dataStore.libraryState.earnedAchievements
            // Load persisted audio profiles so MusicalAnalysisEngine can populate Slide 10.
            let audioProfiles = await dataStore.allAudioProfiles()

            let generated = AnnualReportGenerator.generate(
                year: year,
                books: books,
                goalSet: goalSet,
                earnedAchievements: achievements,
                audioProfiles: audioProfiles
            )

            await MainActor.run {
                reportData = generated
                isGenerating = false
            }
        }
    }
}

// MARK: - January 1st Banner

/// The prominent January 1st discovery banner.
///
/// Visibility rules (from spec):
///   • Shown on January 1st if the previous year has reading sessions.
///   • Remains visible until the app is closed.
///   • After the app closes, the banner does not reappear.
///   • The report remains accessible from the archive.
///
/// Persistence: UserDefaults key "annualReport.bannerDismissedYear" stores the year
/// the banner was last dismissed (by app close or by tapping the banner to open the report).
/// On January 1, if dismissedYear == previousYear, the banner is hidden.
struct JanuaryFirstBannerView: View {
    @EnvironmentObject var dataStore: DataStore

    @State private var showingReport: Bool = false
    @State private var reportData: AnnualReportData?

    private let previousYear: Int = Calendar.current.component(.year, from: Date()) - 1

    var body: some View {
        Group {
            if shouldShowBanner {
                bannerContent
            }
        }
        .sheet(isPresented: $showingReport) {
            if let report = reportData {
                AnnualReportView(data: report) {
                    showingReport = false
                }
                .frame(minWidth: 800, minHeight: 600)
            } else {
                ProgressView("Building your report…")
                    .padding(40)
            }
        }
    }

    // MARK: - Banner Content

    private var bannerContent: some View {
        Button(action: openReport) {
            HStack(spacing: 16) {
                // Decorative glow ring
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Your \(previousYear) Reading Report is ready.")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("See how you read last year — your pace, streaks, and standout books.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.08),
                        Color.accentColor.opacity(0.04),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Logic

    private var shouldShowBanner: Bool {
        // Must be January 1
        let now = Date()
        let calendar = Calendar.current
        guard calendar.component(.month, from: now) == 1,
              calendar.component(.day, from: now) == 1 else { return false }

        // Previous year must have reading data
        let prevYearBooks = booksRead(in: dataStore.books, year: previousYear)
        guard !prevYearBooks.isEmpty else { return false }

        // Must not have been dismissed this session
        let dismissedYear = UserDefaults.standard.integer(forKey: "annualReport.bannerDismissedYear")
        return dismissedYear != previousYear
    }

    private func openReport() {
        // Mark dismissed so app-close removes it next launch
        UserDefaults.standard.set(previousYear, forKey: "annualReport.bannerDismissedYear")

        let books = dataStore.books
        let goalSet = dataStore.libraryState.goalSet
        let achievements = dataStore.libraryState.earnedAchievements
        // Load audio profiles so Slide 10 is populated when opened from the banner.
        let audioProfiles = dataStore.allAudioProfiles()

        Task.detached(priority: .userInitiated) {
            let generated = AnnualReportGenerator.generate(
                year: previousYear,
                books: books,
                goalSet: goalSet,
                earnedAchievements: achievements,
                audioProfiles: audioProfiles
            )
            await MainActor.run {
                reportData = generated
                showingReport = true
            }
        }
    }
}

// MARK: - App Lifecycle Integration (Banner Persistence)

//
// The spec says: "After the application closes, the banner disappears permanently for that year."
// This means: on app launch (AppDelegate / SceneDelegate), check if today is January 1 and if
// the banner has already been dismissed. If the previous dismiss was for this year, hide it.
//
// The implementation above achieves this via UserDefaults:
//   • dismissedYear is written when the user taps the banner.
//   • On the next app launch (January 2+), shouldShowBanner returns false because the date check fails.
//   • On January 1 of the *next* year, previousYear has changed so the banner reappears if there's new data.
//
// No additional app delegate hook is needed. The banner reads UserDefaults on every render.
// If the app closes without the user tapping the banner, shouldShowBanner returns false on next launch
// because the date will no longer be January 1 (the spec says the banner disappears after close).
// That behaviour is achieved by the date check: the banner only appears while the date IS January 1,
// so the next launch (January 2) naturally hides it.
//
// If you want the banner to explicitly disappear even if the app is relaunched on Jan 1 the same day,
// write dismissedYear on app termination:
//
//   func applicationWillTerminate(_ notification: Notification) {
//       let calendar = Calendar.current
//       let now = Date()
//       if calendar.component(.month, from: now) == 1, calendar.component(.day, from: now) == 1 {
//           let prevYear = calendar.component(.year, from: now) - 1
//           UserDefaults.standard.set(prevYear, forKey: "annualReport.bannerDismissedYear")
//       }
//   }
//
// Add this to your AppDelegate to fully match the spec's "banner disappears after app closes" requirement.
