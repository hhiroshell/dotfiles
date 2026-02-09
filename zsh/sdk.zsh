# ==============
# Java (sdkman)
# ==============
export SDKMAN_DIR="$HOME/.sdkman"

if [[ -d "$HOME/.sdkman" ]]; then
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi


# ===
# Go
# ===
export GOPATH="$HOME/.go"

# "$GOPATH/bin" is for binaries installed via "go install"
export PATH="$PATH:$GOPATH/bin"


# ========
# Node.js
# ========

export NPM_CONFIG_PREFIX=${XDG_DATA_HOME:-$HOME/.local/share}/npm-global
export PATH=$NPM_CONFIG_PREFIX/bin:$PATH


# =====
# Rust
# =====
export PATH="$HOME/.cargo/bin:$PATH"

if rustup which rustc &> /dev/null; then
    toolchain_bin="$(dirname "$(rustup which rustc)")"
    # Only create symlink if it doesn't exist or is broken
    if [[ ! -L ~/.cargo/bin ]] || [[ ! -e ~/.cargo/bin ]]; then
        mkdir -p ~/.cargo
        ln -sf "$toolchain_bin" ~/.cargo/bin
    fi
fi
