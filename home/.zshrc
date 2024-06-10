# =======================
# zim zsh plugin manager
# =======================

ZIM_HOME=~/.zim

# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi

# Initialize modules.
source ${ZIM_HOME}/init.zsh


# ===============
# starship promt
# ===============

eval "$(starship init zsh)"


# =========================
# load external zsh scripts
# =========================

# "$HOME/go/bin" is for binaries installed via "go install"
# It requires ghq (installed in "$HOME/bo/bin") to load zsh scripts
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# load zsh scripts from multiple dotfiles repositories
for repo in $(eval "~/go/bin/ghq list --full-path --exact dotfiles"); do
    for file in $(ls $repo/zsh/*.zsh); do
        source $file
    done
done
