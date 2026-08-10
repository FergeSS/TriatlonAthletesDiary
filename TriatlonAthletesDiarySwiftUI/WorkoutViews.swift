import SwiftUI

struct DateCarousel: View {
    @EnvironmentObject private var appState: AppState
    @Binding var date: Date
    private let calendar = Calendar.current

    var body: some View {
        return Panel(height: 96) {
            VStack(spacing: 2) {
                Text(DateText.monthYear(date, language: appState.language)).font(.alternates(16)).foregroundStyle(.white).frame(height: 38)
                HStack(spacing: 0) {
                    Button { shift(-1) } label: { Image("arrow_left").resizable().scaledToFit().frame(width: 20, height: 20) }
                    Spacer(minLength: 7)
                    HStack(spacing: 16) {
                        ForEach(-2...2, id: \.self) { offset in
                            let item = calendar.date(byAdding: .day, value: offset, to: date) ?? date
                            Button { date = item } label: {
                                Text(DateText.day(item, language: appState.language)).font(.montserrat(12)).multilineTextAlignment(.center)
                                    .foregroundStyle(dayText(item)).frame(width: 32, height: 32).background(dayColor(item), in: RoundedRectangle(cornerRadius: 5))
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.orange, lineWidth: offset == 0 ? 2 : 0))
                            }
                        }
                    }
                    Spacer(minLength: 7)
                    Button { shift(1) } label: { Image("arrow_right").resizable().scaledToFit().frame(width: 20, height: 20) }
                }.padding(.horizontal, 10)
            }
        }
    }

    private func shift(_ value: Int) { date = calendar.date(byAdding: .day, value: value, to: date) ?? date }
    private func dayColor(_ value: Date) -> Color {
        if calendar.isDateInToday(value) { return Theme.orange }
        return value < calendar.startOfDay(for: Date()) ? Theme.navy : Theme.inactive
    }
    private func dayText(_ value: Date) -> Color { value > Date() && !calendar.isDateInToday(value) ? Color(red: 41/255, green: 41/255, blue: 41/255) : .white }
}

