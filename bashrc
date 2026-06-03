# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

[ -d "$HOME/.local/bin" ] || mkdir ~/.local/bin
PATH="$PATH:$HOME/.local/bin"

if ! command -v eget &> /dev/null; then
    curl https://zyedidia.github.io/eget.sh | sh
    mv ./eget "$HOME/.local/bin"
fi

command -v fzf &> /dev/null || eget junegunn/fzf --to "$HOME/.local/bin"
command -v rg &> /dev/null || eget BurntSushi/ripgrep --to "$HOME/.local/bin"
command -v fx &> /dev/null || eget antonmedv/fx --to "$HOME/.local/bin"
command -v jq &> /dev/null || eget stedolan/jq --to "$HOME/.local/bin"
command -v yq &> /dev/null || eget mikefarah/yq --to "$HOME/.local/bin"
command -v fd &> /dev/null || eget sharkdp/fd --to "$HOME/.local/bin"
command -v cheat &> /dev/null || eget cheat/cheat --to "$HOME/.local/bin"
command -v bat &> /dev/null || eget sharkdp/bat --to "$HOME/.local/bin"
command -v lf &> /dev/null || eget gokcehan/lf --to "$HOME/.local/bin"
command -v webrpc &> /dev/null || eget webrpc/webrpc --to "$HOME/.local/bin"
command -v jc &> /dev/null || eget kellyjonbrazil/jc --to "$HOME/.local/bin"
command -v tty-copy &> /dev/null || eget jirutka/tty-copy --to "$HOME/.local/bin"
command -v stylua &> /dev/null || eget JohnnyMorganz/StyLua --to "$HOME/.local/bin"
command -v deno &> /dev/null || eget denoland/deno --to "$HOME/.local/bin"
command -v f2 &> /dev/null || eget ayoisaiah/f2 --to "$HOME/.local/bin"

[ -f "$HOME/.local/bin/z.sh" ] || curl https://raw.githubusercontent.com/rupa/z/master/z.sh -o "$HOME/.local/bin/z.sh"
. "$HOME/.local/bin/z.sh"

export VISUAL=nvim
export EDITOR="$VISUAL"

force_color_prompt=yes

bind 'set completion-ignore-case on'

alias v='nvim'
alias f='fish -i'
alias gaa='git add --all'
alias rg='rg --smart-case --glob="!coverage"'
alias bgd='kitty +kitten themes --reload-in=all One Dark'
alias bgl='kitty +kitten themes --reload-in=all Atom One Light'
alias howto="alias | grep $1"
alias hr='history -r' # reload history
alias ble='source ~/.ble.sh/out/ble.sh'

# Jump to previous directories with `j`
function j() {
  [ $# -gt 0 ] && _z "$*" && return
  cd "$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
}

function howto() {
  alias | grep "$1"
}

if [ -d ~/.local/share/junest ]; then
  export PATH="~/.local/share/junest/bin:$PATH"
  export PATH="$PATH:~/.junest/usr/bin_wrappers"
  [[ ~/.junest/usr/share/z/z.sh ]] && source ~/.junest/usr/share/z/z.sh
fi

set -o vi

export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=10000                    # big history
export HISTFILESIZE=10000                # big history
shopt -s histappend                      # append to history, don't overwrite it

# Remove all duplicates preserving the newest usage of the line
if command -v tac &> /dev/null; then
  new_history=$(tac ~/.bash_history | awk '!line_occurances_map[$0]++' | tac)
  echo "${new_history}" > ~/.bash_history
fi

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
[ -f ~/.aliases ] && source ~/.aliases
[ -f ~/.colors.sh ] && source ~/.colors.sh

# This Changes The PS1
export PROMPT_COMMAND=__prompt_command      # Func to gen PS1 after CMDs
function __prompt_command() {
  exit_code=$?
  prompt_char=$([ "${exit_code}" -eq 0 ] && echo "${green}\$${normal}" || echo "${red}\$${normal}")
  code_prompt=$([ "${exit_code}" -gt 0 ] && echo " ${red}${exit_code}")
  history -a

  PS1="\u@\h ${blue}\w${code_prompt}${purple}\$([ \j -gt 0 ] && echo ' {\j}')${normal}\n${prompt_char} "
}

[ -f ~/.bashrc_local ] && source ~/.bashrc_local

# Add support for Snap (go/snap-cl) and enable it by default. #!>>SNAP<<!#
if [[ -r /google/data/ro/teams/ix-ml/snap/config/bashrc ]] ; then #!>>SNAP<<!#
  source /google/data/ro/teams/ix-ml/snap/config/bashrc #!>>SNAP<<!#
fi #!>>SNAP<<!#
export SNAP_DEFAULT_FOR_SYNC=true #!>>SNAP<<!#
export SNAP_DEFAULT_FOR_NEW_WORKSPACE=true #!>>SNAP<<!#

