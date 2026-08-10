import SwiftUI

struct PlansView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DiaryStore
    @State private var refresh = UUID()
    var body: some View {
        VStack(spacing: 0) {
            BackHeader(title: appState.text("My training plans"))
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(store.plans, id: \.objectID) { plan in
                        NavigationLink { PlanEditorView(plan: plan) } label: {
                            Text(plan.title ?? "").font(.montserrat(16)).foregroundStyle(.white).frame(width: 360, height: 50)
                                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 20))
                        }.buttonStyle(.plain)
                    }
                }.padding(.top, 10)
            }.id(refresh).onAppear { refresh = UUID() }
        }.background(FullBackground()).toolbar(.hidden, for: .navigationBar)
    }
}

struct PlanEditorView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DiaryStore
    @Environment(\.dismiss) private var dismiss
    let plan: Plan?
    @State private var name: String
    @State private var drafts: [WorkoutDraft]
    @State private var showAlert = false
    @State private var message = ""

    init(plan: Plan? = nil) {
        self.plan = plan
        _name = State(initialValue: plan?.title ?? "")
        _drafts = State(initialValue: plan?.sortedWorkouts.map(WorkoutDraft.init) ?? [])
    }

    var body: some View {
        VStack(spacing: 0) {
            BackHeader(title: appState.text(plan == nil ? "Make a training plan" : "Edit a training plan"))
            VStack(spacing: 16) {
                Panel(height: 96) {
                    VStack(spacing: 5) {
                        Text(appState.text("The name of the plan")).font(.montserrat(16, weight: "Bold")).foregroundStyle(.white)
                        TextField("", text: $name).multilineTextAlignment(.center).font(.montserrat(12, weight: "Light")).foregroundStyle(.white)
                            .frame(height: 30).background(Theme.navy, in: RoundedRectangle(cornerRadius: 13)).padding(.horizontal, 10)
                            .onChange(of: name) { _, value in if value.count >= 30 { name = String(value.prefix(29)) }; if name == " " { name = "" } }
                    }.padding(.vertical, 10)
                }
                NavigationLink {
                    WorkoutEditorView(isForPlan: true) { value in if value.type != nil { drafts.append(value) } }
                } label: { Text(appState.text("Add workout")) }.buttonStyle(ImageButtonStyle(wide: true))
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(drafts) { draft in
                            NavigationLink {
                                WorkoutEditorView(isForPlan: true, draft: draft) { replacement in
                                    guard let index = drafts.firstIndex(where: { $0.id == draft.id }) else { return }
                                    if replacement.type == nil { drafts.remove(at: index) } else { drafts[index] = replacement }
                                }
                            } label: { WorkoutRow(draft: draft, showsActions: false, onEdit: nil, onShare: nil) }.buttonStyle(.plain)
                        }
                    }
                }
                HStack(spacing: 0) {
                    if plan != nil { Button(appState.text("Delete"), action: delete).buttonStyle(ImageButtonStyle(wide: false)); Spacer() }
                    Button(appState.text("Save"), action: save).buttonStyle(ImageButtonStyle(wide: false))
                }.frame(width: plan == nil ? 160 : 320).padding(.bottom, 8)
            }.frame(width: 360).padding(.top, 10)
        }
        .alert(appState.text("Error"), isPresented: $showAlert) { Button("OK") {} } message: { Text(message) }
        .background(FullBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func save() {
        guard !drafts.isEmpty else { message = appState.text("Add at least 1 workout"); showAlert = true; return }
        guard !name.isEmpty else { message = appState.text("Input name of plan"); showAlert = true; return }
        if let plan { store.updatePlan(plan, title: name, drafts: drafts) } else { store.addPlan(title: name, drafts: drafts) }
        dismiss()
    }
    private func delete() { if let plan { store.deletePlan(plan) }; dismiss() }
}
