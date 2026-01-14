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


# =====
# aqua
# =====

export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"
export AQUA_PROGRESS_BAR=true

# Set a GitHub Access token to avoid GitHub API rete limiting.
# c.f. https://aquaproj.github.io/docs/products/aqua-registry/contributing/#-set-a-github-access-token-to-avoid-github-api-rate-limiting
if [[ "$(uname)" == "Darwin" ]]; then
    export AQUA_GITHUB_TOKEN=$(security find-generic-password -s "aqua-github-token" -w)
fi

if [[ "$(uname)" == "Linux" ]]; then
    aqua() {
        if [[ "$1" == "cp" ]]; then
            shift
            command aqua cp --exclude-tags exclude-on-linux "$@"
        elif [[ "$1" == "i" || "$1" == "install" ]]; then
            shift
            command aqua install --exclude-tags exclude-on-linux "$@"
        elif [[ "$1" == "up" || "$1" == "update" ]]; then
            shift
            command aqua update --exclude-tags exclude-on-linux "$@"
        else
            command aqua "$@"
        fi
    }
fi

aqua install -l


# ================
# starship prompt
# ================

eval "$(starship init zsh)"


# ===================================
# synchronize time at startup on WSL
# ===================================

if [[ "$(uname -r)" == *-WSL2 ]]; then
    wsl.exe -u root date --set @$(pwsh.exe -Command 'Get-Date -UFormat %s')
fi


# ==========================
# load external zsh scripts
# ==========================

# load zsh scripts from multiple dotfiles repositories
for repo in $(eval "ghq list --full-path --exact dotfiles"); do
    for file in $(ls $repo/zsh/*.zsh); do
        source $file
    done
done
