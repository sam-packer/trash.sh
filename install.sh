#!/bin/bash

# Detect package manager and install trash-cli
if command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y trash-cli
elif command -v dnf &> /dev/null; then
    sudo dnf install -y trash-cli
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm trash-cli
elif command -v brew &> /dev/null; then
    brew install trash-cli
else
    echo "Could not detect a supported package manager. Install trash-cli manually."
    exit 1
fi

# Detect user's shell and pick the right rc file
USER_SHELL=$(basename "$SHELL")
case "$USER_SHELL" in
    bash) RC_FILE="$HOME/.bashrc" ;;
    zsh)  RC_FILE="$HOME/.zshrc" ;;
    fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
    *)
        echo "Unsupported shell: $USER_SHELL. Add the alias manually."
        exit 1
        ;;
esac

# Fish uses a different alias syntax
if [ "$USER_SHELL" = "fish" ]; then
    ALIAS_LINE="alias rm 'trash-put'"
else
    ALIAS_LINE="alias rm='trash-put'"
fi

# Add alias if not already present
if ! grep -q "trash-put" "$RC_FILE" 2>/dev/null; then
    echo "" >> "$RC_FILE"
    echo "# Use trash-put instead of rm for safe deletes" >> "$RC_FILE"
    echo "$ALIAS_LINE" >> "$RC_FILE"
    echo "Alias added to $RC_FILE"
else
    echo "Alias already exists in $RC_FILE"
fi

echo "Done. trash-cli installed and rm aliased to trash-put."
echo "Run 'trash-list' to see trash, 'trash-restore' to recover files."
echo ""
echo "Open a new terminal or run 'source $RC_FILE' to activate the alias."