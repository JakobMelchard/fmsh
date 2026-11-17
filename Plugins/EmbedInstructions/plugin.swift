import PackagePlugin

@main
struct EmbedInstructions: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    let input = target.directory.appending("instructions.md")
    let output = context.pluginWorkDirectory.appending("Instructions.generated.swift")
    let script = context.package.directory.appending("Scripts/embed-instructions.sh")
    return [
      .buildCommand(
        displayName: "Embed instructions.md",
        executable: Path("/bin/sh"),
        arguments: [script.string, input.string, output.string],
        inputFiles: [input],
        outputFiles: [output]
      )
    ]
  }
}