struct WorkoutEditorView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DiaryStore
    @Environment(\.dismiss) private var dismiss
    let isForPlan: Bool
    let workout: Workout?
    let onSave: ((WorkoutDraft) -> Void)?
    let editingDraft: Bool
    @State private var draft: WorkoutDraft
    @State private var date: Date
    @State private var distanceText: String
    @State private var durationText: String
    @State private var alertMessage = ""
    @State private var showAlert = false

    init(isForPlan: Bool, draft: WorkoutDraft? = nil, workout: Workout? = nil, onSave: ((WorkoutDraft) -> Void)? = nil) {
        let source = draft ?? workout.map(WorkoutDraft.init) ?? WorkoutDraft(date: isForPlan ? nil : Date())
        self.isForPlan = isForPlan; self.workout = workout; self.onSave = onSave; editingDraft = draft != nil
        _draft = State(initialValue: source); _date = State(initialValue: source.date ?? Date())
        _distanceText = State(initialValue: source.distance.map(String.init) ?? "")
        _durationText = State(initialValue: source.duration.map(String.init) ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            BackHeader(title: appState.text(isEditing ? "Edit workout" : "Add workout"))
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if !isForPlan { DateCarousel(date: $date) }
                    typePanel
                    if draft.type != .other { metricPanel(title: appState.text("Distance"), text: $distanceText, values: [1000,1500,2000,3000,4000,5000,10000], unit: appState.text("m"), max: 1_000_000) }
                    metricPanel(title: appState.text("Duration"), text: $durationText, values: [20,25,30,35,40,45,50,60], unit: appState.text("min"), max: 1440)
                    notesPanel
                    HStack(spacing: 0) {
                        if isEditing { Button(appState.text("Delete"), action: delete).buttonStyle(ImageButtonStyle(wide: false)); Spacer() }
                        Button(appState.text("Save"), action: save).buttonStyle(ImageButtonStyle(wide: false))
                    }.frame(width: isEditing ? 320 : 160).padding(.bottom, 12)
                }.frame(width: 360).padding(.top, 4)
            }
        }
        .alert(appState.text("Error"), isPresented: $showAlert) { Button("OK") {} } message: { Text(alertMessage) }
        .background(FullBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var isEditing: Bool { workout != nil || editingDraft }

    private var typePanel: some View {
        Panel(height: 96) {
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.text("Load type")).font(.montserrat(16, weight: "Bold")).foregroundStyle(.white)
                HStack(spacing: 5) {
                    ForEach(WorkoutType.allCases) { type in
                        Button { draft.type = type } label: {
                            Image("\(type.imageStem)_\(draft.type == type ? "pressed_" : "")\(appState.language.rawValue)").resizable().scaledToFit().frame(width: 52, height: 52)
                        }
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10)
        }
    }

    private func metricPanel(title: String, text: Binding<String>, values: [Int], unit: String, max: Int) -> some View {
        let duration = values.count == 8
        let topWidths: [CGFloat] = duration ? [66, 64, 65] : [61, 61, 65]
        let bottomWidths: [CGFloat] = duration ? [64, 67, 65, 66, 66] : [65, 66, 65, 71]
        let spacing: CGFloat = duration ? 4 : 6
        return Panel(height: 96) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.montserrat(16, weight: "Bold")).foregroundStyle(.white)
                HStack(spacing: spacing) {
                    numberField(text, max: max)
                    ForEach(Array(values.prefix(3).enumerated()), id: \.offset) { index, value in pill(value, unit: unit, text: text, width: topWidths[index]) }
                }
                HStack(spacing: spacing) { ForEach(Array(values.dropFirst(3).enumerated()), id: \.offset) { index, value in pill(value, unit: unit, text: text, width: bottomWidths[index]) } }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10)
        }
    }

    private func numberField(_ binding: Binding<String>, max: Int) -> some View {
        TextField(appState.text("Enter your value"), text: binding).keyboardType(.numberPad).multilineTextAlignment(.center)
            .font(.montserrat(12, weight: "Light")).foregroundStyle(.white).frame(width: 136, height: 20).background(Theme.navy, in: Capsule())
            .onChange(of: binding.wrappedValue) { _, value in
                let digits = value.filter(\.isNumber)
                if digits != value { binding.wrappedValue = digits; alertMessage = appState.text("ONLY_DIGITS_ALLOWED"); showAlert = true }
                if let number = Int(digits), number > max { binding.wrappedValue = String(digits.prefix(max == 1440 ? 4 : 7)); alertMessage = String(format: appState.text("MAX_VALUE_EXCEEDED"), max); showAlert = true }
            }
    }

    private func pill(_ value: Int, unit: String, text: Binding<String>, width: CGFloat) -> some View {
        Button { text.wrappedValue = String(value) } label: {
            Text(verbatim: String(value) + (value < 100 ? " " : "") + unit)
                .font(.montserrat(14))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .allowsTightening(true)
                .frame(width: width, height: 20)
                .background(text.wrappedValue == String(value) ? Theme.orange : Theme.navy, in: Capsule())
        }.buttonStyle(.plain)
    }

    private var notesPanel: some View {
        Panel(height: 96) {
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.text("Notes")).font(.montserrat(16, weight: "Bold")).foregroundStyle(.white)
                TextEditor(text: $draft.description).font(.montserrat(12, weight: "Light")).foregroundStyle(.white).scrollContentBackground(.hidden)
                    .padding(.horizontal, 5).frame(height: 53).background(Theme.navy, in: RoundedRectangle(cornerRadius: 13))
            }.padding(.horizontal, 10)
        }
    }

    private func save() {
        guard let type = draft.type else { fail("TYPE_IS_NILL"); return }
        guard let duration = Int(durationText) else { fail("DURATION_IS_NILL"); return }
        let distance = type == .other ? 0 : Int(distanceText)
        guard let distance else { fail("DISTANCE_IS_NILL"); return }
        draft.type = type; draft.duration = duration; draft.distance = distance; draft.date = isForPlan ? nil : date
        if isForPlan { onSave?(draft) } else if let workout { store.update(workout, with: draft) } else { store.add(draft) }
        dismiss()
    }

    private func delete() {
        if isForPlan { var deleted = draft; deleted.type = nil; deleted.duration = nil; deleted.distance = nil; deleted.description = ""; onSave?(deleted) }
        else if let workout { store.delete(workout) }
        dismiss()
    }
    private func fail(_ key: String) { alertMessage = appState.text(key); showAlert = true }
}

struct WorkoutRow: View {
    @EnvironmentObject private var appState: AppState
    let draft: WorkoutDraft
    let showsActions: Bool
    let onEdit: (() -> Void)?
    let onShare: (() -> Void)?
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20).fill(Theme.panel)
            if let type = draft.type {
                Image(type.iconAsset).resizable().scaledToFit().frame(width: 40, height: 37).offset(x: 15, y: 11)
                HStack(spacing: 5) {
                    if type != .other { Text("\(draft.distance ?? 0)\(appState.text("m"))") }
                    Text("\(draft.duration ?? 0)\(appState.text("min"))")
                }.font(.montserrat(14)).foregroundStyle(.white).offset(x: 80, y: 22)
                Text(draft.description).font(.montserrat(12)).foregroundStyle(.white).lineLimit(1).frame(width: showsActions ? 316 : 340, alignment: .leading).offset(x: 15, y: 52)
                if showsActions {
                    Button(action: { onShare?() }) { Image("share_\(type.rawValue)").resizable().frame(width: 24, height: 24) }.offset(x: 326, y: 10)
                    Button(action: { onEdit?() }) { Image("edit_\(type.rawValue)").resizable().frame(width: 24, height: 24) }.offset(x: 326, y: 45)
                }
            }
        }.frame(width: 360, height: 79)
    }
}
