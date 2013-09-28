#!/bin/bash

# `p` should have been distributed with a `license` file.
# MIT License (MIT), Copyright (c) 2013 Matthew Coleman

VERSION='p: manage passwords through bash, v0.2'

USAGE='
###############################################################################
#
#   `p` is a program to manage passwords through bash.
#
#   * It uses GPG to encrypt password sources.
#   * It uses pwgen to generate passwords.
#   * It uses Xclip to push passwords into the X clipboard.
#
#   USAGE
#
#   p setup
#     Run this first. It helps you set up GPG and initialize `p`.
#
#   p get <options> <query>
#     Query a passwords source, dump it to Xclip by default.
#
#     -o  output to stdout
#   
#     query;  search string; if none given, it will dump the entire
#             passwords file
#
#   p add <options> [key] <value>
#     Add passwords to a password source. 
#
#     -l  password length, `p` will reject < 12 characters
#     -o  output to stdout
#
#     key;  key for the password, used for later retrieval
#     value;  optional explicit password
#
#   p rm <options> [key]
#     Remove a password from a password source.
#
#     -y  do not ask questions
#
#     key;  key for the password to remove
#
#   p edit <options> [key]
#     Edit a currently stored password.
#
#     -l  password length, `p` will reject < 12 characters
#     -o  output to stdout
#     -y  do not ask questions
#     
#     key;  key for the password to edit
#     value;  optional explicit password
#
#   p init <options> [source]
#     Create a new passwords source. 
#
#     -c  sync mode (used internally)
#
#     source; directory for the new password source
#
#   p pull [source]
#     Updates the home source from another given source.
#
#     source; source directory to overwrite the home source
#
#   p push 
#     Updates all findable password sources with the home source.
#
#   p sync [source]
#     Does a pull, and then a push.
#
#     source; source directory to overwrite the home source with
#
#   p source
#     List known sources, specify the active one.
#
###############################################################################
'

CURRENT_USER=$(whoami)

MINIMUM_PASSWORD_LENGTH=12

P_HOME="$HOME/.p"
P_SOURCE="$P_HOME"

_p_find_source() {

  if [ -r "$HOME/.psources" ]; then
    # check recorded sources, use first found 
    while read source; do
      # is the .gnupg directory available and is the p.gpg file available?
      if [ -d "$source/.gnupg" -a -a "$source/p.gpg" ]; then
        P_SOURCE="$source"
        break
      fi
    done < "$HOME/.psources"
  fi

  # make sure we found something
  if [ ! -d "$P_SOURCE/.gnupg" -a ! -a "$P_SOURCE/p.gpg" ]; then
    echo -e "\nI didn't find a valid source or the home source."
    echo -e "Is this your first time running \`p\`? Try \`p setup\`.\n"
    exit 1
  fi
}

_p_check_home() {

  # check if we have a home
  if [ ! -d "$P_HOME" ]; then
    echo "This operation requires the home source, which doesn't seem there; exiting."
    exit 1
  fi
}

p_main() {

  while getopts "hV" opt; do 
    case $opt in
      h)  # help
          echo "$USAGE" 
          exit 0
          ;;
      V)  # version
          echo "$VERSION"
          exit 0
          ;;
      *)  echo "$USAGE"
          exit 1
          ;;
    esac
  done

  case $1 in
    "setup")  action=p_setup
              ;;
    "get")  action=p_get

            # determine source
            _p_find_source
            ;;
    "add")  action=p_add

            # determine source
            _p_find_source
            ;;
    "rm") action=p_remove

          # determine source
          _p_find_source
          ;;
    "edit") action=p_edit

          # determine source
          _p_find_source
          ;;
    "init") action=p_init

            # requires home
            _p_check_home
            ;;
    "pull") action=p_pull

            # requires home
            _p_check_home
            ;;
    "push") action=p_push

            # requires home
            _p_check_home
            ;;
    "sync") action=p_sync

            # requires home
            _p_check_home
            ;;
    "source") action=p_source
              ;;
    \?)   echo -e "\np doesn't know what '$1' is."
          echo "$USAGE"
          exit 1
          ;;
    *)    echo "$USAGE"
          exit 1
          ;;
  esac
      
  # throw out the action argument
  local pass_args=''
  local first=true
  for arg in "$@"; do
    if $first; then 
      first=false; continue
    fi
    pass_args+="$arg "
  done

  $action $pass_args 
}

