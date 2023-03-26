# kubectl
alias k='kubectl'
export KUBE_EDITOR=nvim

# krew
export PATH="$PATH:${KREW_ROOT:-$HOME/.krew}/bin"


# ========================
# multi cluster managemsnt
# ========================

_kubectl-to-multi-clusters() {
    local contexts
    contexts=$(kubectl config get-contexts -o name | fzf --multi --prompt="select target clusters:")
    if [ $? -ne 0 ]; then
        return 1
    fi

    echo -n "🚀 Command to execute: "
    echo "\e[36;1mkubectl $* --context \${context}\e[m"
    echo ""

    echo "☸️  Target kubectl contexts:"
    for ctx in ${(f)contexts}; do
        echo " - ${ctx}"
    done
    echo ""

    echo -n "Are you sure to proceed? [y/N]: "
    read ANS
    case $ANS in
        [Yy]*)
            ;;
        *)
            return 1
            ;;
    esac

    for ctx in ${(f)contexts}; do
        echo ""

        echo "${ctx}"
        for i in $(seq ${#ctx}); do printf "%s" -; done
        echo ""

        eval "kubectl $* --context ${ctx}"
    done
}

alias kubemc='_kubectl-to-multi-clusters'
