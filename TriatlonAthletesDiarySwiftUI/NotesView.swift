import SwiftUI

struct NotesView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DiaryStore
    @State private var date = Date()
    @State private var sharePayload: SharePayload?
    @State private var selectedWorkout: Workout?
    @State private var showEditor = false
    @State private var refresh = UUID()

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: appState.text("Training notes"))
            VStack(spacing: 32) {
                DateCarousel(date: $date)
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(store.workouts(on: date), id: \.objectID) { workout in
                            WorkoutRow(draft: WorkoutDraft(workout: workout), showsActions: true, onEdit: { selectedWorkout = workout; showEditor = true }) { sharePayload = SharePayload(text: share(workout)) }
                        }
                    }
                }
            }.frame(width: 360).padding(.top, -11)
        }
        .id(refresh).onAppear { refresh = UUID() }
        .sheet(item: $sharePayload) { ShareSheet(items: [$0.text]) }
        .navigationDestination(isPresented: $showEditor) { if let selectedWorkout { WorkoutEditorView(isForPlan: false, workout: selectedWorkout) } }
        .background(FullBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func share(_ workout: Workout) -> String {
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = appState.language == .ru ? "dd.MM.yyyy" : "yyyy-MM-dd"
        let distance = workout.workoutType == .other ? appState.text("N/A") : String(format: "%.2f %@", Double(workout.distance) / 1000, appState.text("km."))
        return "Triatlon: athletes diary\n\(appState.text("My workout:"))\n\(appState.text("Type")): \(appState.typeName(workout.workoutType))\n\(appState.text("Duration")): \(workout.duration) \(appState.text("min."))\n\(appState.text("Distance")): \(distance)\n\(appState.text("Date")): \(dateFormatter.string(from: workout.date ?? Date()))"
    }
}

struct SharePayload: Identifiable { let id = UUID(); let text: String }

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
