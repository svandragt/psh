# psh
PHP Shell.

Tired of switching tooling versions between PHP projects? Perhaps you've used a Python virtual environment before? This is an approximation of the same idea for PHP projects. It doesn't deal with installing packages though.

Features:
 - Support for PHP, Composer, Node.
 - Fuzzy matching (sometimes).
 - Project dependencies are defined in a bash compatible file format.

Supports
 - PHP installed via Homebrew
 - Composer
 - Node installed via NVM


## Install

1. Symlink `psh.sh` to `psh` in your path.
2. Add a `pshrc` file to your project folder ala:

```
php=7.3
composer=1.10
node=15.
```
