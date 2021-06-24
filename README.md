# psh - a PHP Shell.

Tired of switching tooling versions between PHP projects? Perhaps you've used a Python virtual environment before? This is an approximation of the same idea for PHP projects. It doesn't deal with installing packages though.

Features:

- Support for PHP , Composer, Node.
- Fuzzy matching (sometimes).
- Project dependencies are defined in a bash environment compatible file format.

Supports

- PHP installed via Homebrew or PHPS (latter untested)
- Composer
- Node installed via NVM or Volta.


## Install

Note that you need to have the tooling pre-installed.

1. Symlink `psh.sh` to `psh` in your path. eg `ln -s psh.sh ~/bin/psh`
2. Add a `pshrc` file to your project folder ala:

```
php=7.3
composer=1.10
node=15.
```

3. type `psh` to start a subshell with tooling set to those versions. Type `exit` to exit the subshell.

## Tip

If you're using zsh you can use the following function to automatically enter the subshell:
```
function chpwd() {
    if [ -r $PWD/pshrc ]; then
        psh
        return
    fi
}
```