p_setup() {

#   p setup
#     Run this first. It helps you set up GPG and initialize `p`.

  echo -e "\nWelcome to \`p\`. Let's do a couple of things before we begin."
  
  # do GPG key check

  echo -e "
-------------------------------------------------
Checking for a valid GPG key...
"

  gpg --no-verbose --quiet --list-keys $CURRENT_USER &> /dev/null 

  if [ ! $? -eq 0 ]; then

    echo "It looks like you don't have a valid GPG key ready to go."
    echo -n "Would you like to go through the process now (yes/no)? "

    read keep_going

    case $keep_going in
      "yes" | "y")
          echo ""
          gpg --gen-key
          ;;
      "no" | "n")
          echo -e "\nOk, exiting.\n"
          exit 0
          ;;
    esac

    if [ ! $? -eq 0 ]; then
      echo "Creating your GPG key seemed to fail for some reason; exiting."
      exit 1
    fi
  else
    echo -e "It looks like you have a GPG key we can use."
  fi

  # set up home source

  echo -e "
-------------------------------------------------
Setting up config and the home source...
"

  # check if we already have a home
  if [ -d "$P_HOME" -a -f "$P_HOME/p.gpg" -a -d "$P_HOME/.gnupg" ]; then
    echo "It appears you already have a home source ($HOME/.p)."
    echo -e "I will let you remove this yourself before continuing.\n"
    exit 0
  fi

  mkdir -p "$P_HOME/bak"
  touch "$HOME/.psources"
  cp -r "$HOME/.gnupg" "$P_HOME"
  echo "" | gpg --homedir="$P_HOME/.gnupg" --yes -e -r $CURRENT_USER > "$P_HOME/p.gpg"

  echo "Ok, successfully created '$HOME/.p' and '$HOME/.psources'." 
  echo -e "You should be good to go! Try adding your first password with \`p add [something]\`.\n"

  return 0
}

p_get() {

#   p get <options> <query>
#     Query a passwords source, dump it to Xclip by default.
#
#     -o  output to stdout
#   
#     query;  search string; if none given, it will dump the entire
#             passwords file

  local stdout=false

  while getopts "o" opt; do 
    case $opt in
      o)  stdout=true
          ;;
      *)  echo "$USAGE"
          exit 1
          ;;
    esac
  done
  shift $(($OPTIND - 1))

  # determine search
  local search=$1

  # get password
  local output=
  if [ -z $search ]; then
    # get everything
    output=$(gpg --no-verbose --quiet --homedir "$P_SOURCE/.gnupg" -d "$P_SOURCE/p.gpg")
  else
    output=$(awk -F' ' '{ print $2 }' <<< \
      $(gpg --no-verbose --quiet --homedir "$P_SOURCE/.gnupg" -d "$P_SOURCE/p.gpg" | grep "$search"))
  fi

  if [ -z "$output" ]; then
    echo "No results found for '$search'"
    return 1
  fi
  if $stdout; then
    echo -e "$output"
  else
    echo $output | xclip -sel clip
  fi

  return 0
}

p_add() {

#   p add <options> [key] <value>
#     Add passwords to a password source. 
#
#     -l  password length, `p` will reject < 12 characters
#     -o  output to stdout
#
#     key;  key for the password used for later retrieval
#     value;  optional explicit password

  local password_length=32
  local stdout=false

  while getopts "l:o" opt; do
    case "$opt" in
      l)  if [[ $OPTARG = *[!0-9]* ]] || [ $OPTARG -lt $MINIMUM_PASSWORD_LENGTH ]; then
            echo "Your specified password size isn't a number, or is too small (>=$MINIMUM_PASSWORD_LENGTH)."
            exit 1
          fi
          password_length="$OPTARG"
          ;;
      o)  stdout=true
          ;;
      *)  echo "$USAGE"
          exit 1
          ;;
    esac
  done
  shift $(($OPTIND - 1))

  local key=$1
  local pass=$2

  # create pass if none supplied
  if [ ! "$pass" ]; then
    pass=$(pwgen $password_length 1) 
  fi

  # backup the current password file
  if [ ! -d "$P_SOURCE/bak" ]; then mkdir "$P_SOURCE/bak"; fi
  if ! $(cp "$P_SOURCE/p.gpg" \
    "$P_SOURCE/bak/p.`date +%Y%m%d%H%M%S`.gpg" &> /dev/null); then
      echo "Could not create password backup, exiting."
      exit 1
  fi

  # append new password
  local passwords=$( echo -e "$(gpg --homedir="$P_SOURCE/.gnupg" -d "$P_SOURCE/p.gpg")\n$key $pass" | column -t)

  # create new passwords file
  echo -e "$passwords" | gpg --homedir="$P_SOURCE/.gnupg" --yes -e -r $CURRENT_USER > "$P_SOURCE/p.gpg"

  # check success
  if [ $? -eq 0 ]; then
    echo "Successfully added password for '$key'"
  fi

  # output
  if $stdout; then
    echo $pass
  else
    echo $pass | xclip -sel clip
  fi

  return 0
}

