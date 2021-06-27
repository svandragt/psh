#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Using # separator to fake arrays

function fake_in {
    # function accepts array
    local lines
    lines=$(echo "$1" | cut -b2- | tr "#" '\n')
    while IFS= read -r line; do
        echo ">$line"
    done <<< "$lines"
}

function fake_inout {
    # function accepts array and returns array
    local lines
    local cmd
    cmd=$(echo "$1" | cut -b2- | tr "#" '\n')
    lines=$1
    while IFS= read -r line; do
        lines="$lines#+$line"
    done <<< "$cmd"
    echo "$lines"
}

function main {

    items="#1 one#2 two#3 three"
    # array merge
    items=$(fake_inout "$items")
    fake_in "$items"
}
main
