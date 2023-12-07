# sdkman
export SDKMAN_DIR="$HOME/.sdkman"

[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# nodenv
export PATH="$PATH:$HOME/.nodenv/bin"

eval "$(nodenv init - zsh)"
