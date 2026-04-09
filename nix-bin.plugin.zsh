# According to the Zsh Plugin Standard:
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

[[ -d $ZPFX/bin ]] || command mkdir -p "$ZPFX/bin"

autoload za-nix-bin-atclone-handler \
    za-nix-bin-atpull-handler \
    za-nix-bin-atdelete-handler \
    za-nix-bin-subcommand-handler

za-nix-bin-null-handler() { :; }

@zinit-register-annex "z-a-nix-bin" \
    hook:atclone-50 \
    za-nix-bin-atclone-handler \
    za-nix-bin-null-handler \
    "nix|nix''"

@zinit-register-annex "z-a-nix-bin" \
    hook:\%atpull-50 \
    za-nix-bin-atpull-handler \
    za-nix-bin-null-handler

@zinit-register-annex "z-a-nix-bin" \
    hook:atdelete-50 \
    za-nix-bin-atdelete-handler \
    za-nix-bin-null-handler

@zinit-register-annex "z-a-nix-bin" \
    subcommand:nix-list \
    za-nix-bin-subcommand-handler \
    za-nix-bin-null-handler

znix() {
    local flakeref="$1"
    local pkg
    if [[ -n "$2" ]]; then
        pkg="$2"
    else
        local _p="$flakeref"
        if [[ "$_p" == *://* ]]; then
            _p="${_p#*://}"   # strip scheme://
            _p="${_p#*/}"     # strip host (user@host/)
        else
            _p="${_p#*:}"     # strip scheme: (e.g. path:)
        fi
        _p="${_p#/}"          # strip leading /
        _p="${_p%%\?*}"       # strip query string
        _p="${_p/\#/-}"       # replace # with -
        pkg="${_p//\//-}"     # replace remaining / with -
    fi
    local -a extra_ices
    zstyle -a ':zinit:annex:nix-bin' default-ices extra_ices
    local plugin_dir="${ZINIT[PLUGINS_DIR]}/${pkg}"
    if [[ ! -d "$plugin_dir" ]]; then
        # Pre-clone and build in the main shell, which has full PATH, to avoid
        # zinit's subprocess PATH limitations (async worker only sources /etc/zshenv).
        [[ :$PATH: == *:/usr/bin:* ]] || path=(/usr/bin $path)
        [[ :$PATH: == *:/bin:* ]]     || path=(/bin $path)
        if command git clone --quiet https://github.com/zdharma-continuum/null.git "$plugin_dir" 2>/dev/null; then
            if (( ${+commands[nix]} )); then
                +zi-log "{m} {b}nix-bin{rst}: Building {ice}$flakeref{rst}"
                if command nix build "$flakeref" --out-link "$plugin_dir/result"; then
                    print -r -- "$flakeref" >! "$plugin_dir/.nix-flakeref"
                    local bin
                    for bin in "$plugin_dir"/result/bin/*(N*); do
                        command ln -sf "$bin" "$ZPFX/bin/${bin:t}"
                        +zi-log "{m} {b}nix-bin{rst}: Linked {file}${bin:t}{rst}"
                    done
                else
                    +zi-log "{e} {b}nix-bin{rst}: \`nix build\` failed for {ice}$flakeref{rst}"
                fi
            else
                +zi-log "{e} {b}nix-bin{rst}: \`nix\` not found in PATH — cannot install {ice}$flakeref{rst}"
            fi
        fi
    fi
    zinit ice "${extra_ices[@]}" id-as"${pkg}" nix"${flakeref}"
    zinit load zdharma-continuum/null
}
