# fmsh

Shell commands from Apple's on-device model.

```sh
fmsh [-p prefix] [-c notes.md]... [question]   # question on stdin when omitted
```

Prints up to three candidate commands, one per line, most likely first. `-p` is what is already
typed; every candidate starts with it. `-c` adds a notes file as context. Exit 2 when the model is
unavailable. Needs macOS 26 on Apple silicon with Apple Intelligence on. Nothing leaves the machine.

```sh
mkdir -p ~/.local/bin && curl -fsSL https://github.com/JakobMelchard/fmsh/releases/latest/download/fmsh -o ~/.local/bin/fmsh && chmod +x ~/.local/bin/fmsh
```

zsh, ctrl-x ctrl-x: describe the command in nvim, pick the answer in fzf, it lands in the prompt.

```zsh
fmsh-ask() {
  local f=$(mktemp -t fmsh) q pick
  zle -I
  nvim "$f" </dev/tty >/dev/tty
  q=$(<"$f"); rm -f -- "$f"
  [[ -n ${q//[[:space:]]/} ]] || { zle reset-prompt; return }
  pick=$(print -r -- "$q" | fmsh -p "$BUFFER" | fzf --no-sort --select-1 --exit-0) &&
    [[ -n $pick ]] && BUFFER=$pick CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fmsh-ask
bindkey '^X^X' fmsh-ask
```

```sh
brew install prek && prek install
swift build -c release
```
