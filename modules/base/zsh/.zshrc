# ~/.zshrc

# Eigene Befehle (dot, theme-apply, …)
path=("$HOME/.local/bin" $path)

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
# alias ls='ls --color=auto'
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

# Sondertasten (übernahm früher oh-my-zsh)
bindkey '^[[1;5D' backward-word        # Strg+Links:  ein Wort zurück
bindkey '^[[1;5C' forward-word         # Strg+Rechts: ein Wort vor
bindkey '^[[1;5A' up-line-or-history   # Strg+Hoch:   wie Hoch
bindkey '^[[1;5B' down-line-or-history # Strg+Runter: wie Runter
bindkey '^[[3~'   delete-char          # Entf
bindkey '^[[3;5~' kill-word            # Strg+Entf:   Wort rechts löschen
bindkey '^H'      backward-kill-word   # Strg+Backspace: Wort links löschen
bindkey '^[[H'    beginning-of-line    # Pos1
bindkey '^[[F'    end-of-line          # Ende
[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]}"  ]] && bindkey "${terminfo[kend]}"  end-of-line
[[ -n "${terminfo[kdch1]}" ]] && bindkey "${terminfo[kdch1]}" delete-char

# ===== Aliase =====
alias zedit="nvim ~/.zshrc"
alias colors='for i in {0..15}; do print -Pn "%K{$i}  $(printf %2d $i)  %k"; ((i==7)) && echo; done; echo;for i in {0..15}; do print -Pn "%F{$i}██ $(printf %2d $i)%f  "; ((i==7)) && echo; done; echo'
# ls
alias ls="eza --group-directories-first --icons always"
alias la="eza --group-directories-first --icons always --all --long"
alias lat="eza --group-directories-first --icons always --all --tree --long --no-filesize --no-user --no-time --level "

# ===== Ergänzungen der Module (von dot verlinkt) =====
for f in ~/.config/zsh/conf.d/*.zsh(N); do source "$f"; done
unset f

# ===== Plugins (müssen am Ende stehen) =====
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

for plugin in \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  [[ -r $plugin ]] && source $plugin
done

ZSH_HIGHLIGHT_STYLES[alias]=fg=blue,bold
ZSH_HIGHLIGHT_STYLES[builtin]=fg=blue,bold
ZSH_HIGHLIGHT_STYLES[function]=fg=green,bold
ZSH_HIGHLIGHT_STYLES[command]=fg=white,bold
