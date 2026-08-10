import SwiftUI

struct MainTabView: View {
    @State private var selection = 0
    var body: some View {
        ZStack {
            FullBackground()
            VStack(spacing: 0) {
                Group {
                    switch selection {
                    case 0: NavigationStack { DiaryHomeView() }
                    case 1: NavigationStack { StatisticsView() }
                    case 2: NavigationStack { NotesView() }
                    default: NavigationStack { ArticlesView() }
                    }
                }.toolbar(.hidden, for: .navigationBar).frame(maxWidth: .infinity, maxHeight: .infinity)
                CustomTabBar(selection: $selection)
            }
        }.ignoresSafeArea(edges: .bottom)
    }
}

private struct CustomTabBar: View {
    @Binding var selection: Int
    private let images = ["tasks", "statistics", "notes", "articles"]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(images.indices, id: \.self) { index in
                Button { selection = index } label: {
                    Image(images[index]).renderingMode(.template).resizable().scaledToFit().frame(width: 28, height: 28)
                        .foregroundStyle(selection == index ? .white : Theme.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(selection == index ? Color.white.opacity(0.18) : .clear, in: Capsule())
                        .padding(.vertical, 11).padding(.horizontal, 8)
                }
            }
        }
        .frame(height: 82)
        .padding(.horizontal, 10)
        .background(LinearGradient(colors: [Color.white.opacity(0.32), Theme.orange], startPoint: .top, endPoint: .center), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct DiaryHomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DiaryStore
    @State private var refresh = UUID()

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: appState.text("Athlete's Diary"))
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    NavigationLink { RecommendedPlanView() } label: {
                        Image("plan-\(appState.language == .ru ? "ru" : "eng")").resizable().frame(width: 360, height: 249)
                    }
                    NavigationLink { PlansView() } label: {
                        ZStack(alignment: .topLeading) {
                            Image("my_plan_\(appState.language == .ru ? "ru" : "eng")").resizable().frame(width: 360, height: 189)
                            Text(planCount).font(.montserrat(16)).foregroundStyle(.white).padding(.horizontal, 10).frame(height: 20)
                                .background(Theme.orange, in: RoundedRectangle(cornerRadius: 10)).padding(.top, 40).padding(.leading, 10)
                        }
                    }
                    NavigationLink { WorkoutEditorView(isForPlan: false) } label: { Text(appState.text("Add workout")) }.buttonStyle(ImageButtonStyle(wide: true))
                    NavigationLink { PlanEditorView() } label: { Text(appState.text("Make a training plan")) }.buttonStyle(ImageButtonStyle(wide: true))
                }.frame(width: 360).padding(.top, 10).padding(.bottom, 16)
            }.id(refresh).onAppear { refresh = UUID() }
        }.background(FullBackground()).toolbar(.hidden, for: .navigationBar)
    }

    private var planCount: String {
        let count = store.plans.count
        if appState.language == .en { return "\(count) \(count < 2 ? "workout" : "workouts")" }
        let word = count == 0 ? "тренировок" : (count % 10 == 1 && count % 100 != 11 ? "тренировка" : ((2...4).contains(count % 10) && !(12...14).contains(count % 100) ? "тренировки" : "тренировок"))
        return "\(count) \(word)"
    }
}

struct RecommendedPlanView: View {
    @EnvironmentObject private var appState: AppState
    var body: some View {
        VStack(spacing: 0) {
            BackHeader(title: appState.text("Recommended plan"))
            ScrollView(showsIndicators: false) {
                Image("recommended_plan_\(appState.language.rawValue)").resizable().scaledToFit().frame(width: 360).clipShape(RoundedRectangle(cornerRadius: 20)).padding(.top, 28)
            }
        }.background(FullBackground()).toolbar(.hidden, for: .navigationBar)
    }
}
