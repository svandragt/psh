#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

trap _cleanup INT EXIT RETURN
trap 'rm -f "$tempfile"' EXIT
tempfile=$(mktemp) || exit 1

Options=$*
larg_php=''
larg_composer=''
larg_node=''

### COMPOSER ###
function composer_alias() {
  selected=$(composer_select "$1")
  if [[ -z $selected ]]; then
    echo "Sorry, unable to find Composer version '$1'." >&2
    return 0
  fi
  echo "Using Composer: $selected"

  hash -r
  # shellcheck disable=SC2139
  alias composer="php $selected"
  alias >>"$tempfile"
}

function composer_all() {
  find ~/.composer -maxdepth 1 -name '*.phar' | sort --field-separator=- --key=6Vr
}

function composer_select() {
  while IFS= read -r line; do
    if [[ $line == *"-$1"* ]]; then
      echo "$line"
      return 0
    fi
  done <<<"$(composer_all | sort --reverse -V)"
}
### /COMPOSER ###

### NODE ###
function node_alias() {
  selected=$(node_select "$1")
  if [[ -z $selected ]]; then
    echo "Sorry, unable to find Node version '$1'." >&2
    return 0
  fi
  echo "Using Node    : $selected"

  hash -r
  # shellcheck disable=SC2139
  alias node="$selected"
  alias >>"$tempfile"
}

function node_all() {
  node_all_nvm
  node_all_volta
}

function node_all_nvm() {
  find "$NVM_DIR/versions/node" -maxdepth 1 -type d | grep -E 'v[0-9\.]*$'
}

function node_all_volta() {
  if [[ -n $(command -v volta) ]]; then
    find ~/.volta/tools/image/node -mindepth 1 -maxdepth 1 -type d
  fi
}

function node_select() {
  input="$1"
  while IFS= read -r line; do
    if [[ $line == *"/$input"* || $line == *"/v$input"* ]]; then
      echo "$line/bin/node"
      return 0
    fi
  done <<<"$(node_all | sort --reverse -V)"
}
### /NODE ###

### PHP ###
function php_alias() {
  selected=$(php_select "$1")
  if [[ -z $selected ]]; then
    echo "Sorry, unable to find PHP version '$1'." >&2
    return 0
  fi
  echo "Using PHP     : $selected"

  # export current paths
  export PHPRC=""
  [[ -f $selected/etc/php.ini ]] && export PHPRC=$selected/etc/php.ini
  [[ -d $selected/bin ]] && export PATH="$selected/bin:$PATH"
  [[ -d $selected/sbin ]] && export PATH="$selected/sbin:$PATH"
  # use configured manpath if it exists, otherwise, use `$selected/share/man`
  local _manpath
  _manpath=$(php-config --man-dir)
  [[ -z $_manpath ]] && _manpath=$selected/share/man
  [[ -d $_manpath ]] && export MANPATH="$_manpath:${MANPATH-}"

  # refresh shell
  hash -r
  alias >>"$tempfile"
}

function php_all() {
  php_all_phps
  php_all_brew
}

function php_all_brew() {
  # add default Homebrew directories (php@x.y/x.y.z) if brew is installed
  if [[ -n $(command -v brew) ]]; then
    find "$(brew --cellar)" -maxdepth 2 -mindepth 2 -type d | grep -E 'php@[0-9\.]'
  fi
}

function php_all_phps() {
  # add ~/.phps if it exists (default)
  if [[ -d $HOME/.phps ]]; then
    echo "$HOME/.phps"
  fi
}

function php_select() {
  while IFS= read -r line; do
    if [[ $line == *"/$1"* ]]; then
      echo "$line"
      break
    fi
  done <<<"$(php_all | sort --reverse -V)"
}
### /PHP ###

function _cleanup() {
  unset -f _usage _cleanup
  return 0
}

function _usage() {
  ###### U S A G E : Help and ERROR ######
  cat <<EOF
   psh $Options
   $*
   Usage: psh <[options]>
   Options:
      -h   --help           Show this message
      --composer=x.[y.z]    Set Composer version
      --php=x.[y.z]         Set PHP version
      --node=x.[y.z]        Set Node version
EOF
  return 1
}

function _ensure_rcfile() {
  file=pshrc
  if [ ! -f $file ]; then
    echo "Creating $file file..."
    $EDITOR $file
  fi
}

# MAIN
while getopts ':bfh-A:BF' OPTION; do
  case "$OPTION" in
  h) _usage ;;
  -)
    [ $OPTIND -ge 1 ] && optind=$(expr $OPTIND - 1) || optind=$OPTIND
    eval OPTION="\$$optind"
    OPTARG=$(echo "$OPTION" | cut -d'=' -f2)
    OPTION=$(echo "$OPTION" | cut -d'=' -f1)
    case $OPTION in
    --help) _usage ;;
    --php)
      larg_php="$OPTARG"
      ;;
    --composer)
      larg_composer="$OPTARG"
      ;;
    --node)
      larg_node="$OPTARG"
      ;;
    *) _usage " Long: >>>>>>>> invalid options (long) " ;;
    esac
    OPTIND=1
    shift
    ;;
  ?) _usage "Short: >>>>>>>> invalid options (short) " ;;
  esac
done

_ensure_rcfile
# shellcheck disable=SC1091
source pshrc

# PHP before composer
if [ -n "${larg_php}" ]; then
  php=$larg_php
fi
if [ -n "${php-}" ]; then
  php_alias "$php"
fi

if [ -n "${larg_composer}" ]; then
  composer=$larg_composer
fi
if [ -n "${composer-}" ]; then
  composer_alias "$composer"
fi

if [ -n "${larg_node}" ]; then
  node=$larg_node
fi
if [ -n "${node-}" ]; then
  node_alias "$node"
fi

bash --rcfile "$tempfile"
