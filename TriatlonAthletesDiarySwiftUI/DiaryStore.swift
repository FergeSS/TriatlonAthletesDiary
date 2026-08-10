import Foundation
import CoreData

@MainActor
final class DiaryStore: ObservableObject {
    static let shared = DiaryStore()
    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataBase")
        if inMemory { container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null") }
        container.loadPersistentStores { _, error in
            if let error { fatalError("Unresolved Core Data error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var workouts: [Workout] {
        let request = Workout.fetchRequest(); request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return (try? container.viewContext.fetch(request)) ?? []
    }

    var plans: [Plan] { (try? container.viewContext.fetch(Plan.fetchRequest())) ?? [] }

    func add(_ draft: WorkoutDraft) {
        let workout = Workout(context: container.viewContext); apply(draft, to: workout); save()
    }

    func update(_ workout: Workout, with draft: WorkoutDraft) { apply(draft, to: workout); save() }

    func delete(_ workout: Workout) { container.viewContext.delete(workout); save() }

    func workouts(on date: Date) -> [Workout] {
        workouts.filter { item in
            guard let itemDate = item.date else { return false }
            return Calendar.current.isDate(itemDate, inSameDayAs: date)
        }
    }

    func recentWorkouts(days: Int, type: WorkoutType? = nil) -> [Workout] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        return workouts.filter {
            guard let date = $0.date, date >= cutoff, date <= Date() else { return false }
            return type == nil || $0.workoutType == type
        }
    }

    func addPlan(title: String, drafts: [WorkoutDraft]) {
        let plan = Plan(context: container.viewContext); plan.title = title
        plan.workouts = Set(drafts.map { draft in let workout = Workout(context: container.viewContext); apply(draft, to: workout); return workout })
        save()
    }

    func updatePlan(_ plan: Plan, title: String, drafts: [WorkoutDraft]) {
        for workout in plan.workouts ?? [] { container.viewContext.delete(workout) }
        plan.title = title
        plan.workouts = Set(drafts.map { draft in let workout = Workout(context: container.viewContext); apply(draft, to: workout); return workout })
        save()
    }

    func deletePlan(_ plan: Plan) { container.viewContext.delete(plan); save() }

    private func apply(_ draft: WorkoutDraft, to workout: Workout) {
        workout.type = draft.type?.rawValue ?? 0; workout.desc = draft.description; workout.date = draft.date
        workout.distance = Int32(draft.distance ?? 0); workout.duration = Int32(draft.duration ?? 0)
    }

    private func save() { try? container.viewContext.save(); objectWillChange.send() }
}
