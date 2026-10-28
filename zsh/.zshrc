# ~/.zshrc  (Original: ~/dotfiles/zsh/.zshrc)

# ===== Prompt =====
PROMPT='%F{magenta}%n%f@%F{blue}%m%f %F{blue}%~ %f%(!.#.$) '

# ===== History =====
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# ===== Allgemeine Optionen =====
setopt AUTO_CD               # Verzeichnisname allein wechselt hinein
setopt INTERACTIVE_COMMENTS  # Kommentare mit # auch in der Kommandozeile
unsetopt BEEP                # keine Terminal-Glocke

# ===== Farben für ls und Vervollständigung =====
if [[ -r ~/.dircolors ]]; then
  eval "$(dircolors ~/.dircolors)"
else
  eval "$(dircolors)"
fi
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# ===== Vervollständigung =====
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select                        # Auswahl mit Pfeiltasten
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # Groß/klein egal
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}      # Farben wie bei ls

# ===== Tastenbelegung =====
bindkey -e

autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Bild auf/ab: Präfix-Suche in der History
for km in emacs viins vicmd; do
  [[ -n "${terminfo[kpp]}" ]] && bindkey -M $km "${terminfo[kpp]}" up-line-or-beginning-search
  [[ -n "${terminfo[knp]}" ]] && bindkey -M $km "${terminfo[knp]}" down-line-or-beginning-search
done

# Pfeil hoch/runter: normale History
for km in emacs viins vicmd; do
  bindkey -M $km "^[[A" up-line-or-history
  bindkey -M $km "^[[B" down-line-or-history
  [[ -n "${terminfo[kcuu1]}" ]] && bindkey -M $km "${terminfo[kcuu1]}" up-line-or-history
  [[ -n "${terminfo[kcud1]}" ]] && bindkey -M $km "${terminfo[kcud1]}" down-line-or-history
done

# ===== Aliase =====
alias zedit="nvim ~/dotfiles/zsh/.zshrc"
alias themedit="nvim ~/dotfiles/theme/ansi.conf"
alias colors='for i in {0..15}; do print -Pn "%K{$i}  $(printf %2d $i)  %k"; ((i==7)) && echo; done; echo'

# ===== Plugins (müssen am Ende stehen) =====
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=16'

for plugin in \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  [[ -r $plugin ]] && source $plugin
done

ZSH_HIGHLIGHT_STYLES[alias]=fg=blue,bold
ZSH_HIGHLIGHT_STYLES[builtin]=fg=blue,bold
ZSH_HIGHLIGHT_STYLES[function]=fg=blue,bold
ZSH_HIGHLIGHT_STYLES[command]=fg=white,bold
