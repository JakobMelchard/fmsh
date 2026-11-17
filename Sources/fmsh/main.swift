import Foundation
import FoundationModels

@Generable
struct Suggestions {
  @Guide(
    description: "Distinct complete one-line shell commands, most likely first", .maximumCount(3))
  var commands: [String]
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
var instructions = """
  You turn a request into shell commands for \(shell) on macOS.
  Give up to 3 distinct, complete, runnable one-line commands, most likely first.
  Give one when only one is reasonable. Commands only, no explanation, no markdown.
  """
if !head.isEmpty { instructions += "\nEvery command starts with: \(head)" }

do {
  let session = LanguageModelSession(instructions: instructions)
  let prompt =
    notes.isEmpty ? question : "Reference notes:\n\(notes.prefix(8000))\nRequest: \(question)"
  let reply = try await session.respond(to: prompt, generating: Suggestions.self)
  var seen = Set<String>()
  for raw in reply.content.commands {
    let c = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !c.isEmpty, !c.contains(where: \.isNewline) else { continue }
    let cmd = head.isEmpty || c.hasPrefix(prefix) ? c : prefix + c
    if seen.insert(cmd).inserted { print(cmd) }
  }
} catch {
  FileHandle.standardError.write(Data("fmsh: \(error)\n".utf8))
  exit(3)
}
