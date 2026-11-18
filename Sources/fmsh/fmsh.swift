import Foundation
import FoundationModels

enum ArgumentError: Error, Equatable {
  case fileReadFailed(path: String, message: String)
}

struct ParsedArguments: Equatable {
  var prefix: String
  var notes: String
  var remaining: [String]
}

func stripANSI(_ text: String) -> String {
  text.replacing(/\u{1B}\[[0-9;]*m/, with: "")
}

func parseArguments(
  _ arguments: [String],
  readFile: (String) throws -> String = { try String(contentsOfFile: $0, encoding: .utf8) }
) throws -> ParsedArguments {
  var args = arguments
  var prefix = ""
  var notes = ""
  while args.count > 1, args[0] == "-p" || args[0] == "-c" {
    let (flag, value) = (args[0], args[1])
    args.removeFirst(2)
    if flag == "-p" {
      prefix = value
    } else {
      do {
        let text = try readFile(value)
        notes += stripANSI(text) + "\n"
      } catch {
        throw ArgumentError.fileReadFailed(path: value, message: error.localizedDescription)
      }
    }
  }
  return ParsedArguments(prefix: prefix, notes: notes, remaining: args)
}

func resolveShell(_ rawShell: String?) -> String {
  String((rawShell ?? "zsh").split(separator: "/").last ?? "zsh")
}

func renderInstructions(template: String, shell: String, prefix: String) -> String {
  let head = prefix.trimmingCharacters(in: .whitespaces)
  var instructions = template.replacingOccurrences(of: "{{shell}}", with: shell)
  if !head.isEmpty { instructions += "\nEvery command starts with: \(head)" }
  return instructions
}

func buildPrompt(question: String, notes: String) -> String {
  notes.isEmpty ? question : "Reference notes:\n\(notes.prefix(8000))\nRequest: \(question)"
}

func normalizeCandidates(_ lines: [String], prefix: String) -> [String] {
  let head = prefix.trimmingCharacters(in: .whitespaces)
  var seen = Set<String>()
  var result: [String] = []
  for raw in lines {
    let c = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !c.isEmpty, !c.contains(where: \.isNewline) else { continue }
    let cmd = head.isEmpty || c.hasPrefix(prefix) ? c : prefix + c
    if seen.insert(cmd).inserted { result.append(cmd) }
  }
  return result
}

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

@main
struct Fmsh {
  static func main() async {
    let parsed: ParsedArguments
    do {
      parsed = try parseArguments(Array(CommandLine.arguments.dropFirst()))
    } catch let ArgumentError.fileReadFailed(path, message) {
      FileHandle.standardError.write(Data("fmsh: \(path): \(message)\n".utf8))
      exit(1)
    } catch {
      FileHandle.standardError.write(Data("fmsh: \(error.localizedDescription)\n".utf8))
      exit(1)
    }

    let request =
      parsed.remaining.isEmpty
      ? String(decoding: FileHandle.standardInput.readDataToEndOfFile(), as: UTF8.self)
      : parsed.remaining.joined(separator: " ")
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

    let shell = resolveShell(ProcessInfo.processInfo.environment["SHELL"])
    let instructions = renderInstructions(
      template: loadInstructions(), shell: shell, prefix: parsed.prefix)
    let prompt = buildPrompt(question: question, notes: parsed.notes)

    do {
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
      for cmd in normalizeCandidates(reply.commands.map(\.line), prefix: parsed.prefix) {
        print(cmd)
      }
    } catch {
      FileHandle.standardError.write(Data("fmsh: \(error)\n".utf8))
      exit(3)
    }
  }
}
