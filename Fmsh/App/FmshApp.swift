import SwiftUI

@main
struct FmshApp: App {
  @State private var model = Model()

  var body: some Scene {
    Window("Fmsh", id: "main") {
      ContentView()
        .environment(model)
        .frame(minWidth: 520, minHeight: 360)
        .preferredColorScheme(.dark)
    }
    .windowToolbarStyle(.unified)
    .defaultSize(width: 900, height: 600)

    Settings {
      SettingsView()
        .preferredColorScheme(.dark)
    }
  }
}
