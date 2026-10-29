#!/bin/bash
# Helper functions for creating symlinks from dotfile directories to home/config.
#
# Directories are created as real directories (not symlinks).
# Files are symlinked individually (recursively).
# This prevents app-generated files from being tracked in the repository.
#
# link_dotconfig <name> <repo_root>
#   dot.config/<name>  →  ~/.config/<name>
#
# link_dothome <dirname> <repo_root>
#   dot.<dirname>/     →  ~/.<dirname>

# Internal: recursively link files, create real directories
_link_item() {
    local source="$1"
    local target="$2"

    if [ -f "$source" ]; then
        # Already correctly linked - skip
        if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
            echo "  Already linked: $target"
            return 0
        fi
        # Backup existing file or stale symlink
        if [ -e "$target" ] || [ -L "$target" ]; then
            mv "$target" "${target}.backup.$(date +%Y%m%d-%H%M%S)"
            echo "  Backed up: $target"
        fi
        mkdir -p "$(dirname "$target")"
        ln -s "$source" "$target"
        echo "  Linked: $target"

    elif [ -d "$source" ]; then
        # If target is a symlink from the old approach, back it up and replace with real dir
        if [ -L "$target" ]; then
            mv "$target" "${target}.backup.$(date +%Y%m%d-%H%M%S)"
            echo "  Backed up dir-symlink: $target"
        fi
        mkdir -p "$target"
        # Recurse into all items including hidden files
        while IFS= read -r -d '' item; do
            _link_item "$item" "$target/$(basename "$item")"
        done < <(find "$source" -maxdepth 1 -mindepth 1 -print0)
    fi
}

# Link dot.config/<name> to ~/.config/<name>
link_dotconfig() {
    local name="$1"
    local repo_root="$2"
    local source="$repo_root/dot.config/$name"

    if [ ! -e "$source" ]; then
        echo "Warning: $source does not exist, skipping"
        return 1
    fi

    echo "Linking: $name"
    _link_item "$source" "$HOME/.config/$name"
}

# Link dot.<dirname>/ to ~/.<dirname>
link_dothome() {
    local dirname="$1"
    local repo_root="$2"
    local source="$repo_root/dot.$dirname"

    if [ ! -e "$source" ]; then
        echo "Warning: $source does not exist, skipping"
        return 1
    fi

    echo "Linking: .$dirname"
    _link_item "$source" "$HOME/.$dirname"
}
