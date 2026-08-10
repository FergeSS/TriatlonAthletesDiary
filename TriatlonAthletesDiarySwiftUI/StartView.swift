import SwiftUI
import WebKit

struct StartView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showPolicy = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("заставка").resizable().scaledToFill().frame(width: proxy.size.width, height: proxy.size.height).clipped()
                VStack {
                    Spacer()
                    Button(appState.text("Start")) { appState.isStarted = true }
                        .buttonStyle(ImageButtonStyle(wide: false)).padding(.bottom, 20)
                    HStack {
                        Button { appState.language = appState.language == .en ? .ru : .en } label: {
                            Image(appState.language == .ru ? "Frame ru" : "Frame eng").resizable().scaledToFit().frame(width: 100, height: 50)
                        }
                        Spacer()
                        Button { showPolicy = true } label: { Image("Policy").resizable().scaledToFit().frame(width: 30, height: 30) }
                    }.padding(.horizontal, 20).padding(.bottom, 20)
                }
            }
        }.ignoresSafeArea().fullScreenCover(isPresented: $showPolicy) { PolicyView() }
    }
}

struct PolicyView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()
            HTMLView(resource: "terms", extension: "html").padding(.horizontal, 10).padding(.top, 50)
            Button { dismiss() } label: { Image("arrow_left").resizable().scaledToFit().frame(width: 42, height: 42) }.padding(.leading, 14)
        }
    }
}

struct HTMLView: UIViewRepresentable {
    let resource: String
    let `extension`: String
    func makeUIView(context: Context) -> WKWebView { let view = WKWebView(); view.layer.cornerRadius = 15; view.clipsToBounds = true; return view }
    func updateUIView(_ view: WKWebView, context: Context) {
        guard view.url == nil, let url = Bundle.main.url(forResource: resource, withExtension: `extension`) else { return }
        view.load(URLRequest(url: url))
    }
}
