# trash.sh

One command to make `rm` safer on any Linux or macOS server.

```
curl -sSL trash.sh | bash
```

This installs [trash-cli](https://github.com/andreafrancia/trash-cli) and aliases `rm` to `trash-put`, so deleted files go to a trash folder instead of being permanently destroyed.

## What it does

1. Detects your package manager (apt, dnf, pacman, brew) and installs trash-cli
2. Detects your shell (bash, zsh, fish) and adds the alias to the right config file
3. That's it

## After running it

- `rm` now moves files to trash instead of deleting them
- `trash-list` shows what's in the trash
- `trash-restore` recovers files to their original location
- `trash-empty` permanently deletes everything in the trash

The alias only applies to interactive shell sessions. Scripts that use `rm` are unaffected.

## Inspect before running

You can view the script before running it:

```
curl -sSL trash.sh
```

Or just visit [trash.sh](https://trash.sh) in your browser.

## Why

Because `rm` is permanent, and humans make mistakes. [Here's the story behind it.](https://www.linkedin.com/posts/activity-7428641672093184001-wHsR/)
