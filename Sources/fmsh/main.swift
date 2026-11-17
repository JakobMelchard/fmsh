import Foundation
import FoundationModels

func loadInstructions() -> String {
  let env = ProcessInfo.processInfo.environment
  if let path = env["FMSH_INSTRUCTIONS"], !path.isEmpty {
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
      FileHandle.standardError.write(Data("fmsh: \(path): cannot read instructions\n".utf8))
      exit(1)
    }
    return text
  }
  let home = FileManager.default.homeDirectoryForCurrentUser.path
  let config = env["XDG_CONFIG_HOME"] ?? "\(home)/.config"
  let path = "\(config)/fmsh/instructions.md"
  return (try? String(contentsOfFile: path, encoding: .utf8)) ?? defaultInstructions
}

@Generable
struct Command {
  @Guide(description: "A complete command line that runs as typed, for example: ls -d */")
  var line: String
}

@Generable
struct Suggestions {
  @Guide(description: "Up to three candidate commands, best first", .maximumCount(3))
  var commands: [Command]
}

var args = Array(CommandLine.arguments.dropFirst())
var prefix = ""
var notes = ""
while args.count > 1, args[0] == "-p" || args[0] == "-c" {
  let (flag, value) = (args[0], args[1])
  args.removeFirst(2)
  if flag == "-p" {
    prefix = value
  } else {
    do {
      let text = try String(contentsOfFile: value, encoding: .utf8)
      notes += text.replacing(/\u{1B}\[[0-9;]*m/, with: "") + "\n"
    } catch {
      FileHandle.standardError.write(Data("fmsh: \(value): \(error.localizedDescription)\n".utf8))
      exit(1)
    }
  }
}
let request =
  args.isEmpty
  ? String(decoding: FileHandle.standardInput.readDataToEndOfFile(), as: UTF8.self)
  : args.joined(separator: " ")
let question = request.trimmingCharacters(in: .whitespacesAndNewlines)
guard !question.isEmpty else {
  FileHandle.standardError.write(
    Data("usage: fmsh [-p prefix] [-c notes.md]... [question] (or question on stdin)\n".utf8))
  exit(1)
}

let model = SystemLanguageModel.default
guard case .available = model.availability else {
  FileHandle.standardError.write(Data("fmsh: model unavailable: \(model.availability)\n".utf8))
  exit(2)
}

let shell =
  (ProcessInfo.processInfo.environment["SHELL"] ?? "zsh").split(separator: "/").last ?? "zsh"
let head = prefix.trimmingCharacters(in: .whitespaces)
var instructions = loadInstructions().replacingOccurrences(of: "{{shell}}", with: shell)
if !head.isEmpty { instructions += "\nEvery command starts with: \(head)" }

do {
  let prompt =
    notes.isEmpty ? question : "Reference notes:\n\(notes.prefix(8000))\nRequest: \(question)"
  func ask() async throws -> Suggestions {
    let session = LanguageModelSession(model: model, instructions: instructions)
    return try await session.respond(
      to: prompt, generating: Suggestions.self, options: GenerationOptions(temperature: 0.2)
    ).content
  }
  let reply: Suggestions
  do {
    reply = try await ask()
  } catch {
    reply = try await ask()
  }
  var seen = Set<String>()
  for raw in reply.commands {
    let c = raw.line.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !c.isEmpty, !c.contains(where: \.isNewline) else { continue }
    let cmd = head.isEmpty || c.hasPrefix(prefix) ? c : prefix + c
    if seen.insert(cmd).inserted { print(cmd) }
  }
} catch {
  FileHandle.standardError.write(Data("fmsh: \(error)\n".utf8))
  exit(3)
}
