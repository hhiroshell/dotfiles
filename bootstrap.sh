#!/usr/bin/env bash

base_path="/home/hhiroshell/src/github.com/hhiroshell/dotfiles/home"
declare -a targets=(
    ".config"
    ".gitconfig"
    ".gitignore_global"
    ".ideavimrc"
    ".ssh/config"
    ".zimrc"
    ".zshrc"
)

for target in "${targets[@]}"; do
    src="${base_path}/${target}"
    dest="$HOME/${target}"

    dest_dir=$(dirname "${dest}")
    if [ ! -d "${dest_dir}" ]; then
        mkdir -p "${dest_dir}"
    fi

    ln -s "${src}" "${dest}"
    echo "Created symlink for ${target}"
done
