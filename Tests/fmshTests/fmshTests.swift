import Foundation
import Testing

@testable import fmsh

@Suite("fmsh Tests")
struct FmshTests {
  @Test("ANSI escape sequences are stripped")
  func ansiStripping() {
    #expect(stripANSI("\u{1B}[31merror\u{1B}[0m: \u{1B}[1;32mok\u{1B}[m") == "error: ok")
    #expect(stripANSI("plain text") == "plain text")
  }

  @Test("CLI argument parsing handles -p, multiple -c flags, and remaining words")
  func argumentParsing() throws {
    let files: [String: String] = [
      "a.md": "\u{1B}[32mfirst note\u{1B}[0m",
      "b.md": "second note",
    ]
    let parsed = try parseArguments(
      ["-p", "git ", "-c", "a.md", "-c", "b.md", "list", "branches"],
      readFile: { path in
        guard let text = files[path] else {
          throw NSError(domain: NSCocoaErrorDomain, code: 260)
        }
        return text
      }
    )
    #expect(parsed.prefix == "git ")
    #expect(parsed.notes == "first note\nsecond note\n")
    #expect(parsed.remaining == ["list", "branches"])
  }

  @Test("CLI argument parsing throws when -c file cannot be read")
  func argumentParsingMissingFile() {
    #expect(throws: ArgumentError.self) {
      _ = try parseArguments(
        ["-c", "missing.md", "query"],
        readFile: { _ in throw NSError(domain: NSCocoaErrorDomain, code: 260) }
      )
    }
  }

  @Test("Instruction rendering substitutes {{shell}} and appends non-empty prefix")
  func instructionRendering() {
    let tpl = "Shell is {{shell}}."
    #expect(
      renderInstructions(template: tpl, shell: "zsh", prefix: "")
        == "Shell is zsh."
    )
    #expect(
      renderInstructions(template: tpl, shell: "fish", prefix: "   ")
        == "Shell is fish."
    )
    #expect(
      renderInstructions(template: tpl, shell: "bash", prefix: "git commit ")
        == "Shell is bash.\nEvery command starts with: git commit"
    )
    #expect(resolveShell("/bin/zsh") == "zsh")
    #expect(resolveShell(nil) == "zsh")
  }

  @Test("Candidate normalization enforces prefix, filters newlines, and deduplicates")
  func candidateNormalization() {
    let raw = [
      "  status -s  ",
      "git status -s",
      "log --oneline\nrm -rf /",
      "   ",
      "diff --staged",
    ]
    let normalized = normalizeCandidates(raw, prefix: "git ")
    #expect(normalized == ["git status -s", "git diff --staged"])

    let noPrefix = normalizeCandidates([" ls -la ", "ls -la", "pwd\nwhoami"], prefix: "  ")
    #expect(noPrefix == ["ls -la"])
  }
}
