// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "fmsh",
  platforms: [.macOS(.v26)],
  targets: [
    .executableTarget(
      name: "fmsh",
      swiftSettings: [.treatAllWarnings(as: .error)],
      plugins: ["EmbedInstructions"]
    ),
    .plugin(name: "EmbedInstructions", capability: .buildTool()),
  ]
)
