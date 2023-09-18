_slow-yes() {
    while :
    do
        echo "y"
        sleep 5
    done
}

_ghq-idea() {
    if [ -n "$*" ]; then
        if [[ "$(uname -r)" == *microsoft* ]]; then
            _slow-yes | cmd.exe /c idea.bat $(wslpath -aw "$@") > /dev/null 2>&1 &
        elif [[ "$(uname)" == "Darwin" ]]; then
            "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" "$@" > /dev/null 2>&1 &
        fi
    else
		local repo
		repo=$(ghq list | fzf)
		if [ $? -ne 0 ]
		then
			return 1
		fi

        if [[ "$(uname -r)" == *microsoft* ]]; then
            _slow-yes | cmd.exe /c idea.bat $(wslpath -aw "$(ghq root)/${repo}") > /dev/null 2>&1 &
        elif [[ "$(uname)" == "Darwin" ]]; then
            "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" "$(ghq root)/${repo}" > /dev/null 2>&1 &
        fi
    fi
}

alias idea='_ghq-idea'
