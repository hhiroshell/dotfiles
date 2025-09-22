#!/usr/bin/env bash

base_path="$(cd $(dirname $0); pwd)/home"

declare -a targets=(
    ".aqua/aqua.yaml"
    ".claude/commands"
    ".config/helix"
    ".config/nvim"
    ".config/starship.toml"
    ".config/tmux"
    ".gitconfig"
    ".gitignore_global"
    ".ideavimrc"
    ".ssh/config"
    ".zimrc"
    ".zshenv"
    ".zshrc"
)

for target in "${targets[@]}"; do
    src="${base_path}/${target}"
    dest="${HOME}/${target}"

    if [ -f "${dest}" ]; then
        echo "The file or symlink \"${dest}\" already exists."
        continue
    fi
    if [ -d "${dest}" ]; then
        echo "The directory \"${dest}\" already exists."
        continue
    fi

    dest_dir=$(dirname "${dest}")
    if [ ! -d "${dest_dir}" ]; then
        mkdir -p "${dest_dir}"
    fi

    ln -s "${src}" "${dest}"
    echo "Created symlink for ${target}"
done
