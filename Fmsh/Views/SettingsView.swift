import SwiftUI

struct SettingsView: View {
  @AppStorage("greeting") private var greeting = "hello"

  var body: some View {
    Form {
      TextField("Greeting", text: $greeting)
      Text("Shown in the main window. Stored in user defaults.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .formStyle(.grouped)
    .frame(width: 420)
  }
}
