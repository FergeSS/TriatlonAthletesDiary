import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLang") }
    }
    @Published var isStarted = false

    init() {
        language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLang") ?? "en") ?? .en
    }

    func text(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    func typeName(_ type: WorkoutType) -> String {
        switch type { case .swimming: text("Swimming"); case .cycling: text("Cycling"); case .running: text("Running"); case .other: text("Other") }
    }
}

enum DateText {
    static func monthYear(_ date: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "MMMM yyyy"; formatter.locale = Locale(identifier: language.rawValue)
        let value = formatter.string(from: date)
        return value.prefix(1).uppercased() + value.dropFirst()
    }

    static func day(_ date: Date, language: AppLanguage) -> String {
        let number = DateFormatter(); number.dateFormat = "dd"
        let weekday = DateFormatter(); weekday.dateFormat = "EEE"; weekday.locale = Locale(identifier: language.rawValue)
        return "\(number.string(from: date))\n\(weekday.string(from: date))"
    }
}
