import Foundation
import CoreData

enum AppLanguage: String, Codable, CaseIterable {
    case en, ru
}

enum WorkoutType: Int32, CaseIterable, Identifiable {
    case swimming, cycling, running, other

    var id: Int32 { rawValue }
    var imageStem: String {
        switch self {
        case .swimming: "swim"
        case .cycling: "cycle"
        case .running: "run"
        case .other: "other"
        }
    }
    var iconAsset: String { "type_\(rawValue)" }
}

@objc(Workout)
final class Workout: NSManagedObject {
    @NSManaged var date: Date?
    @NSManaged var desc: String?
    @NSManaged var distance: Int32
    @NSManaged var duration: Int32
    @NSManaged var type: Int32
    @NSManaged var plan: Plan?
}

extension Workout {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Workout> { NSFetchRequest(entityName: "Workout") }
    var workoutType: WorkoutType { WorkoutType(rawValue: type) ?? .other }
}

@objc(Plan)
final class Plan: NSManagedObject {
    @NSManaged var title: String?
    @NSManaged var workouts: Set<Workout>?
}

extension Plan {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Plan> { NSFetchRequest(entityName: "Plan") }
    var sortedWorkouts: [Workout] { Array(workouts ?? []).sorted { $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString } }
}

struct WorkoutDraft: Identifiable, Equatable {
    var id = UUID()
    var type: WorkoutType?
    var description = ""
    var date: Date?
    var distance: Int?
    var duration: Int?

    init(type: WorkoutType? = nil, description: String = "", date: Date? = nil, distance: Int? = nil, duration: Int? = nil) {
        self.type = type; self.description = description; self.date = date; self.distance = distance; self.duration = duration
    }

    init(workout: Workout) {
        type = workout.workoutType; description = workout.desc ?? ""; date = workout.date
        distance = Int(workout.distance); duration = Int(workout.duration)
    }
}
