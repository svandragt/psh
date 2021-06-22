#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
    
function composer_detect {
	local VERSIONS=$(ls $HOME/.composer/*.phar)
	echo $VERSIONS
}

function composer_locate {
	local PHARS=$(composer_detect)
	local TARGET=$1

	# locate selected PHP version
	local CHOICE=
	for _PHAR in $(echo "$PHARS" | tr " " "\n"); do
		if [[ $_PHAR == *"-$TARGET"* ]]; then
			_CHOICE=$_PHAR
			break;
		fi
	done

	# bail-out if we were unable to find a PHP matching given version
	if [[ -z $_CHOICE ]]; then
		echo "Sorry, unable to find version '$1'." >&2
		return 1
	fi

	echo $_CHOICE
}

function composer_switch {
	# target version
	local TARGET=$1
	local _PHAR=$(composer_locate $TARGET)

	echo "Using composer $_PHAR"


	hash -r
	alias composer="php $_PHAR"
	alias >> ~/setAppEnv
}

function node_locate {
	local VERSIONS=""

	# add default nvm directories if brew is installed
	if [[ ! -z $NVM_DIR ]]; then
		VERSIONS="$VERSIONS $(echo $(find $NVM_DIR/versions/node -maxdepth 1 -type d | grep -E 'v[0-9\.]*$'))"
	fi

	REPOS=()
	for _VERSION in $(echo $VERSIONS | tr " " "\n"); do
		REPOS=("${REPOS[@]}" $_VERSION)
	done
	VERSIONS=

	local TARGET=$1

	# locate selected PHP version
	for _REPO in "${REPOS[@]}"; do
		if [[ $_REPO == *"/v$TARGET"*  && -z $_ROOT ]]; then
			local _ROOT=$_REPO/bin/node
			break;
		fi
	done

	# bail-out if we were unable to find a PHP matching given version
	if [[ -z $_ROOT ]]; then
		echo "Sorry, unable to find version '$1'." >&2
		return 1
	fi

	echo $_ROOT
}

function node_switch {
	# target version
	local TARGET=$1

	# Convert versions to installation paths
	local _ROOT=$(node_locate $TARGET)

	echo "Using node $_ROOT"

	hash -r
	alias node="$_ROOT"
	alias >> ~/setAppEnv
}

function php_switch {
	# target version
	local TARGET=$1

	# Convert versions to installation paths
	local VERSIONS=""
	# add ~/.phps if it exists (default)
	if [[ -d $HOME/.phps ]]; then
		VERSIONS="$VERSIONS $HOME/.phps"
	fi

	# add default Homebrew directories if brew is installed
	if [[ -n $(command -v brew) ]]; then
		VERSIONS="$VERSIONS $(echo $(find $(brew --cellar) -maxdepth 1 -type d | grep -E 'php@[0-9\.]*$'))"
	fi

	REPOS=()
	for _VERSION in $(echo $VERSIONS | tr " " "\n"); do
		REPOS=("${REPOS[@]}" $_VERSION)
	done
	VERSIONS=

	# locate selected PHP version
	for _REPO in "${REPOS[@]}"; do
		if [[ -d "$_REPO/$TARGET" && -z $_ROOT ]]; then
			local _ROOT=$_REPO/$TARGET
			break;
		fi
	done

	# try a fuzzy match since we were unable to find a PHP matching given version
	if [[ -z $_ROOT ]]; then
		TARGET_FUZZY=()

		for _REPO in "${REPOS[@]}"; do
			for _dir in $(find -H $_REPO -maxdepth 1 -mindepth 1 -type d 2>/dev/null); do
				TARGET_FUZZY=("${TARGET_FUZZY[@]}" "$($_dir/bin/php-config --version 2>/dev/null)")
			done
		done

		TARGET_FUZZY=$(IFS=$'\n'; echo "${TARGET_FUZZY[*]}" | sort -r -t . -k 1,1n -k 2,2n -k 3,3n | grep -E "^$TARGET" 2>/dev/null | tail -1)

		for _REPO in "${REPOS[@]}"; do
			for _dir in $(find -H $_REPO -maxdepth 1 -mindepth 1 -type d 2>/dev/null); do
				_VERSION="$($_dir/bin/php-config --version 2>/dev/null)"
				if [[ -n "$TARGET_FUZZY" && "$_VERSION" == "$TARGET_FUZZY" ]]; then
					local _ROOT=$_dir
					break;
				fi
			done
		done
	fi

	# bail-out if we were unable to find a PHP matching given version
	if [[ -z $_ROOT ]]; then
		echo "Sorry, unable to find version '$TARGET'." >&2
		return 1
	fi

	echo "Using PHP $_ROOT"

	# export current paths
	export PHPRC=""
	[[ -f $_ROOT/etc/php.ini ]] && export PHPRC=$_ROOT/etc/php.ini
	[[ -d $_ROOT/bin  ]]        && export PATH="$_ROOT/bin:$PATH"
	[[ -d $_ROOT/sbin ]]        && export PATH="$_ROOT/sbin:$PATH"

	# use configured manpath if it exists, otherwise, use `$_ROOT/share/man`
	local _MANPATH=$(php-config --man-dir)
	[[ -z $_MANPATH ]] && _MANPATH=$_ROOT/share/man
	[[ -d $_MANPATH ]] && export MANPATH="$_MANPATH:$MANPATH"

	hash -r
	export > ~/setAppEnv
}


# MAIN
if [ ! -f pshrc ]
then
	$EDITOR pshrc
	exit 0;
fi
source pshrc

if [ ! -z "$php" ]
then 
	php_switch $php
fi

if [ ! -z "$composer" ]
then 
	composer_switch $composer
fi

if [ ! -z "$node" ]
then 
	node_switch $node
	echo ''
fi
bash --rcfile ~/setAppEnv
