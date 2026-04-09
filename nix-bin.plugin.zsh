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
        local path="$flakeref"
        if [[ "$path" == *://* ]]; then
            path="${path#*://}"   # strip scheme://
            path="${path#*/}"     # strip host (user@host/)
        else
            path="${path#*:}"     # strip scheme: (e.g. path:)
        fi
        path="${path#/}"          # strip leading /
        path="${path%%\?*}"       # strip query string
        path="${path/\#/-}"       # replace # with -
        pkg="${path//\//-}"       # replace remaining / with -
    fi
    local -a extra_ices
    zstyle -a ':zinit:annex:nix-bin' default-ices extra_ices
    if [[ ! -d "${ZINIT[PLUGINS_DIR]}/${pkg}" ]]; then
        extra_ices=("${(@)extra_ices:#wait*}")
    fi
    zinit ice "${extra_ices[@]}" id-as"${pkg}" nix"${flakeref}"
    zinit load zdharma-continuum/null
}
