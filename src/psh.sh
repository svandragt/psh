#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

### COMPOSER ###
function composer_alias {
    selected=$(composer_select "$1")
    if [[ -z $selected ]]; then
        echo "Sorry, unable to find Composer version '$input'." >&2
        return 0
    fi
    echo "Using Composer: $selected"

    hash -r
    # shellcheck disable=SC2139
    alias composer="php $selected"
    alias >>~/setAppEnv
}

function composer_all {
    find ~/.composer -maxdepth 1 -name '*.phar' | sort --field-separator=- --key=6Vr
}

function composer_select {
    while IFS= read -r line; do
        if [[ $line == *"-$1"* ]]; then
            echo "$line"
            return 0
        fi
    done <<< "$(composer_all)"
}
### /COMPOSER ###


### NODE ###
function node_alias {
    selected=$(node_select "$1")
    if [[ -z $selected ]]; then
        echo "Sorry, unable to find Node version '$1'." >&2
        return 0
    fi
    echo "Using Node    : $selected"

    hash -r
    # shellcheck disable=SC2139
    alias node="$selected"
    alias >>~/setAppEnv
}

function node_all {
    node_all_nvm
    node_all_volta
}

function node_all_nvm {
    find "$NVM_DIR/versions/node" -maxdepth 1 -type d | grep -E 'v[0-9\.]*$'
}

function node_all_volta {
    if [[ -n $(command -v volta) ]]; then
        find ~/.volta/tools/image/node -mindepth 1 -maxdepth 1 -type d
    fi
}

function node_select {
    input="$1"
    while IFS= read -r line; do
        if [[ $line == *"/$input"* || $line == *"/v$input"*  ]]; then
            echo "$line/bin/node"
            return 0
        fi
    done <<< "$(node_all)"
}
### /NODE ###


### PHP ###
function php_alias {
    selected=$(php_select "$1")
    if [[ -z $selected ]]; then
        echo "Sorry, unable to find PHP version '$1'." >&2
        return 0
    fi
    echo "Using PHP     : $selected"

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

    # refresh shell
    hash -r
    alias >>~/setAppEnv
}

function php_all {
    php_all_phps
    php_all_brew
}

function php_all_brew {
    # add default Homebrew directories (php@x.y/x.y.z) if brew is installed
    if [[ -n $(command -v brew) ]]; then
        find "$(brew --cellar)" -maxdepth 2 -mindepth 2 -type d | grep -E 'php@[0-9\.]'
    fi
}

function php_all_phps {
    # add ~/.phps if it exists (default)
    if [[ -d $HOME/.phps ]]; then
        echo "$HOME/.phps"
    fi
}

function php_select {
    while IFS= read -r line; do
        if [[ $line == *"/$1"*  ]]; then
            echo "$line"
            break
        fi
    done <<< "$(php_all)"
}
### /PHP ###


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
