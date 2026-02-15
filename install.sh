#!/bin/bash

set -e

# Determine the real user when run with sudo
# If someone runs "curl ... | sudo bash", we want to install as root but add the alias for the user who invoked sudo
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME=$(eval echo "~$SUDO_USER")
    TARGET_SHELL=$(getent passwd "$SUDO_USER" | cut -d: -f7)
else
    TARGET_USER=$(whoami)
    TARGET_HOME="$HOME"
    TARGET_SHELL="$SHELL"
fi

if command -v trash-put &> /dev/null; then
    echo "trash-cli is already installed, skipping installation."
else
    install_with_pkg() {
        if command -v apt &> /dev/null; then
            $1 apt update && $1 apt install -y trash-cli
        elif command -v dnf &> /dev/null; then
            $1 dnf install -y trash-cli
        elif command -v pacman &> /dev/null; then
            $1 pacman -S --noconfirm trash-cli
        else
            return 1
        fi
    }

    if command -v brew &> /dev/null; then
        # brew doesn't need root
        brew install trash-cli
    elif [ "$(id -u)" -eq 0 ]; then
        # already root
        install_with_pkg "" || {
            echo "Could not detect a supported package manager. Install trash-cli manually."
            exit 1
        }
    elif command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then
        # has passwordless sudo
        install_with_pkg "sudo" || {
            echo "Could not detect a supported package manager. Install trash-cli manually."
            exit 1
        }
    else
        echo "Error: root privileges are required to install trash-cli."
        echo "Re-run with: curl -sSL trash.sh | sudo bash"
        exit 1
    fi
fi

USER_SHELL_NAME=$(basename "$TARGET_SHELL")
case "$USER_SHELL_NAME" in
    bash) RC_FILE="$TARGET_HOME/.bashrc" ;;
    zsh)  RC_FILE="$TARGET_HOME/.zshrc" ;;
    fish) RC_FILE="$TARGET_HOME/.config/fish/config.fish" ;;
    *)
        echo "Unsupported shell: $USER_SHELL_NAME. Add the alias manually."
        exit 1
        ;;
esac

# Create the rc file and fish config directory if they don't exist
if [ "$USER_SHELL_NAME" = "fish" ]; then
    mkdir -p "$(dirname "$RC_FILE")"
fi
if [ ! -f "$RC_FILE" ]; then
    touch "$RC_FILE"
fi

# Check if rm is already aliased to something else
if [ "$USER_SHELL_NAME" = "fish" ]; then
    ALIAS_LINE="alias rm 'trash-put'"
    EXISTING=$(grep "alias rm " "$RC_FILE" 2>/dev/null | grep -v "trash-put" || true)
else
    ALIAS_LINE="alias rm='trash-put'"
    EXISTING=$(grep "^alias rm=" "$RC_FILE" 2>/dev/null | grep -v "trash-put" || true)
fi

if [ -n "$EXISTING" ]; then
    echo "Warning: rm is already aliased in $RC_FILE:"
    echo "  $EXISTING"
    echo "Skipping alias to avoid conflict. Remove the existing alias and re-run if you want to use trash-put."
    exit 0
fi

# Add alias if not already present
if grep -q "trash-put" "$RC_FILE" 2>/dev/null; then
    echo "Alias already exists in $RC_FILE, skipping."
else
    echo "" >> "$RC_FILE"
    echo "# Use trash-put instead of rm for safe deletes" >> "$RC_FILE"
    echo "$ALIAS_LINE" >> "$RC_FILE"
    echo "Alias added to $RC_FILE"
fi

# Fix ownership if we wrote to another user's rc file as root
if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    chown "$TARGET_USER" "$RC_FILE"
fi

echo ""
echo "Done! trash-cli installed and rm aliased to trash-put for $TARGET_USER."
echo ""
echo "  trash-list       - see what's in the trash"
echo "  trash-restore    - recover a deleted file"
echo "  trash-empty      - permanently empty the trash"
echo ""
echo "Open a new terminal or run 'source $RC_FILE' to activate."
