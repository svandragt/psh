#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function composer_all() {
  local all
  all=$(find ~/.composer -maxdepth 1 -name '*.phar' | sort --field-separator=- --key=6Vr)
  echo "$all"
}

function composer_select() {
  local all
  local target
  target=$1
  all=$(composer_all)

  # locate selected PHP version
  local selected
  for v in $(echo "$all" | tr " " "\n"); do
    if [[ $v == *"-$target"* ]]; then
      selected=$v
      break
    fi
  done

  # bail-out if we were unable to find a PHP matching given version
  if [[ -z $selected ]]; then
    echo "Sorry, unable to find version '$1'." >&2
    return 1
  fi
  echo "$selected"
}

function composer_switch() {
  # target version
  local target
  local _phar
  target=$1
  _phar=$(composer_select "$target")

### NODE ###
function node_alias {
  # input version
  local selected
  selected=$(node_select "$1")

  echo "Using Node: $selected"
  # refresh shell
  hash -r
  # shellcheck disable=SC2139
  alias node="$selected"
  alias >>~/setAppEnv
}

function node_all_nvm {
  all=$1

  if [[ -n $NVM_DIR ]]; then
		all="$all $(find "$NVM_DIR/all/node" -maxdepth 1 -type d | grep -E 'v[0-9\.]*$')"
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

  # add default Homebrew directories (php@x.y) if brew is installed
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
	# Convert all to installation paths
	all=$(node_all "$input")

	local input
	input=$1

  # locate selected node version
  for v in $(echo "$all" | tr " " "\n"); do
    if [[ $v == *"/$input"* || $v == *"/v$input"*  ]]; then
      selected="$v/bin/node"
      break
    fi
  done


	# bail-out if we were unable to find a PHP matching given version
	if [[ -z $selected ]]; then
		echo "Sorry, unable to find version '$1'." >&2
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

#function php_switch {
#	# target version
#	local target=$1
#
#	# Convert all to installation paths
#	local all=""
#	# add ~/.phps if it exists (default)
#	if [[ -d $HOME/.phps ]]; then
#		all="$all $HOME/.phps"
#	fi
#
#	# add default Homebrew directories if brew is installed
#	if [[ -n $(command -v brew) ]]; then
#		all="$all  $(find "$(brew --cellar)" -maxdepth 1 -type d | grep -E 'php@[0-9\.]*$')"
#	fi
#
#	repos=()
#	for _version in $(echo "$all" | tr " " "\n"); do
#		repos=("${repos[@]}" "$_version")
#	done
#	all=
#
#	# locate selected PHP version
#	local _root
#	for _repo in "${repos[@]}"; do
#		if [[ -d "$_repo/$target" && -z $_root ]]; then
#			_root="$_repo/$target"
#			break;
#		fi
#	done
#
#	# try a fuzzy match since we were unable to find a PHP matching given version
#	if [[ -z $_root ]]; then
#		target_fuzzy=()
#
#		for _repo in "${repos[@]}"; do
#			while IFS= read -r -d '' _dir; do
#				target_fuzzy=("${target_fuzzy[@]}" "$("$_dir/bin/php-config" --version 2>/dev/null)")
#			done< <(find -H "$_repo" -maxdepth 1 -mindepth 1 -type d 2 -print0)
#		done
#
#		target_fuzzy=$(IFS=$'\n'; echo "${target_fuzzy[*]}" | sort -r -t . -k 1,1n -k 2,2n -k 3,3n | grep -E "^$target" 2>/dev/null | tail -1)
#
#		for _repo in "${repos[@]}"; do
#			while IFS= read -r -d '' _dir; do
#				_version="$("$_dir/bin/php-config" --version 2>/dev/null)"
#				if [[ -n "$target_fuzzy" && "$_version" == "$target_fuzzy" ]]; then
#					local _root=$_dir
#					break;
#				fi
#			done< <(find -H "$_repo" -maxdepth 1 -mindepth 1 -type d 2 -print0)
#		done
#	fi
#
#	# bail-out if we were unable to find a PHP matching given version
#	if [[ -z $_root ]]; then
#		echo "Sorry, unable to find version '$target'." >&2
#		return 1
#	fi
#
#	echo "Using PHP $_root"
#
#	# export current paths
#	export PHPRC=""
#	[[ -f $_root/etc/php.ini ]] && export PHPRC=$_root/etc/php.ini
#	[[ -d $_root/bin  ]]        && export PATH="$_root/bin:$PATH"
#	[[ -d $_root/sbin ]]        && export PATH="$_root/sbin:$PATH"
#
#	# use configured manpath if it exists, otherwise, use `$_root/share/man`
#	local _manpath
#	_manpath=$(php-config --man-dir)
#	[[ -z $_manpath ]] && _manpath=$_root/share/man
#	[[ -d $_manpath ]] && export MANPATH="$_manpath:$MANPATH"
#
#	hash -r
#	export > ~/setAppEnv
#}

# MAIN
if [ ! -f pshrc ]; then
  echo "Creating pshrc file..."
  touch pshrc
  $EDITOR pshrc
  exit 0
fi
source pshrc
#
#if [ -n "$php" ]
#then
#	php_switch "$php"
#fi

if [ -n "$composer" ]; then
  composer_switch "$composer"
fi

#if [ -n "$node" ]
#then
#	node_switch "$node"
#	echo ''
#fi
bash --rcfile ~/setAppEnv
rm -rf ~/setAppEnv
