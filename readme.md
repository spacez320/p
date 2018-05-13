p
=

---

**DEPRECATED** - *I don't maintain or use this anymore. I'd recommend checking
out [pass](https://www.passwordstore.org/), which is much better.*

---

`p` is a program to manage passwords through bash.

This program is aimed primarily at desktop Linux users who use X, but prefer
the terminal. It is meant to be straightforward to use, to add convenience, and
to promote secure password practices. 

* It uses GPG to encrypt password sources.
* It uses pwgen to generate passwords.
* It uses Xclip to push passwords into the X clipboard.

## PHILOSOPHY ##

`p` uses an encrypted password file and a GPG keypair to manage *password
sources*. It assumes you will have the following:

1. a *home source*, where your password sources will originate from
2. any number of additional sources that live elsewhere (like thumb-drives)

You may add new passwords to any source, but afterwards you will need to come
back to your home source and synchronize through a pull-to-home/push-to-others
process.  Another way to think of it is 'dropping off' passwords to your home
source to be 'picked up' later by the rest of your password sources.

See `p push`, `p pull`, and `p sync` if you're still confused.

## USING SOURCES ##

`p` will search for recorded password sources through the `$HOME/.psources`
file, a newline delimited file of directories. 

The home source is located at `$HOME/.p`.

When searching for a password source to use, it will always take the first
`.psources` entry it finds that is accessible, and fall back to the home
source.

See `p source`, `p init` to get a handle on sources.

## REMOTE USAGE ##

Any machine that you want to use `p` for getting and adding passwords will at
least need the following:

* `p` itself and all dependencies
* the appropriate `.psources` file in `$HOME`

Some commands require you be located on the machine with your home source.

## USAGE ##

* `p setup`

  Run this first. It helps you set up GPG and initialize `p`.

* `p get (options) (query)`

  Query a passwords source, dump it to Xclip by default.

  *-o* output to stdout

  *query* is the search string. If none is given, it will dump the entire
  passwords file. 

* `p add (options) [key] (value)`

  Add passwords to a password source.

  *-l* password length, `p` will reject < 12 characters

  *-o* output to stdout

  *key* is the key for the password that you can use to retrieve the password
  later.

  *value* is an optional explicit password

* `p rm (options) [key]`

  Remove a password from a password source.

  *-y*  do not ask questions

  *key* is the key for the password that you want to remove 

* `p edit (options) [key] (value)`

  Edit a currently stored password.

  *-l* password length, `p` will reject < 12 characters
  
  *-o* output to stdout

  *-y*  do not ask questions

  *key* is the key for the password that you want to edit 

  *value* is an optional explicit password replacement

* `p init (options) [source]`

  Creates a new passwords source.

  *-c*  sync mode (used internally for `p sync`)

  *source* is the directory for the new password source. It must be empty and
  writeable.

* `p pull [source]`

  Updates the home source from another given source.

  *source* is the source directory to overwrite the home source with.

* `p push`

  Updates all findable password sources with the home source.

* `p sync [source]`

  Does a pull, then a push (see `p pull` and `p push`).

* `p source`

  Lists known sources, specifies the active one.

## WARNINGS ##

* **DEPRECATED** - I don't maintain or use this anymore. I'd recommend
checking out [pass](https://www.passwordstore.org/), which is much better.

* `p` can really be considered a wrapper for `gpg`. Knowing how to use `gpg`
is advisable.

* Note that `p` does not have any sort of knowledge on how to resolve divergent
password sources. It doesn't really have any knowledge at all. Pushing and
pulling are strictly overwrite options (for now).

* There is no way to remove sources or passwords other than editing things by
hand (for now).

* This script is very much in its infancy. Be careful, keep a backup of your
passwords somewhere else.

