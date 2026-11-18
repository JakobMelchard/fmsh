import Foundation
import PackagePlugin

@main
struct EmbedInstructions: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    let input = target.directoryURL.appending(path: "instructions.md")
    let output = context.pluginWorkDirectoryURL.appending(path: "Instructions.generated.swift")
    let script = context.package.directoryURL.appending(path: "Scripts/embed-instructions.sh")
    return [
      .buildCommand(
        displayName: "Embed instructions.md",
        executable: URL(filePath: "/bin/sh"),
        arguments: [
          script.path(percentEncoded: false),
          input.path(percentEncoded: false),
          output.path(percentEncoded: false),
        ],
        inputFiles: [input],
        outputFiles: [output]
      )
    ]
  }
}
