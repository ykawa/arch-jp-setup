# vim: filetype=sh autoindent smartindent expandtab tabstop=2 softtabstop=2 shiftwidth=2 shiftround
#exec 4>> $HOME/debug_output.txt
#BASH_XTRACEFD=4
#PS4='$LINENO: '
#set -x

case $- in
  *i*) ;;
  *) return;;
esac

shopt -s checkwinsize
shopt -s expand_aliases
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=100000
HISTFILESIZE=100000
HISTIGNORE='ls:pwd:exit'

# ウィンドウタイトルの設定は zoxide 等のフック登録後に行う (ファイル末尾参照)
PROMPT_COMMAND='history -a; history -c; history -r'

# Fallback to basic prompt if bash-it is not available
short_host_name() {
  local len=${#HOSTNAME}
  if [ $len -gt 8 ]; then
    echo "${HOSTNAME:0:4}${HOSTNAME:$len-4:4}"
  else
    echo "${HOSTNAME}"
  fi
}

PS1="[\u@$(short_host_name) \W]$ "
unset -f short_host_name

# Load basic bash completion
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
fi

# --- fzf: キーバインド＆補完 ---
if [ -f /usr/share/fzf/key-bindings.bash ]; then
  . /usr/share/fzf/key-bindings.bash
fi
if [ -f /usr/share/fzf/completion.bash ]; then
  . /usr/share/fzf/completion.bash
fi

eval "$(dircolors -b 2>/dev/null || true)"

# -- coreutils for macos
if [ -d /usr/local/opt/coreutils/libexec/gnubin ]; then
  export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
fi

[ builtin type lesspipe >/dev/null 2>&1 ] && eval "$(SHELL=/bin/sh lesspipe)"

# OS detection
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS specific settings
  if builtin type gdircolors >/dev/null 2>&1; then
    if [ -e ~/.dircolors ]; then
      eval "$(gdircolors -b ~/.dircolors)"
    fi
  fi

  # macOS aliases (using GNU coreutils if available)
  if builtin type gls >/dev/null 2>&1; then
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
  # Linux specific settings
  if builtin type dircolors >/dev/null 2>&1; then
    if [ -e ~/.dircolors ]; then
      eval "$(dircolors -b ~/.dircolors)"
    fi
  fi

  # Linux aliases
  alias ls='ls --group-directories-first --color=auto'
  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'
  alias open='xdg-open'
fi

# Common aliases
alias grep='grep --color=auto'
alias s='screen -DRR'

# lsd overrides (if available)
if builtin command -v lsd >/dev/null 2>&1; then
  alias ls='lsd --group-dirs first'
  alias ll='lsd -al --group-dirs first'
  alias la='lsd -A --group-dirs first'
  alias al='lsd -al --group-dirs first'
  alias l='lsd --group-dirs first --icon=never'
fi

if builtin type stty >/dev/null 2>&1; then
  stty werase undef
  stty stop undef
fi
bind "\C-w":unix-filename-rubout

export VISUAL=nvim
export EDITOR="$VISUAL"
export LESSCHARSET=utf-8

# X11 forwarding (Linux only)
if [[ "$OSTYPE" != "darwin"* ]]; then
  xhost +local:root > /dev/null 2>&1
fi
complete -cf sudo

export PATH="/opt/bin:$HOME/bin:$PATH"

# -- mise
export PATH="$HOME/.local/bin:$PATH"
if builtin type mise >/dev/null 2>&1; then
  export MISE_HOOK_ENV_CHPWD_ONLY=1
  export MISE_HOOK_ENV_CACHE_TTL=60s

  eval "$(mise activate bash)"

  export PATH="$HOME/.local/bin:$PATH"
  export MISE_HOOK_ENV_CHPWD_ONLY=1
  export MISE_HOOK_ENV_CACHE_TTL=60s
fi

# -- npm completion (if npm is available)
if builtin type npm >/dev/null 2>&1; then
  source <(npm completion)
fi

# -- PYTHONSTARTUP
if [ -z "$PYTHONSTARTUP" -a -s "$HOME/.pythonstartup" ]; then
  export PYTHONSTARTUP="$HOME/.pythonstartup"
fi

# -- GNU Global
if [ ! -f $HOME/.globalrc ]; then
  if [ -x /usr/local/bin/gtags ]; then
    export GTAGSCONF=/usr/local/share/gtags/gtags.conf
  fi
  if builtin type pygmentize >/dev/null 2>&1; then
    export GTAGSLABEL=pygments
  fi
fi

# -- GO
if [ -z "$GOPATH" -a -d "$HOME/go" ]; then
  export GOPATH="$HOME/go"
fi

if [ -n "$GOROOT" ]; then
  export PATH="$GOROOT/bin:$PATH"
fi

# -- gem (if gem is available)
if builtin type gem >/dev/null 2>&1; then
  user_gemhome="$(gem environment user_gemhome 2>/dev/null)"
  if [ -n "$user_gemhome" ]; then
    export PATH="$PATH:$user_gemhome/bin"
  fi
fi

# -- local env
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.vim/bin:$PATH"
export PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"

[ -e $HOME/.bashrc_local ] && . $HOME/.bashrc_local

# -------------------------------------------
# clean up and normalize the PATH.
# -------------------------------------------
eval export "$( LC_ALL=C perl -CIO ~/.config/shell/organize_path.pl )"

# -------------------------------------------
if builtin type resize >/dev/null 2>&1; then
  rs() {
    eval `resize`
  }
else
  rs() {
    kill -s WINCH $$
  }
fi

# -- gnu screen
if [ -n "$STY" ]; then
  scr_cd()
  {
    cd "$@"
    screen -X chdir "$PWD"
  }
  alias cd=scr_cd
fi

ccol() {
  cut -c1-${COLUMNS}
}

cls() {
  if builtin type banner >/dev/null 2>&1; then
      banner --width=$(tput cols) $(date "+%Y-%m-%d-%H:%M")
  fi
  perl -e 'print "\n"x`tput lines`'
}

# stop everything Docker containers
stopcontainers() {
  set -x
  docker ps -a
  docker ps -a | perl -nle 'print((split)[-1]) if $.>1' | xargs --no-run-if-empty docker stop
  docker ps -a | perl -nle 'print((split)[-1]) if $.>1' | xargs --no-run-if-empty docker rm
  set +x
}

# remove everything Docker containers
removecontainers() {
  stopcontainers
  docker system prune -f
  docker volume ls -f dangling=true --format "{{ .Name }}" | grep -E '^[a-z0-9]{64}$' | xargs --no-run-if-empty docker volume rm
}

# remove everything Docker
armaggedon() {
  removecontainers
  docker network prune -f
  docker rmi -f $(docker images --filter dangling=true -qa)
  docker volume rm $(docker volume ls --filter dangling=true -q)
  docker rmi -f $(docker images -qa)
  docker system prune -f -a
}

# for developing alpine docker images helper.
alprun()
{
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

# for developing bullseye docker images helper.
debrun()
{
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

ex()
{
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


clipcopy() {
  if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  else
    xclip -selection clipboard
  fi
}

hs()
{
  if [ $# -gt 0 ]; then
    cat ~/.zsh_history* ~/.bash_history* | col -bfx | sed -re 's/^: [^;]+//g' -e 's/^;//g' | sort | uniq | peco --query "$*" | tr -d '\n' | clipcopy
  else
    cat ~/.zsh_history* ~/.bash_history* | col -bfx | sed -re 's/^: [^;]+//g' -e 's/^;//g' | sort | uniq | peco | tr -d '\n' | clipcopy
  fi
}

reload() {
  exec "${SHELL}" "$@"
}

# -- Starship Configuration
if builtin command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# zoxide（z <ディレクトリ名の一部> で移動、zi で絞り込み）
if builtin command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

# Shift+↑/↓ で ScrollToPrompt が効くように、プロンプト直前に A マーカーを送る
if [ -n "$WEZTERM_EXECUTABLE" ] 2>/dev/null; then
  __wezterm_prompt_mark() { printf '\033]133;A\007'; }
  if [ -z "${PROMPT_COMMAND}" ]; then
    PROMPT_COMMAND="__wezterm_prompt_mark"
  else
    PROMPT_COMMAND="__wezterm_prompt_mark; ${PROMPT_COMMAND}"
  fi
fi

# -------------------------------------------
# ターミナルタイトル (zsh の termtitle と同じ表示)
#   待機中: user@host: ~/dir
#   実行中: コマンドライン [user@host: ~/dir]
# PROMPT_COMMAND 内の関数 (__zoxide_hook 等) や補完・bind -x で
# DEBUG trap が発火してもタイトルを書き換えないよう、
# プロンプト表示後の最初の 1 回だけ反映する。
# 他のフックより後に実行されるよう、必ずファイル末尾で登録すること。
# -------------------------------------------
case "$TERM" in
  screen*)
    __termtitle_set() { printf '\033k%s\033\\' "$1"; }
    ;;
  xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty*|tmux*|foot*|kitty*|wezterm*|st|st-*)
    __termtitle_set() { printf '\033]0;%s\007' "$1"; }
    ;;
esac

if declare -F __termtitle_set >/dev/null; then
  __termtitle_ready=
  __termtitle_last_hist=

  __termtitle_location() {
    printf '%s@%s: %s' "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"
  }

  __termtitle_precmd() {
    __termtitle_set "$(__termtitle_location)"
    __termtitle_last_hist=$(HISTTIMEFORMAT= builtin history 1)
    __termtitle_ready=1
  }

  __termtitle_preexec() {
    [ -n "${__termtitle_ready}" ] || return 0
    # 補完関数・bind -x (fzf 等) の実行中は無視
    [ -n "${COMP_LINE-}" ] && return 0
    [ -n "${READLINE_LINE+x}" ] && return 0
    __termtitle_ready=

    local cmd hist
    hist=$(HISTTIMEFORMAT= builtin history 1)
    if [ -n "${hist}" ] && [ "${hist}" != "${__termtitle_last_hist}" ]; then
      # 履歴番号を除いたコマンドライン全体
      cmd=$(printf '%s' "${hist}" | sed -E '1s/^ *[0-9]+\*? +//')
      cmd=${cmd//$'\n'/ }
    else
      # 履歴に残らないコマンド (先頭スペース・重複等) は実行中の単純コマンド
      cmd=${BASH_COMMAND}
    fi
    __termtitle_set "${cmd} [$(__termtitle_location)]"
  }

  PROMPT_COMMAND+=(__termtitle_precmd)
  trap '__termtitle_preexec' DEBUG
fi
