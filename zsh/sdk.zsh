# ==============
# Java (sdkman)
# ==============
export SDKMAN_DIR="$HOME/.sdkman"

if [[ -d "$HOME/.sdkman" ]]; then
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi


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
