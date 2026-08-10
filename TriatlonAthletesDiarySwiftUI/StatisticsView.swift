import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DiaryStore
    @State private var days = 7
    @State private var graph = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: appState.text("Statistics")) {
                Button { graph.toggle() } label: {
                    ZStack { Circle().fill(Color.white.opacity(0.18)); Image(graph ? "statistic_list" : "statistic_graph").resizable().scaledToFit().frame(width: 32, height: 32) }.frame(width: 44, height: 44)
                }
            }
            periodPanel.padding(.top, -3)
            ScrollView(showsIndicators: false) {
                if graph { graphList } else { statisticsList }
            }.frame(width: 360).padding(.top, 16)
        }.background(FullBackground()).toolbar(.hidden, for: .navigationBar)
    }

    private var periodPanel: some View {
        Panel(height: 52) {
            HStack(spacing: 7.5) {
                periodButton(appState.text("Week"), 7); periodButton(appState.text("Month"), 30); periodButton(appState.text("Year"), 365)
            }.padding(7.5)
        }.frame(width: 360)
    }

    private func periodButton(_ title: String, _ value: Int) -> some View {
        Button { days = value } label: {
            Text(title).font(.montserrat(12)).foregroundStyle(days == value ? .white : Theme.muted).frame(width: 110, height: 32)
                .background(Image(days == value ? "radio_button_st_selected" : "radio_button_st").resizable())
        }
    }

    private var statisticsList: some View {
        let all = store.recentWorkouts(days: days)
        return ZStack(alignment: .topLeading) {
            Image("list_\(appState.language.rawValue)").resizable().frame(width: 360, height: 499)
            ForEach(Array(WorkoutType.allCases.enumerated()), id: \.offset) { index, type in
                let values = all.filter { $0.workoutType == type }
                let duration = values.reduce(0) { $0 + Int($1.duration) }
                statPair("\(values.count)", appState.text("pcs.")).position(x: 88, y: 84 + CGFloat(index * 55))
                statPair("\(duration / 60)", appState.text("h.")).position(x: 220, y: 84 + CGFloat(index * 55))
                statPair("\(duration % 60)", appState.text("min.")).position(x: 290, y: 84 + CGFloat(index * 55))
                if index < 3 {
                    let distance = values.reduce(0) { $0 + Int($1.distance) }
                    statPair("\(distance / 1000)", appState.text("km.")).position(x: 90, y: 369 + CGFloat(index * 55))
                    statPair("\(distance % 1000)", appState.text("m.")).position(x: 188, y: 369 + CGFloat(index * 55))
                }
            }
        }.frame(width: 360, height: 499)
    }

    private func statPair(_ value: String, _ unit: String) -> some View {
        (
            Text(verbatim: value)
                .font(.montserrat(20, weight: "ExtraBoldItalic"))
            + Text(verbatim: " \(unit)")
                .font(.montserrat(14))
        )
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var graphList: some View {
        VStack(spacing: 10) {
            ForEach(Array(WorkoutType.allCases.prefix(3))) { type in
                let values = store.recentWorkouts(days: days, type: type)
                Panel(height: 268) {
                    ZStack(alignment: .topLeading) {
                        Text(appState.typeName(type)).font(.alternates(16)).foregroundStyle(.white).padding(10)
                        Image(type.iconAsset).resizable().scaledToFit().frame(width: 40, height: 37).position(x: 330, y: 28)
                        ExactGraph(workouts: values, type: type, appState: appState).frame(width: 348, height: 220).offset(x: 5, y: 40)
                    }
                }
            }
        }
    }
}

private struct ExactGraph: View {
    let workouts: [Workout]
    let type: WorkoutType
    let appState: AppState
    var body: some View {
        Canvas { context, size in
            let width = size.width - 20, xAxis = size.height * 0.85, yAxis = width * 0.15
            var axes = Path(); axes.move(to: CGPoint(x: yAxis, y: 0)); axes.addLine(to: CGPoint(x: yAxis, y: xAxis)); axes.addLine(to: CGPoint(x: width, y: xAxis))
            axes.move(to: CGPoint(x: width - 10, y: xAxis - 5)); axes.addLine(to: CGPoint(x: width, y: xAxis)); axes.addLine(to: CGPoint(x: width - 10, y: xAxis + 5))
            axes.move(to: CGPoint(x: yAxis - 5, y: 10)); axes.addLine(to: CGPoint(x: yAxis, y: 0)); axes.addLine(to: CGPoint(x: yAxis + 5, y: 10))
            context.stroke(axes, with: .color(.white), lineWidth: 2)
            context.draw(Text(appState.text("t, min")).font(.system(size: 12)).foregroundStyle(.white), at: CGPoint(x: yAxis - 20, y: 18))
            context.draw(Text(appState.text("Distance, m")).font(.system(size: 12)).foregroundStyle(.white), at: CGPoint(x: width - 40, y: xAxis + 27))
            guard !workouts.isEmpty else { return }
            let maxX = Double(workouts.map(\.distance).max() ?? 0) + Double(workouts.first?.distance ?? 0)
            let maxY = Double(workouts.map(\.duration).max() ?? 0) + Double(workouts.map(\.duration).min() ?? 0)
            guard maxX > 0, maxY > 0 else { return }
            let sx = (width - yAxis - 10) / maxX, sy = (xAxis - 10) / maxY
            var line = Path()
            for (index, workout) in workouts.enumerated() {
                let point = CGPoint(x: yAxis + Double(workout.distance) * sx, y: xAxis - Double(workout.duration) * sy)
                index == 0 ? line.move(to: point) : line.addLine(to: point)
                context.fill(Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)), with: .color(color))
            }
            context.stroke(line, with: .color(.white), lineWidth: 2)
        }
    }
    private var color: Color { switch type { case .swimming: Theme.swim; case .cycling: Theme.cycle; case .running: Theme.run; case .other: .white } }
}
