# vim: filetype=zsh autoindent smartindent expandtab tabstop=2 softtabstop=2 shiftwidth=2 shiftround

# =============================================================================
# Basic Configuration
# =============================================================================

export LANG=ja_JP.UTF-8

autoload -Uz colors
colors
setopt globdots

# =============================================================================
# Completion System
# =============================================================================

if [ -f /usr/share/zsh/plugins/zsh-completions/zsh-completions.zsh ]; then
  fpath=($fpath /usr/share/zsh/plugins/zsh-completions/src)
fi
if [ -d "$HOME/.zsh/completion" ]; then
  fpath=($fpath $HOME/.zsh/completion)
fi
if [ -d "$HOME/.zsh/zsh-completions/src" ]; then
  fpath=($fpath $HOME/.zsh/zsh-completions/src)
fi
autoload -Uz compinit
compinit

# Completion menu selection with arrow keys
zstyle ':completion:*:default' menu select=2

# =============================================================================
# Helper Functions for Plugin Loading
# =============================================================================

# Source a plugin from multiple possible locations
_source_plugin() {
  local plugin_name="$1"
  shift
  local locations=("$@")

  for location in "${locations[@]}"; do
    if [ -f "$location" ]; then
      source "$location"
      return 0
    fi
  done
  return 1
}

# =============================================================================
# Plugins
# =============================================================================

# zsh-autosuggestions
_source_plugin "zsh-autosuggestions" \
  "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting (should be sourced at the end of plugins)
_source_plugin "zsh-syntax-highlighting" \
  "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# =============================================================================
# History Configuration
# =============================================================================

bindkey -e
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt append_history
setopt hist_expand
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_verify
setopt inc_append_history
setopt share_history
setopt noautoremoveslash

# =============================================================================
# Key Bindings
# =============================================================================

# Ctrl+r for incremental history search backward, Ctrl+s for forward
bindkey '^r' history-incremental-pattern-search-backward
bindkey '^s' history-incremental-pattern-search-forward

# Disable Ctrl+s lock and Ctrl+q unlock
setopt no_flow_control

# History search with partial command input
# Example: type 'ls' then Ctrl+p to search backward through ls commands
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^b" history-beginning-search-forward-end

# Ctrl+x Ctrl+e to edit the current command line in $VISUAL/$EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# =============================================================================
# Word Style Configuration
# =============================================================================

autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars " '\"/=;@:{}[]()<>,|."
zstyle ':zle:*' word-style unspecified

# =============================================================================
# Zsh Advanced Features
# =============================================================================

# cdr command for directory history (persistent across sessions)
autoload -Uz add-zsh-hook
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ":chpwd:*" recent-dirs-default true

# zmv for multiple file operations (e.g., zmv *.txt *.txt.bk)
autoload -Uz zmv

# =============================================================================
# OS Detection
# =============================================================================

if [[ "$OSTYPE" == "darwin"* ]]; then
  IS_MACOS=1
  IS_LINUX=0
else
  IS_MACOS=0
  IS_LINUX=1
fi

# =============================================================================
# Aliases
# =============================================================================

# OS-specific aliases
if [[ $IS_MACOS -eq 1 ]]; then
  # macOS aliases
  if builtin command -v gls >/dev/null 2>&1; then
    alias ls='gls --group-directories-first --color=auto'
    alias dir='gdir --color=auto'
    alias vdir='gvdir --color=auto'
  else
    alias ls='ls -G'
    alias dir='ls -G'
    alias vdir='ls -lG'
  fi
  alias open='open'
else
  # Linux aliases
  alias ls='ls --group-directories-first --color=auto'
  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'
  alias open='xdg-open'
fi
# lsd overrides (if available)
if builtin command -v lsd >/dev/null 2>&1; then
  alias ls='lsd --group-dirs first'
  alias ll='lsd -al --group-dirs first'
  alias la='lsd -A --group-dirs first'
  alias al='lsd -al --group-dirs first'
  alias l='lsd --group-dirs first --icon=never'
fi

# Common aliases
alias grep='grep --color=auto'
alias lu='ls -U1'
alias s='screen -DRR'
alias zmv='noglob zmv -W'

# =============================================================================
# Environment Variables
# =============================================================================
export VISUAL=nvim
export EDITOR="$VISUAL"
export LESSCHARSET=utf-8

# Keep pager output on screen (stop clearing on exit)
# -X: don't use terminal init/deinit (no alt screen); -R: show colors safely
export LESS="-R -X"
export PAGER=less
export MANPAGER='less -X'

# =============================================================================
# PATH Configuration
# =============================================================================

