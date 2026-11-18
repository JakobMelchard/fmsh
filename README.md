# fmsh

## Purpose
- Demonstrates structured shell-command generation with Apple's on-device Foundation Models API.
- Prints up to three candidates, most likely first, one command per line. Never executes suggestions.

## Usage
Requires macOS 26+, Apple silicon and Apple Intelligence enabled:

```sh
git clone https://github.com/lilfeelz/fmsh.git
cd fmsh
swift build -c release
.build/release/fmsh 'find files larger than 100 MB'
printf '%s\n' 'list hidden files' | .build/release/fmsh
```

- Syntax: `fmsh [-p prefix] [-c notes.md]... [question]`; reads stdin when question is omitted.
- `-p` preserves a command prefix; repeated `-c` adds notes, limited to 8,000 characters in the prompt.
- Instructions: `Sources/fmsh/instructions.md`, embedded at build; `{{shell}}` expands to the shell name.
- Override: nonempty `FMSH_INSTRUCTIONS` (file path) takes precedence and exits `1` if unreadable; otherwise use `$XDG_CONFIG_HOME/fmsh/instructions.md` (default `~/.config`) when readable, else embedded defaults.
- Exit codes: `1` invalid input/file read; `2` model unavailable; `3` generation failed after one retry.
- Generation uses the on-device model, not a remote API. Candidates are not validated and may be invalid or unsafe; review before running.

Install the released binary:

```sh
mkdir -p ~/.local/bin
curl -fsSL https://github.com/lilfeelz/fmsh/releases/latest/download/fmsh -o ~/.local/bin/fmsh
chmod +x ~/.local/bin/fmsh
```

Add `~/.local/bin` to `PATH`; invoke `fmsh` directly or pipe its output to a command picker.

## Layout
```text
Sources/fmsh/fmsh.swift       # parse input, prompt model, normalize candidates
Sources/fmsh/instructions.md  # embedded default model instructions
Plugins/EmbedInstructions/   # Swift build-tool plugin
Scripts/embed-instructions.sh # generates the embedded Swift string
Tests/fmshTests/              # parsing, prompts, normalization and ANSI tests
.github/workflows/           # macOS CI, hooks, release binary and review automation
```

## Operate
- Owner: lilfeelz. Local CLI, no server or deployment service.
- Deploy: build locally or install the release asset above.
- Rollback: replace the binary with a previously downloaded release; no built-in rollback command.
- CI: macOS 26 release build and model-availability smoke test, plus shared hooks; model-unavailable exit `2` is accepted.
- Release-please owns versioning; release workflow builds and attaches `fmsh` to the GitHub release.

```sh
swift test
swift build -c release
swift format lint --strict --recursive Sources Tests Plugins
prek run --all-files
```

## Dependencies
- Swift 6.2+ / macOS 26 SDK, Foundation and FoundationModels; no external Swift packages.
- Apple Intelligence model availability depends on hardware, settings and model download.
- Development hooks: prek and tools declared in `.pre-commit-config.yaml`.

## Status
- Live: released CLI with deterministic unit tests; useful model output depends on local availability. Planned: retain as an on-device AI showcase.
