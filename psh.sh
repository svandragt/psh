#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

### COMPOSER ###
function composer_alias {
    # input version
    local selected
    selected=$(composer_select "$1")

    echo "Using Composer: $selected"
    # refresh shell
    hash -r
    # shellcheck disable=SC2139
    alias composer="php $selected"
    alias >>~/setAppEnv
}

function composer_all {
    find ~/.composer -maxdepth 1 -name '*.phar' | sort --field-separator=- --key=6Vr
}

function composer_select {
    local input
    local all
    input=$1
    selected=''
    all=$(composer_all)

    # filter selected Composer version
    for v in $(echo "$all" | tr " " "\n"); do
        if [[ $v == *"-$input"* ]]; then
            selected=$v
            break
        fi
    done

    if [[ -z $selected ]]; then
        echo "Sorry, unable to find Composer version '$input'." >&2
        return 0
    fi
    echo "$selected"
}
### /COMPOSER ###

### NODE ###
function node_alias {
    # input version
    local selected
    selected=$(node_select "$1")

    echo "Using Node    : $selected"
    # refresh shell
    hash -r
    # shellcheck disable=SC2139
    alias node="$selected"
    alias >>~/setAppEnv
}

function node_all_nvm {
    all=$1

    if [[ -n $NVM_DIR ]]; then
        all="$all $(find "$NVM_DIR/versions/node" -maxdepth 1 -type d | grep -E 'v[0-9\.]*$')"
    fi

    repos=()
    for v in $(echo "$all" | tr " " "\n"); do
        repos=("${repos[@]}" "$v")
    done
    all=

    echo "${repos[@]}"
}

function node_all_volta {
    all=$1

    if [[ -n $(command -v volta) ]]; then
        all="$all  $(find ~/.volta/tools/image/node -mindepth 1 -maxdepth 1 -type d)"
    fi

    echo "${all[@]}"
}

# Must be after node_all_*
function node_all {
    local all
    local selected
    all=""

    all=$(node_all_nvm "$all")
    all=$(node_all_volta "$all")

    echo "$all"
}

function node_select {
    # input version
    local input
    local selected
    input=$1
    selected=''

    # Convert all to installation paths
    all=$(node_all "$input")

    for v in $(echo "$all" | tr " " "\n"); do
        if [[ $v == *"/$input"* || $v == *"/v$input"*  ]]; then
            selected="$v/bin/node"
            break
        fi
    done

    if [[ -z $selected ]]; then
        echo "Sorry, unable to find Node version '$1'." >&2
        return 0
    fi

    echo "$selected"
}
### /NODE ###

### PHP ###
function php_alias {
    local selected
    selected=$(php_select "$1")

    echo "Using PHP     : $selected"
    # refresh shell
    hash -r
    alias >>~/setAppEnv
}

function php_all {
    local all
    all=''

    # add ~/.phps if it exists (default)
    if [[ -d $HOME/.phps ]]; then
        all="$all $HOME/.phps"
    fi

    # add default Homebrew directories (php@x.y) if brew is installed
    if [[ -n $(command -v brew) ]]; then
        all="$all  $(find "$(brew --cellar)" -maxdepth 1 -type d | grep -E 'php@[0-9\.]*$')"
    fi
    echo "$all"
}

function php_select {
    local input
  local selected
    local all
    input=$1
    all=$(php_all)

    #TODO are we restructuring the array here?
    repos=()
    for v in $(echo "$all" | tr " " "\n"); do
        repos=("${repos[@]}" "$v")
    done
    all=

    selected=$(php_select_exact "${repos[@]}")
    if [[ -z $selected ]]; then
        selected=$(php_select_fuzzy "${repos[@]}")
    fi

    if [[ -z $selected ]]; then
        echo "Sorry, unable to find PHP version '$input'." >&2
        return 0
    fi


    # export current paths
    export PHPRC=""
    [[ -f $selected/etc/php.ini ]] && export PHPRC=$selected/etc/php.ini
    [[ -d $selected/bin  ]]        && export PATH="$selected/bin:$PATH"
    [[ -d $selected/sbin ]]        && export PATH="$selected/sbin:$PATH"

    # use configured manpath if it exists, otherwise, use `$selected/share/man`
    local _manpath
    _manpath=$(php-config --man-dir)
    [[ -z $_manpath ]] && _manpath=$selected/share/man
    [[ -d $_manpath ]] && export MANPATH="$_manpath:${MANPATH-}"

    echo "$selected"

    hash -r
    export > ~/setAppEnv
}

function php_select_exact {
    local selected
    local -a repos
    local option
    selected=''
    repos=$1

    for r in "${repos[@]}"; do
        option="$r/$input"
        if [[ -d "$option" ]]; then
            selected="$option"
            break;
        fi
    done

    echo "$selected"
}

function php_select_fuzzy {
    local selected
    local -a repos
    local -a input_fuzzy
    selected=''
    repos=$1

    # TODO what does this do
    for r in "${repos[@]}"; do
        while IFS= read -r -d '' _dir; do
            input_fuzzy=("${input_fuzzy[@]}" "$("$_dir/bin/php-config" --version 2>/dev/null)")
        done< <(find -H "$r" -maxdepth 1 -mindepth 1 -type d -print0)
    done

    # Sort versioning
    version=$(IFS=$'\n'; echo "${input_fuzzy[*]}" | sort -r -t . -k 1,1n -k 2,2n -k 3,3n | grep -E "^$input" 2>/dev/null | tail -1)

    # Match exact version
    for r in "${repos[@]}"; do
        while IFS= read -r -d '' _dir; do
            v="$("$_dir/bin/php-config" --version 2>/dev/null)"
            if [[ -n "$version" && "$v" == "$version" ]]; then
                selected=$_dir
                break;
            fi
        done< <(find -H "$r" -maxdepth 1 -mindepth 1 -type d -print0)
    done

    echo "$selected"
}
### PHP ###

function _ensure_rcfile {
    file=pshrc
    if [ ! -f $file ]; then
        echo "Creating $file file..."
        $EDITOR $file
        exit 0
    fi
}

# MAIN
function _main {
    _ensure_rcfile
    # shellcheck disable=SC1091
    source pshrc

    # PHP before composer
    if [ -n "${php-}" ]; then
        php_alias "$php"
    fi
    if [ -n "${composer-}" ]; then
        composer_alias "$composer"
    fi

    if [ -n "${node-}" ]
    then
        node_alias "$node"
    fi

    bash --rcfile ~/setAppEnv
    rm -rf ~/setAppEnv
}
_main
