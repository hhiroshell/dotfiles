#!/usr/bin/env bash
# OS and architecture detection

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        arm64)   echo "arm64" ;;
        *)       echo "unknown" ;;
    esac
}

# Export for use in other scripts
PKGMUX_OS="$(detect_os)"
PKGMUX_ARCH="$(detect_arch)"
export PKGMUX_OS PKGMUX_ARCH
