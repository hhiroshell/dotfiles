# =======
# sdkman
# =======
export SDKMAN_DIR="$HOME/.sdkman"

[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"


# ===
# go
# ===
export GOPATH="$HOME/.go"

# "$GOPATH/bin" is for binaries installed via "go install"
export PATH="$PATH:$GOPATH/bin"

# =====
# node
# =====

# settings for npm installed with aqua
# c.f. https://zenn.dev/shunsuke_suzuki/articles/aqua-nodejs-support
export NPM_CONFIG_PREFIX=${XDG_DATA_HOME:-$HOME/.local/share}/npm-global
export PATH=$NPM_CONFIG_PREFIX/bin:$PATH