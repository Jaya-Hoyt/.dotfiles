export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
# start fish shell
WHICH_FISH="$(which fish)"
if [[ "$-" =~ i && -x "${WHICH_FISH}" && ! "${SHELL}" -ef "${WHICH_FISH}" ]]; then
  # Safeguard to only activate fish for interactive shells and only if fish
  # shell is present and executable. Verify that this is a new session by
  # checking if $SHELL is set to the path to fish. If it is not, we set
  # $SHELL and start fish.
  #
  # If this is not a new session, the user probably typed 'bash' into their
  # console and wants bash, so we skip this.
  exec env SHELL="${WHICH_FISH}" "${WHICH_FISH}" -i
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if hash rg 2>/dev/null; then
  export FZF_DEFAULT_COMMAND='rg -S --files --no-ignore-vcs --hidden --glob="!bin" --glob="!build" --glob="!node_modules"'
fi

# Setting Environment Variables
set -o ignoreeof
export VISUAL=nvim
export EDITOR="$VISUAL"
export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}
export NIXPKGS_ALLOW_UNFREE=1
export PATH="${HOME}/.nix-profile/bin:${PATH}"
export PATH="/nix/var/nix/profiles/default/bin:${PATH}"
HYPHEN_INSENSITIVE="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=white'

# For `..` `...` `....`
setopt autocd

# History search on up/down arrow
bindkey "^[OA" history-beginning-search-backward
bindkey "^[OB" history-beginning-search-forward


# Aliases
alias f="fish -i"
alias init-venv="python -m virtualenv venv"
alias init-venv3="python3 -m virtualenv venv"
alias activate="source venv/bin/activate"
alias stop="pkill -f "
alias zshconfig="vim ~/.zshrc"
alias howto="alias | grep $1"
alias fz='vim $(fzf)'
alias v='vim'
alias dps='docker ps'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcb='docker-compose build --no-cache'
alias dcd='docker-compose down'
alias dcs='docker-compose stop'
alias dsh='docker exec -it $1 /bin/bash'
alias rm-containers='docker container rm $(docker container ls -aq)'
alias rm-images='docker image prune -a'
alias xml='tidy -xml -i -q <<<'
alias xmlp='pbpaste | tidy -xml -i -q'
alias vim='nvim'
unalias rg 2>/dev/null
alias rg='rg --smart-case --glob="!coverage"'
alias bgd='kitty +kitten themes --reload-in=all One Dark'
alias bgl='kitty +kitten themes --reload-in=all Atom One Light'

cht() {
  curl cht.sh/${1} | less -r
}

java-run() {
  local filename="$1"
  local args=(${@:2})
  javac -d bin -cp bin:/usr/share/maven-repo/junit/junit/4.x/junit-4.x.jar "$filename"
  java -cp bin ${filename%.*} $args
}

junit() {
  local filename="$1"
  javac -d bin -cp bin:/usr/share/maven-repo/junit/junit/4.x/junit-4.x.jar ${filename}
  java -cp bin:/usr/share/maven-repo/junit/junit/4.x/junit-4.x.jar org.junit.runner.JUnitCore ${filename%.*}
}

# Set light/dark theme based on macos theme
if command -v kitty &> /dev/null; then
  if defaults read -g AppleInterfaceStyle &>/dev/null; then
    kitty +kitten themes --reload-in=all One Dark
  else
    kitty +kitten themes --reload-in=all Atom One Light
  fi
fi

split() {
  tr $1 '\n'
}