p_remove() {

#   p rm <options> [key]
#     Remove a password from a password source.
#
#     -y  do not ask questions
#
#     key;  key for the password to remove

  local prompt=true

  while getopts "y" opt; do
    case "$opt" in
      y)  prompt=false 
          ;;
      *)  echo "$USAGE"
          exit 1
          ;;
    esac
  done
  shift $(($OPTIND - 1))

  local key=$1

  if [ -z $key ]; then
    echo "You must provide a key to remove its password; exiting."
    exit 1
  fi

  # get passwords 
  local passwords=`p_get -o`  

  # make sure the key exists
  echo -e "$passwords" | grep -w $key > /dev/null
  if [ ! $? -eq 0 ]; then
    echo "No results found for '$key'"
    return 1
  fi

  # backup the current password file
  if [ ! -d "$P_SOURCE/bak" ]; then mkdir "$P_SOURCE/bak"; fi
  if ! $(cp "$P_SOURCE/p.gpg" \
    "$P_SOURCE/bak/p.`date +%Y%m%d%H%M%S`.gpg" &> /dev/null); then
      echo "Could not create password backup, exiting."
      exit 1
  fi

  # prompt
  if $prompt; then

    echo "You are about to remove the password entry for '$key'."
    echo -n "Are you sure about this? (yes/no) "

    read keep_going
    case $keep_going in
      "no" | "n")
          echo -e "\nOk, exiting.\n"
          exit 0
          ;;
    esac
  fi

  # create new passwords file
  echo -e "$passwords" | sed "/$key/d" | gpg --homedir="$P_SOURCE/.gnupg" --yes -e -r $CURRENT_USER > "$P_SOURCE/p.gpg"

  # check success
  if [ $? -eq 0 ]; then
    echo "Successfully removed password for '$key'"
  fi

  return 0
}

p_edit() {

  p_remove $@ && p_add $@ 

  return 0

}

p_init() {

#   p init <options> [source]
#     Create a new passwords source. 
#
#     -c  sync mode (used internally)
#
#     source; directory for the new password source

  sync_mode=false

  while getopts "c" opt; do
    case "$opt" in
      c)  # don't track the new source
          sync_mode=true
          ;;
      *)  echo "$USAGE"
          exit 1
          ;;
    esac
  done
  shift $(($OPTIND - 1))

  # check and get absolute path
  if ! $sync_mode; then 
    if [ ! -d "$1" -o ! -w "$1" -o "$(ls -A "$1")" ]; then
      echo "Provided source '$1' is not a directory, or is not writeable, or is not empty; exiting."
      exit 1
    fi
  fi
  local source="$(cd $1; pwd)"

  # copy p files
  cp -r "$P_HOME/"{.gnupg,p.gpg} "$source/"

  # add new source to sources directory
  if ! $sync_mode; then
    echo "$source" >> "$HOME/.psources"
  fi

  $sync_mode || echo "Successfully created p source '$source'."
  
  # reset argument pointer
  $sync_mode && OPTIND=1

  return 0
}

p_pull() {

#   p pull [source]
#     Updates the home source from another given source.
#
#     source; source directory to overwrite the home source
  
  # is the .gnupg directory available and is the p.gpg file available?
  if [ ! -d "$1" -o ! -d "$1/.gnupg" -o ! -a "$1/p.gpg" ]; then
    echo "Provided source '$1' doesn't appear to be a valid source." 
    exit 1
  fi
  local source="$(cd $1; pwd)"

  # copy p files
  cp -r "$source/"{.gnupg,p.gpg} "$P_HOME/"

  if [ $? -eq 0 ]; then
    echo "Successfully updated the home source."
  fi

}

p_push() {

#   p push 
#     Updates all findable password sources with the home source.

  while read source; do
    # is the .gnupg directory available and is the p.gpg file available?
    if [ -d "$source/.gnupg" -a -a "$source/p.gpg" ]; then
      p_init -c "$source"
      if [ $? -eq 0 ]; then 
        echo "Found and updated '$source'."
      fi
    fi
  done < "$HOME/.psources"

  return 0
}

p_sync() {

#   p sync [source]
#     Does a pull, and then a push.
#
#     source; source directory to overwrite the home source
  
  p_pull $@ && p_push

  return 0
}

p_source() {

#   p source
#     List known sources, specify the active one.

  local non_home=false

  _p_find_source

  echo ""
  while read source; do
    if [ "$source" == "$P_SOURCE" ]; then
      non_home=true
      echo "--> $source"
    else
      echo "    $source"
    fi
  done < "$HOME/.psources"

  if [ -d "$P_HOME" -a -f "$P_HOME/p.gpg" -a -d "$P_HOME/.gnupg" ]; then
    if ! $non_home; then
      echo -e "--> $HOME/.p\n"
    else
      echo -e "    $HOME/.p\n"
    fi
  fi

  return 0
}

p_main $@
exit $?