# Initialize PATH with base directories
export PATH="/opt/bin:$HOME/bin:$PATH"

# macOS specific paths
if [[ $IS_MACOS -eq 1 ]]; then
  # GNU coreutils for macOS
  if [ -d /usr/local/opt/coreutils/libexec/gnubin ]; then
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
  fi
  if [ -d /opt/homebrew/opt/coreutils/libexec/gnubin ]; then
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
  fi
fi

# mise (development tool version manager)
export PATH="$HOME/.local/bin:$PATH"
if builtin command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Go configuration
if [ -z "$GOPATH" -a -d "$HOME/go" ]; then
  export GOPATH="$HOME/go"
fi
if [ -n "$GOROOT" ]; then
  export PATH="$GOROOT/bin:$PATH"
fi

# Ruby gem
if builtin type gem >/dev/null 2>&1; then
  local user_gemhome="$(gem environment user_gemhome 2>/dev/null)"
  if [ -n "$user_gemhome" ]; then
    export PATH="$PATH:$user_gemhome/bin"
  fi
fi

# Local user directories
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.vim/bin:$PATH"

# Jetbrains IDE
export PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"

# Turso
export PATH="$PATH:$HOME/.turso"

# Clean up and normalize the PATH
eval export "$( LC_ALL=C perl -CIO ~/.config/shell/organize_path.pl )"

# =============================================================================
# dircolors Configuration
# =============================================================================

if [ -e ~/.dircolors ]; then
  if [[ $IS_MACOS -eq 1 ]]; then
    # macOS with GNU dircolors
    if builtin command -v gdircolors >/dev/null 2>&1; then
      eval "$(gdircolors -b ~/.dircolors)"
      zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
    fi
  else
    # Linux with dircolors
    if builtin command -v dircolors >/dev/null 2>&1; then
      eval "$(dircolors -b ~/.dircolors)"
      zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
    fi
  fi
fi

# =============================================================================
# External Tools Integration
# =============================================================================

# npm completion
if builtin type npm >/dev/null 2>&1; then
  source <(npm completion)
fi

# Python startup file
if [ -z "$PYTHONSTARTUP" -a -s "$HOME/.pythonstartup" ]; then
  export PYTHONSTARTUP="$HOME/.pythonstartup"
fi

# X11 forwarding (Linux only)
if [[ $IS_LINUX -eq 1 ]]; then
  if builtin type xhost >/dev/null 2>&1; then
    xhost +local:root > /dev/null 2>&1
  fi
fi

# =============================================================================
# VCS/Git Configuration
# =============================================================================

autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' use-simple true

# =============================================================================
# Terminal Integration
# =============================================================================

# WezTerm: Enable ScrollToPrompt with Shift+Up/Down
if [ -n "$WEZTERM_EXECUTABLE" ] 2>/dev/null; then
  wezterm_precmd() {
    printf '\033]133;A\007'
  }
  add-zsh-hook precmd wezterm_precmd 2>/dev/null || true
fi

# =============================================================================
# Utility Functions
# =============================================================================

# Resize terminal window
if builtin command -v resize >/dev/null 2>&1; then
  rs() {
    eval `resize`
  }
else
  rs() {
    kill -s WINCH $$
  }
fi

# GNU screen: Update working directory
if [ -n "$STY" ]; then
  scr_cd() {
    cd "$@"
    screen -X chdir "$PWD"
  }
  alias cd=scr_cd
fi


# Cut to terminal width
ccol() {
  cut -c1-${COLUMNS}
}

# Open nvim in the current directory, or the given files (Omarchy `n`)
n() {
  if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi
}

# Clear screen with banner
cls() {
  if builtin type banner >/dev/null 2>&1; then
    banner --width=$(tput cols) $(date "+%Y-%m-%d-%H:%M")
  fi
  perl -e 'print "\n"x`tput lines`'
}

# Docker: Stop all containers
stopcontainers() {
  set -x
  docker ps -a
  docker ps -a | perl -nle 'print((split)[-1]) if $.>1' | xargs --no-run-if-empty docker stop
  docker ps -a | perl -nle 'print((split)[-1]) if $.>1' | xargs --no-run-if-empty docker rm
  set +x
}

# Docker: Remove all containers
removecontainers() {
  stopcontainers
  docker system prune -f
  docker volume ls -f dangling=true --format "{{ .Name }}" | grep -E '^[a-z0-9]{64}$' | xargs --no-run-if-empty docker volume rm
}

# Docker: Remove everything
armaggedon() {
  removecontainers
  docker network prune -f
  docker rmi -f $(docker images --filter dangling=true -qa)
  docker volume rm $(docker volume ls --filter dangling=true -q)
  docker rmi -f $(docker images -qa)
  docker system prune -f -a
}