# Jump to previous directories with `j`
unalias z 2> /dev/null
j() {
  [ $# -gt 0 ] && _z "$*" && return
  cd "$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
}

# Search for a command from history and print it out
hs() {
    cat ~/.zsh_history | cut -d ';' -f 2- | fzf
}

# Search and execute a command from history
h() {
    eval $(hs)
}

# Fuzzy find and install a package from a debian-based OS
apt-install() {
  local app=$(apt-cache pkgnames | fzf)
  if [ $app ]; then
    sudo apt-get install $app
  fi
}


nix-search() {
  local app=$(nix search --extra-experimental-features "nix-command flakes" nixpkgs $1 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | cut -d " " -f2 | awk 'NF' | sed -r "s/legacyPackages.aarch64-darwin.//" |sed -r "s/legacyPackages.x86_64-linux.//" | fzf --query $1)

  if [ $app ]; then
    nix-env -iA nixpkgs.${app}
  fi
}

# Install (one or multiple) selected application(s)
# using "brew search" as source input
# mnemonic [B]rew [I]nstall [P]lugin
bip() {
  local app=$(brew formulae | fzf -m)
  if [ $app ]; then
    brew install $app
  fi
}

# Update (one or multiple) selected application(s)
# mnemonic [B]rew [U]pdate [P]lugin
bup() {
  local app=$(brew leaves | fzf -m)
  if [ -n "$app" ]; then
    brew upgrade "$app"
  fi
}

# Delete (one or multiple) selected application(s)
# mnemonic [B]rew [C]lean [P]lugin (e.g. uninstall)
bcp() {
  local app=$(brew leaves | fzf -m)
  if [ -n "$app" ]; then
    brew uninstall "$app"
  fi
}

# Install (one or multiple) selected application(s)
# using "brew search" as source input
# mnemonic [C]ask [I]nstall [P]lugin
cip() {
  local app=$(brew casks | fzf -m)
  if [ -n "$app" ]; then
    brew install --cask "$app"
  fi
}

# Delete (one or multiple) selected application(s)
# mnemonic [C]ask [C]lean [P]lugin (e.g. uninstall)
ccp() {
  local app=$(brew list --cask | fzf -m)
  if [ -n "$app" ]; then
    brew uninstall "$app"
  fi
}

# List all the applications installed with brew
brew-apps() {
  brew bundle dump --no-restart --file -
}


### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
  command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
  command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
    print -P "%F{33} %F{34}Installation successful.%f%b" || \
    print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zi light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

# Theme
zi ice depth=1
zi light romkatv/powerlevel10k

zinit lucid for \
  atinit"HIST_STAMPS=dd.mm.yyyy" \
  OMZL::history.zsh \


# Load first
zinit wait lucid for \
  OMZL::clipboard.zsh \
  OMZL::compfix.zsh \
  OMZL::completion.zsh \
  OMZL::correction.zsh \
  OMZL::directories.zsh \
  OMZL::git.zsh \
  OMZL::grep.zsh \
  OMZL::key-bindings.zsh \
  OMZL::spectrum.zsh \
  OMZL::termsupport.zsh \
  OMZP::git \
  OMZ::plugins/git-auto-fetch/git-auto-fetch.plugin.zsh \
  OMZP::fzf

# Load And Initialize The Completion System Ignoring Insecure Directories With A
# Cache Time Of 24 Hours, So It Should Almost Always Regenerate The First Time A
# Shell Is Opened Each Day.
# See: https://gist.github.com/ctechols/ca1035271ad134841284
autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C


# Load second
zi wait'0a' lucid light-mode for \
  ver'develop' atinit'ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' atload'_zsh_autosuggest_start' \
    zsh-users/zsh-autosuggestions \
  zsh-users/zsh-syntax-highlighting


# Load third
zi wait'0b' lucid light-mode for \
  softmoth/zsh-vim-mode \
  rupa/z \
  from"gh-r" as"program" \
    @junegunn/fzf \
  as"command" from"gh-r" mv"ripgrep* -> rg" pick"rg/rg" \
    BurntSushi/ripgrep \
  as"command" from"gh-r" mv"fd* -> fd" pick"fd/fd" \
    @sharkdp/fd

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [ -f ~/.zshrc_local ]; then
    source ~/.zshrc_local
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Add support for Snap (go/snap-cl) and enable it by default. #!>>SNAP<<!#
if [[ -r /google/data/ro/teams/ix-ml/snap/config/bashrc ]] ; then #!>>SNAP<<!#
  source /google/data/ro/teams/ix-ml/snap/config/bashrc #!>>SNAP<<!#
fi #!>>SNAP<<!#
export SNAP_DEFAULT_FOR_SYNC=true #!>>SNAP<<!#
export SNAP_DEFAULT_FOR_NEW_WORKSPACE=true #!>>SNAP<<!#

