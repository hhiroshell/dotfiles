# ==============
# Java (sdkman)
# ==============
export SDKMAN_DIR="$HOME/.sdkman"

if [[ -d "$HOME/.sdkman" ]]; then
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi


# =====
# Node (nvm)
# =====

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


# =====
# pnpm
# =====

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac


# =====
# Rust
# =====

if rustup which rustc &> /dev/null; then
    toolchain_bin="$(dirname "$(rustup which rustc)")"
    # Only create symlink if it doesn't exist or is broken
    if [[ ! -L ~/.cargo/bin ]] || [[ ! -e ~/.cargo/bin ]]; then
        mkdir -p ~/.cargo
        ln -sf "$toolchain_bin" ~/.cargo/bin
    fi
fi
