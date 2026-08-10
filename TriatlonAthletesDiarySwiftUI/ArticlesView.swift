import SwiftUI

struct ArticlesView: View {
    @EnvironmentObject private var appState: AppState
    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: appState.text("Training recommendations"))
            VStack(spacing: 16) {
                article(index: 1, name: "swim", title: "swim")
                article(index: 2, name: "run", title: "run")
                article(index: 3, name: "cycle", title: "cycle")
                Spacer()
            }.frame(width: 360).padding(.top, -4)
        }.background(FullBackground()).toolbar(.hidden, for: .navigationBar)
    }

    private func article(index: Int, name: String, title: String) -> some View {
        NavigationLink {
            ArticleDetailView(article: name, title: appState.text(title))
        } label: {
            Image("article_\(index)_\(appState.language.rawValue)").resizable().frame(width: 360, height: 154)
        }.buttonStyle(.plain)
    }
}

struct ArticleDetailView: View {
    @EnvironmentObject private var appState: AppState
    let article: String
    let title: String
    var body: some View {
        VStack(spacing: 0) {
            BackHeader(title: title)
            ScrollView(showsIndicators: false) {
                Image("text_\(article)_\(appState.language.rawValue)").resizable().scaledToFit().frame(width: 360)
            }.frame(width: 360).clipShape(RoundedRectangle(cornerRadius: 20)).padding(.top, 2)
        }.background(FullBackground()).toolbar(.hidden, for: .navigationBar)
    }
}
