import SwiftUI
import CoreText

enum Theme {
    static let gray = Color(red: 75/255, green: 75/255, blue: 75/255)
    static let orange = Color(red: 246/255, green: 107/255, blue: 14/255)
    static let navy = Color(red: 17/255, green: 43/255, blue: 60/255)
    static let panel = Color(red: 46/255, green: 68/255, blue: 83/255).opacity(0.70)
    static let inactive = Color(red: 59/255, green: 74/255, blue: 84/255)
    static let muted = Color(red: 132/255, green: 132/255, blue: 132/255)
    static let swim = Color(red: 28/255, green: 198/255, blue: 1)
    static let cycle = orange
    static let run = Color(red: 230/255, green: 224/255, blue: 22/255)
}

enum FontRegistrar {
    static func registerBundledFonts() {
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return }
        for case let url as URL in enumerator where url.pathExtension.lowercased() == "ttf" {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    static func montserrat(_ size: CGFloat, weight: String = "Regular") -> Font { .custom("Montserrat-\(weight)", size: size) }
    static func alternates(_ size: CGFloat, weight: String = "Bold") -> Font { .custom("MontserratAlternates-\(weight)", size: size) }
}

struct FullBackground: View {
    var body: some View {
        GeometryReader { proxy in
            Image("back").resizable().scaledToFill().frame(width: proxy.size.width, height: proxy.size.height).clipped()
        }.ignoresSafeArea()
    }
}

struct ImageButtonStyle: ButtonStyle {
    let wide: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.montserrat(16, weight: "Bold")).foregroundStyle(.white)
            .frame(width: wide ? 360 : 160, height: 50)
            .background(Image(configuration.isPressed ? (wide ? "big_button_pressed" : "start pressed") : (wide ? "big_button" : "start")).resizable())
    }
}

struct ScreenHeader<Left: View>: View {
    @EnvironmentObject private var appState: AppState
    let title: String
    @ViewBuilder var left: Left

    var body: some View {
        ZStack {
            Text(title)
                .font(.alternates(18, weight: "ExtraBold"))
                .foregroundStyle(Theme.orange)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: 270)
            HStack {
                left.frame(width: 44, height: 44)
                Spacer()
                Button { appState.isStarted = false } label: {
                    ZStack { Circle().fill(Color.white.opacity(0.55)); Circle().stroke(Theme.muted, lineWidth: 1); Image("home").resizable().scaledToFit().frame(width: 27, height: 27) }
                        .frame(width: 44, height: 44)
                }
            }
        }.frame(height: 52).padding(.horizontal, 20)
    }
}

extension ScreenHeader where Left == Color {
    init(title: String) { self.title = title; left = .clear }
}

struct BackHeader: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    var body: some View {
        ScreenHeader(title: title) {
            Button { dismiss() } label: {
                ZStack { Circle().fill(Color.white.opacity(0.55)); Circle().stroke(Theme.muted, lineWidth: 1); Image("arrow_left").resizable().scaledToFit().frame(width: 20, height: 20) }
                    .frame(width: 44, height: 44)
            }
        }
    }
}

struct Panel<Content: View>: View {
    let height: CGFloat?
    @ViewBuilder let content: Content
    init(height: CGFloat? = nil, @ViewBuilder content: () -> Content) { self.height = height; self.content = content() }
    var body: some View { content.frame(maxWidth: .infinity, minHeight: height, maxHeight: height).background(Theme.panel, in: RoundedRectangle(cornerRadius: 20)) }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    var body: some View { if appState.isStarted { MainTabView() } else { StartView() } }
}
