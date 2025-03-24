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