# Run Alpine Linux in Docker
alprun() {
  touch $HOME/ash_history .ash_history
  docker run --rm -it -v $HOME/ash_history:/work/.ash_history \
  -v $(pwd):/work -w /work alpine:latest \
  sh -c "addgroup -g `id -g` people;
  adduser -D -G people -h /work -u `id -u` person;
  apk add --no-cache sudo;
  echo '%people ALL=(ALL) NOPASSWD: ALL'>>/etc/sudoers;
  su - person"
  [ "$HOME" = $(pwd) ] || rm -f .ash_history
}

# Run Debian in Docker (for development)
debrun() {
  touch $HOME/bash_history .bash_history
  docker run --rm -it -v $HOME/bash_history:/work/.bash_history \
  -v $(pwd):/work -w /work debian:latest \
  sh -c "groupadd -g `id -g` people;
  useradd -u `id -u` -g people -s /bin/bash -d /work person;
  apt-get update; apt-get install -y --no-install-recommends sudo $@;
  echo '%people ALL=(ALL) NOPASSWD: ALL'>>/etc/sudoers;
  su - person"
  [ "$HOME" = $(pwd) ] || rm -f .bash_history
}

# Extract various archive formats
ex() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1       ;;
      *.tar.gz)    tar xzf $1       ;;
      *.bz2)       bunzip2 $1       ;;
      *.rar)       unrar x $1       ;;
      *.gz)        gunzip $1        ;;
      *.tar)       tar xf $1        ;;
      *.tbz2)      tar xjf $1       ;;
      *.tgz)       tar xzf $1       ;;
      *.zip)       unzip -u sjis $1 ;;
      *.Z)         uncompress $1    ;;
      *.7z)        7z x $1          ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Reload shell
reload() {
  exec "${SHELL}" "$@"
}

# Set terminal title
termtitle() {
  case "$TERM" in
    rxvt*|xterm*|nxterm|gnome|screen|screen-*|st|st-*|alacritty*|tmux*|foot*|kitty*|wezterm*)
      local prompt_host="${(%):-%m}"
      local prompt_user="${(%):-%n}"
      local prompt_char="${(%):-%~}"
      case "$1" in
        precmd)
          printf '\e]0;%s@%s: %s\a' "${prompt_user}" "${prompt_host}" "${prompt_char}"
          ;;
        preexec)
          printf '\e]0;%s [%s@%s: %s]\a' "$2" "${prompt_user}" "${prompt_host}" "${prompt_char}"
          ;;
      esac
      ;;
  esac
}

# Clipboard copy: Wayland -> wl-copy, otherwise xclip (X11 etc.)
clipcopy() {
  if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  else
    xclip -selection clipboard
  fi
}

# Search shell history with peco
# Usage: hs [query]
hs() {
  cat ~/.zsh_history* ~/.bash_history* | col -bfx | sed -re 's/^: [^;]+//g' -e 's/^;//g' | sort | uniq | peco --query "$*" | tr -d '\n' | clipcopy
}

# =============================================================================
# Prompt and Hooks
# =============================================================================

# Custom precmd and preexec functions
custom_precmd() {
  termtitle precmd
  vcs_info
}

custom_preexec() {
  termtitle preexec "${(V)1}"
}

# Add custom functions to hook arrays (oh-my-zsh compatible)
if [[ -n "${precmd_functions}" ]]; then
  # oh-my-zsh is loaded, use hook arrays
  precmd_functions+=(custom_precmd)
  preexec_functions+=(custom_preexec)
else
  # Fallback to direct function definition
  precmd() { custom_precmd "$@" }
  preexec() { custom_preexec "$@" }
fi

# Periodic function: Show git stash list every 10 minutes
PERIOD=600
periodic() {
  # Check if git command exists
  if ! builtin command -v git >/dev/null 2>&1; then
    return
  fi

  # Check if inside a git repository
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local stashes="$(git stash list)"
    if [ -n "${stashes}" ]; then
      echo "----------------------------------------"
      echo -e "\033[34m"
      echo "${stashes}"
      echo -e "\033[m"
      echo ""
    fi
  fi
}

# Set prompt
PROMPT='[%1~]${vcs_info_msg_0_}'$'\n[%n@%m]$ '

# =============================================================================
# Starship Configuration
# =============================================================================

if builtin command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# AI agent aliases and tmux dev layouts
[ -e $HOME/.zshrc_ai ] && . $HOME/.zshrc_ai

# =============================================================================
# Local Configuration
# =============================================================================

[ -e $HOME/.zshrc_local ] && . $HOME/.zshrc_local

