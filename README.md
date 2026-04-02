# zinit-annex-nix-bin

A [Zinit](https://github.com/zdharma-continuum/zinit) annex that installs [Nix](https://nixos.org/nix/) packages and symlinks their binaries into `$ZPFX/bin`, making them available on `$PATH` without any shell startup overhead.

## Installation

Load alongside your other annexes:

```zsh
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    kadaan/zinit-annex-nix-bin
```

## How it works

The annex adds a `nix''` ice modifier. When a plugin is loaded with this ice, the annex:

1. Runs `nix build <flakeref> --out-link $dir/result`, creating a GC root inside the plugin's directory
2. Symlinks every executable from `$dir/result/bin/` into `$ZPFX/bin`

On subsequent shell startups, `nix` is never invoked — the binaries are already present as symlinks in `$ZPFX/bin`, which Zinit adds to `$PATH`. Startup cost is zero.

On `zinit update`, the annex re-runs `nix build --refresh` to fetch the latest version. Because `$dir/result` is updated in place, the `$ZPFX/bin` symlinks automatically reflect the new store path without relinking.

On `zinit delete`, the annex removes only the `$ZPFX/bin` symlinks that point into the plugin's own directory, leaving any same-named symlinks from other plugins untouched.

## Usage

### `nix''` ice

```zsh
nix'<flakeref>'
```

Any valid Nix flake ref is accepted verbatim:

```zsh
# nixpkgs registry shorthand
zinit ice id-as'nix-ripgrep' nix'nixpkgs#ripgrep'
zinit load zdharma-continuum/null

# pinned nixpkgs branch
zinit ice id-as'nix-tokei' nix'github:nixos/nixpkgs/nixos-24.11#tokei'
zinit load zdharma-continuum/null

# local flake
zinit ice id-as'nix-mytool' nix'path:/home/user/my-flake#mytool'
zinit load zdharma-continuum/null
```

> **Note:** `id-as` is required when loading multiple packages via `zdharma-continuum/null`, as each load needs a unique plugin slot. The `id-as` value is also the identifier used with `zinit update` and `zinit delete`.

### Multiple packages

```zsh
zinit ice id-as'nix-ripgrep' nix'nixpkgs#ripgrep'
zinit load zdharma-continuum/null

zinit ice id-as'nix-fd' nix'nixpkgs#fd'
zinit load zdharma-continuum/null

zinit ice id-as'nix-tokei' nix'nixpkgs#tokei'
zinit load zdharma-continuum/null
```

### Updating

```zsh
# update a specific package
zinit update nix-ripgrep

# update all plugins including nix packages
zinit update --all
```

### Deleting

```zsh
zinit delete nix-ripgrep
```

## `zinit nix-list`

Lists all plugins managed by this annex, showing the flake ref, current Nix store path, and linked binaries:

```
• nix-ripgrep
    flake:  nixpkgs#ripgrep
    store:  /nix/store/abc123-ripgrep-14.1.1
    bins:   rg

• nix-fd
    flake:  nixpkgs#fd
    store:  /nix/store/def456-fd-9.0.0
    bins:   fd
```

## Requirements

- [Nix](https://nixos.org/download/) with flakes enabled
- [Zinit](https://github.com/zdharma-continuum/zinit)
