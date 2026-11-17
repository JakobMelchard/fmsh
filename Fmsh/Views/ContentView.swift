import SwiftUI

struct ContentView: View {
  @Environment(Model.self) private var model
  @AppStorage("greeting") private var greeting = "hello"

  var body: some View {
    VStack(spacing: 12) {
      Text(greeting).font(.largeTitle.monospaced())
      Button("Count \(model.count)") { model.increment() }
        .keyboardShortcut("k", modifiers: .command)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
